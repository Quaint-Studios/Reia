use std::env;
use std::sync::Arc;
use std::time::Duration;
use tokio::time::sleep;
use tracing::{error, info, warn};

use crate::db::error::DomainDbError;

pub struct DbConfig {
    pub db_url: String,
    pub auth_token: Option<String>,
    pub replica_path: String,
    pub max_retries: u32,
    pub retry_backoff_ms: u64,
}

impl DbConfig {
    pub fn from_env() -> Self {
        Self {
            db_url: env::var("TURSO_DATABASE_URL")
                .unwrap_or_else(|_| "file:local_save.db".to_string()),
            auth_token: env::var("TURSO_AUTH_TOKEN").ok(),
            replica_path: env::var("TURSO_REPLICA_PATH")
                .unwrap_or_else(|_| "local_replica.db".to_string()),
            max_retries: env::var("TURSO_MAX_RETRIES")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(5),
            retry_backoff_ms: env::var("TURSO_RETRY_BACKOFF_MS")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(20),
        }
    }

    pub async fn connect(&self) -> Result<Arc<turso::Connection>, DomainDbError> {
        let conn = if self.db_url.starts_with("libsql://") || self.db_url.starts_with("https://") {
            let token = self.auth_token.clone().unwrap_or_default();
            info!(
                "[Turso] Connecting to remote instance: {} (replica: {})",
                self.db_url, self.replica_path
            );

            let db = turso::sync::Builder::new_remote(&self.replica_path)
                .with_remote_url(&self.db_url)
                .with_auth_token(&token)
                .build()
                .await?;

            db.connect().await?
        } else {
            info!(
                "[Turso] Connecting to local embedded database: {}",
                self.db_url
            );

            let db = turso::Builder::new_local(&self.db_url).build().await?;
            db.connect()?
        };

        let conn = Arc::new(conn);

        // Pragmas for performance and concurrency
        if let Err(e) = conn.execute("PRAGMA foreign_keys = ON;", ()).await {
            warn!("[Turso] Failed to enable PRAGMA foreign_keys: {}", e);
        }
        if let Err(e) = conn.execute("PRAGMA busy_timeout = 5000;", ()).await {
            warn!("[Turso] Failed to set PRAGMA busy_timeout: {}", e);
        }

        Ok(conn)
    }
}

pub struct DatabaseManager {
    pub conn: Arc<turso::Connection>,
    pub config: DbConfig,
}

impl DatabaseManager {
    pub async fn new() -> Result<Self, DomainDbError> {
        let config = DbConfig::from_env();
        let conn = config.connect().await?;
        Ok(Self { conn, config })
    }

    /// Executes an async operation with exponential backoff and jitter for OCC serialization retries
    pub async fn execute_with_retry<F, Fut, R>(&self, mut op: F) -> Result<R, DomainDbError>
    where
        F: FnMut(Arc<turso::Connection>) -> Fut,
        Fut: std::future::Future<Output = Result<R, DomainDbError>>,
    {
        let mut attempts = 0;
        loop {
            attempts += 1;
            match op(self.conn.clone()).await {
                Ok(res) => return Ok(res),
                Err(DomainDbError::SerializationFailure) if attempts < self.config.max_retries => {
                    let exp = 1u64 << (attempts - 1).min(6);
                    let nano_jitter = std::time::SystemTime::now()
                        .duration_since(std::time::SystemTime::UNIX_EPOCH)
                        .map(|d| (d.subsec_nanos() as u64) % 25)
                        .unwrap_or(0);
                    let backoff =
                        Duration::from_millis(self.config.retry_backoff_ms * exp + nano_jitter);
                    warn!(
                        "[Turso OCC] Serialization contention on attempt {}, retrying in {}ms...",
                        attempts,
                        backoff.as_millis()
                    );
                    sleep(backoff).await;
                }
                Err(DomainDbError::SerializationFailure) => {
                    error!(
                        "[Turso OCC] Exceeded max retries ({}) due to serialization failure.",
                        self.config.max_retries
                    );
                    return Err(DomainDbError::SerializationFailure);
                }
                Err(err) => return Err(err),
            }
        }
    }
}
