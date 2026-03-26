use libsql::Connection;
use serde::{ Deserialize, Serialize };
use std::sync::Arc;

/// Represents the database schema for a character
#[derive(Debug, Serialize, Deserialize)]
pub struct PlayerData {
    pub id: i64,
    pub username: String,
    pub zone_id: i64,
    pub x: f32,
    pub y: f32,
    pub z: f32,
    pub health: i32,
}

/// Data Access Object for Player-related Turso queries.
pub struct PlayerDao;

impl PlayerDao {
    /// Fetches all player data from the local embedded replica.
    /// This resolves in microseconds and avoids cloud latency.
    pub async fn fetch_player(conn: &Arc<Connection>, player_id: i64) -> Option<PlayerData> {
        // Safe parameterized query to prevent SQL injection
        let query = "SELECT id, username, zone_id, x, y, z, health FROM players WHERE id = ?1";

        let mut stmt = conn.prepare(query).await.ok()?;
        let mut rows = stmt.query(libsql::params![player_id]).await.ok()?;

        if let Some(row) = rows.next().await.ok().flatten() {
            Some(PlayerData {
                id: row.get(0).unwrap_or(0),
                username: row.get(1).unwrap_or_default(),
                zone_id: row.get(2).unwrap_or(0),
                x: row.get::<f64>(3).unwrap_or(0.0) as f32,
                y: row.get::<f64>(4).unwrap_or(0.0) as f32,
                z: row.get::<f64>(5).unwrap_or(0.0) as f32,
                health: row.get(6).unwrap_or(100),
            })
        } else {
            None
        }
    }

    /// Flushes Godot ECS Transform state to the Database.
    /// Run this periodically (e.g. every 30 seconds)
    /// or explicitly on Zone transitions and disconnects.
    pub async fn save_player_state(
        conn: &Arc<Connection>,
        player_id: i64,
        zone_id: i64,
        x: f32,
        y: f32,
        z: f32,
        health: i32
    ) -> Result<(), libsql::Error> {
        let query =
            "UPDATE players SET zone_id = ?1, x = ?2, y = ?3, z = ?4, health = ?5 WHERE id = ?6";

        conn.execute(query, libsql::params![zone_id, x, y, z, health, player_id]).await?;

        Ok(())
    }
}
