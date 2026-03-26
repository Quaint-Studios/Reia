use libsql::{ Builder, Connection };
use std::sync::Arc;

pub struct DatabaseManager {
    pub conn: Arc<Connection>,
}

impl DatabaseManager {
    pub async fn init(url: String, token: String) -> Self {
        // Initialize Embedded Replica
        let db = Arc::new(
            Builder::new_remote_replica("local.db", url, token)
                .build().await
                .expect("Failed to build Turso replica")
        );

        let conn = Arc::new(db.connect().unwrap());

        // Spawn a background task to sync to cloud every 5 seconds
        let db_clone = db.clone();
        tokio::spawn(async move {
            loop {
                tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
                if let Err(e) = db_clone.sync().await {
                    tracing::error!("Turso Cloud Sync Failed: {}", e);
                }
            }
        });

        DatabaseManager { conn }
    }
}
