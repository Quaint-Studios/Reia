use std::env;
use std::sync::Arc;
use tokio::time::{Duration, sleep};
use tracing::{error, info, warn};

/// Production domain error enum mapping SQLite extended codes and Turso error variants
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DomainDbError {
    UniqueViolation { detail: String },
    ForeignKeyViolation { detail: String },
    SerializationFailure,
    ConnectionError(String),
    QueryFailed { code: String, message: String },
}

impl std::fmt::Display for DomainDbError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DomainDbError::UniqueViolation { detail } => {
                write!(f, "Unique constraint violation: {}", detail)
            }
            DomainDbError::ForeignKeyViolation { detail } => {
                write!(f, "Foreign key constraint violation: {}", detail)
            }
            DomainDbError::SerializationFailure => {
                write!(f, "MVCC OCC serialization failure (busy snapshot)")
            }
            DomainDbError::ConnectionError(err) => write!(f, "Database connection error: {}", err),
            DomainDbError::QueryFailed { code, message } => {
                write!(f, "Query failed [{}]: {}", code, message)
            }
        }
    }
}

impl std::error::Error for DomainDbError {}

pub enum DbBackend {
    LocalEmbedded(Arc<turso::Connection>),
    RemoteTurso(Arc<turso::Connection>),
}

pub struct DbConfig {
    pub db_url: String,
    pub auth_token: Option<String>,
    pub max_retries: u32,
    pub retry_backoff_ms: u64,
}

impl DbConfig {
    pub fn from_env() -> Self {
        let db_url =
            env::var("TURSO_DATABASE_URL").unwrap_or_else(|_| "file:local_save.db".to_string());
        let auth_token = env::var("TURSO_AUTH_TOKEN").ok();
        let max_retries = env::var("TURSO_MAX_RETRIES")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(5);
        let retry_backoff_ms = env::var("TURSO_RETRY_BACKOFF_MS")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(20);

        DbConfig {
            db_url,
            auth_token,
            max_retries,
            retry_backoff_ms,
        }
    }

    pub async fn connect(&self) -> Result<DbBackend, DomainDbError> {
        if self.db_url.starts_with("libsql://") || self.db_url.starts_with("https://") {
            let token = self.auth_token.clone().unwrap_or_default();
            info!(
                "[Turso] Connecting to remote Cloud instance at {}",
                self.db_url
            );

            let db = turso::sync::Builder::new_remote("local_replica.db")
                .with_remote_url(&self.db_url)
                .with_auth_token(&token)
                .build()
                .await
                .map_err(|e| DomainDbError::ConnectionError(e.to_string()))?;

            let conn = db
                .connect()
                .await
                .map_err(|e| DomainDbError::ConnectionError(e.to_string()))?;

            Ok(DbBackend::RemoteTurso(Arc::new(conn)))
        } else {
            info!(
                "[Turso] Connecting to local embedded database at {}",
                self.db_url
            );

            let db = turso::Builder::new_local(&self.db_url)
                .build()
                .await
                .map_err(|e| DomainDbError::ConnectionError(e.to_string()))?;

            let conn = db
                .connect()
                .map_err(|e| DomainDbError::ConnectionError(e.to_string()))?;

            Ok(DbBackend::LocalEmbedded(Arc::new(conn)))
        }
    }
}

pub struct DatabaseManager {
    pub conn: Arc<turso::Connection>,
    pub config: DbConfig,
}

impl DatabaseManager {
    pub async fn new() -> Result<Self, DomainDbError> {
        let config = DbConfig::from_env();
        let backend = config.connect().await?;

        let conn = match backend {
            DbBackend::LocalEmbedded(c) => c,
            DbBackend::RemoteTurso(c) => c,
        };

        // Enable foreign key enforcement and set busy timeout for optimal concurrency
        if let Err(e) = conn.execute("PRAGMA foreign_keys = ON;", ()).await {
            warn!("[Turso] Failed to enable PRAGMA foreign_keys: {}", e);
        }
        if let Err(e) = conn.execute("PRAGMA busy_timeout = 5000;", ()).await {
            warn!("[Turso] Failed to set PRAGMA busy_timeout: {}", e);
        }

        Ok(DatabaseManager { conn, config })
    }

    /// Executes a write operation with an optimistic retry loop for MVCC OCC serialization failures
    pub async fn execute_with_retry<F, R, E>(&self, mut op: F) -> Result<R, DomainDbError>
    where
        F: FnMut(&turso::Connection) -> Result<R, E>,
        E: std::fmt::Display,
    {
        let mut attempts = 0;
        loop {
            attempts += 1;
            match op(&self.conn) {
                Ok(res) => return Ok(res),
                Err(err) => {
                    let err_str = err.to_string();
                    if err_str.contains("SQLITE_BUSY")
                        || err_str.contains("serialization")
                        || err_str.contains("40001")
                    {
                        if attempts < self.config.max_retries {
                            warn!(
                                "[Turso OCC] Serialization contention on attempt {}, retrying in {}ms...",
                                attempts, self.config.retry_backoff_ms
                            );
                            sleep(Duration::from_millis(
                                self.config.retry_backoff_ms * (attempts as u64),
                            ))
                            .await;
                            continue;
                        } else {
                            error!(
                                "[Turso OCC] Exceeded maximum retries ({}) due to serialization failure.",
                                self.config.max_retries
                            );
                            return Err(DomainDbError::SerializationFailure);
                        }
                    }

                    if err_str.contains("UNIQUE constraint") {
                        return Err(DomainDbError::UniqueViolation { detail: err_str });
                    }
                    if err_str.contains("FOREIGN KEY constraint") {
                        return Err(DomainDbError::ForeignKeyViolation { detail: err_str });
                    }

                    return Err(DomainDbError::QueryFailed {
                        code: "ERR_QUERY".to_string(),
                        message: err_str,
                    });
                }
            }
        }
    }
}
