use libsql::Connection;
use std::env;

pub enum DbBackend {
    LocalEmbedded(Connection),
    RemoteTurso(Connection),
}

pub struct DbConfig {
    pub db_url: String,
    pub auth_token: Option<String>,
}

impl DbConfig {
    pub fn from_env() -> Self {
        let db_url = env::var("TURSO_DATABASE_URL")
            .unwrap_or_else(|_| "file:local_save.db".to_string());
        let auth_token = env::var("TURSO_AUTH_TOKEN").ok();

        DbConfig { db_url, auth_token }
    }

    pub async fn connect(&self) -> Result<DbBackend, libsql::Error> {
        if self.db_url.starts_with("libsql://") || self.db_url.starts_with("https://") {
            // Remote Turso Cloud connection
            let token = self.auth_token.clone().unwrap_or_default();
            let db = libsql::Builder::new_remote(self.db_url.clone(), token)
                .build()
                .await?;
            let conn = db.connect()?;
            Ok(DbBackend::RemoteTurso(conn))
        } else {
            // Embedded local file or memory database via libSQL
            let db = libsql::Builder::new_local(&self.db_url)
                .build()
                .await?;
            let conn = db.connect()?;
            Ok(DbBackend::LocalEmbedded(conn))
        }
    }
}
