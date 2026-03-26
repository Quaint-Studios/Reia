use dashmap::DashMap;

pub struct PlayerSpatialData {
    pub x: f32,
    pub y: f32,
    pub z: f32,
    pub zone_id: u32,
}

pub struct WorldState {
    // DashMap is fast for concurrent reads/writes.
    // Tokio can read it while Godot writes to it without massive locking bottlenecks.
    pub players: DashMap<i64, PlayerSpatialData>,
}

impl WorldState {
    pub fn new() -> Self {
        WorldState {
            players: DashMap::new(),
        }
    }
}
