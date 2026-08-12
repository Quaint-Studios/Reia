use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::instrument;
use turso::Connection;

use crate::db::error::DomainDbError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerData {
    pub id: i64,
    pub username: String,
    pub zone_id: i64,
    pub x: f32,
    pub y: f32,
    pub z: f32,
    pub health: i32,
}

// Ergonomic, type-safe conversion from a Turso row to PlayerData
impl TryFrom<&turso::Row> for PlayerData {
    type Error = DomainDbError;

    fn try_from(row: &turso::Row) -> Result<Self, Self::Error> {
        Ok(Self {
            id: row.get(0)?,
            username: row.get(1)?,
            zone_id: row.get(2)?,
            x: row.get::<f64>(3)? as f32,
            y: row.get::<f64>(4)? as f32,
            z: row.get::<f64>(5)? as f32,
            health: row.get(6)?,
        })
    }
}

pub struct PlayerDao;

impl PlayerDao {
    /// Fetches player data from the database by ID.
    /// Returns `Ok(Some(PlayerData))` if found, `Ok(None)` if no matching record exists,
    /// or `Err(DomainDbError)` on database query failure.
    #[instrument(name = "dao.fetch_player", skip(conn), fields(player_id = %player_id))]
    pub async fn fetch_player(
        conn: &Arc<Connection>,
        player_id: i64,
    ) -> Result<Option<PlayerData>, DomainDbError> {
        let query = "SELECT id, username, zone_id, x, y, z, health FROM players WHERE id = ?1";

        let mut stmt = conn.prepare(query).await?;
        let mut rows = stmt.query(turso::params![player_id]).await?;

        if let Some(row) = rows.next().await? {
            let player = PlayerData::try_from(&row)?;
            Ok(Some(player))
        } else {
            Ok(None)
        }
    }

    /// Flushes player state to the database and verifies rows_affected != 0.
    #[instrument(name = "dao.save_player_state", skip(conn), fields(player_id = %player_id, zone_id = %zone_id))]
    pub async fn save_player_state(
        conn: &Arc<Connection>,
        player_id: i64,
        zone_id: i64,
        x: f32,
        y: f32,
        z: f32,
        health: i32,
    ) -> Result<(), DomainDbError> {
        let query =
            "UPDATE players SET zone_id = ?1, x = ?2, y = ?3, z = ?4, health = ?5 WHERE id = ?6";

        let rows_affected = conn
            .execute(query, turso::params![zone_id, x, y, z, health, player_id])
            .await?;

        if rows_affected == 0 {
            return Err(DomainDbError::NotFound);
        }

        Ok(())
    }
}

use crate::db::connection::DatabaseManager;

pub struct PlayerRepository {
    db: Arc<DatabaseManager>,
}

impl PlayerRepository {
    pub fn new(db: Arc<DatabaseManager>) -> Self {
        Self { db }
    }

    #[instrument(name = "repo.fetch_player", skip(self), fields(player_id = %player_id))]
    pub async fn fetch_player(&self, player_id: i64) -> Result<Option<PlayerData>, DomainDbError> {
        PlayerDao::fetch_player(&self.db.conn, player_id).await
    }

    #[instrument(name = "repo.save_player_state", skip(self, data), fields(player_id = %data.id))]
    pub async fn save_player_state(&self, data: &PlayerData) -> Result<(), DomainDbError> {
        let data = data.clone();
        self.db
            .execute_with_retry(|conn| {
                let data = data.clone();
                async move {
                    PlayerDao::save_player_state(
                        &conn,
                        data.id,
                        data.zone_id,
                        data.x,
                        data.y,
                        data.z,
                        data.health,
                    )
                    .await
                }
            })
            .await
    }
}
