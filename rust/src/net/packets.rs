use rkyv::{ Archive, Deserialize, Serialize };

/// The internal bridge struct used to pass data from the Tokio async
/// network thread through the Flume channel to the Godot main thread.
pub struct IncomingPacket {
    pub client_id: i64,
    pub op_code: u16,
    pub payload: Vec<u8>,
}

pub struct OutgoingPacket {
    pub target_id: i64, // Used by server to route to specific client. 0 for Client-to-Server.
    pub op_code: u16,
    pub payload: Vec<u8>,
}

// ==========================================
// RKYV PROTOCOLS (Zero-Copy Networking)
// ==========================================
// These structs define the exact byte layout of the UDP packets.
// Because we use rkyv, the Rust server can validate and read these
// structs straight off the network buffer without allocating memory.

#[derive(Archive, Deserialize, Serialize, Debug, PartialEq)]
#[rkyv(compare(PartialEq), derive(Debug))]
pub enum ClientBoundPacket {
    /// Sent when the server confirms a successful login
    AuthSuccess {
        player_id: i64,
        zone_id: u32,
    },
    /// Broadcasted when a player, monster, or item enters the client's view
    EntitySpawn {
        entity_id: i64,
        entity_type: String, // "PLAYER", "BONE", "GOBLIN"
        name: String, // Username or Item Name
        x: f32,
        y: f32,
        z: f32,
    },
    /// A bulk update of transforms for entities in the player's chunk
    StateSync {
        entities: Vec<EntitySyncData>,
    },
    /// Fire-and-forget events for visual observers (e.g. CombatVFX)
    EventTrigger {
        target_id: i64,
        event_type: String, // e.g., "DAMAGE_TAKEN", "LEVEL_UP"
    },
    /// A chat message broadcasted to the local zone
    ChatMessage {
        sender_name: String,
        message: String,
    },
}

#[derive(Archive, Deserialize, Serialize, Debug, PartialEq)]
#[rkyv(compare(PartialEq), derive(Debug))]
pub enum ServerBoundPacket {
    /// Client requesting authentication
    AuthRequest {
        username: String,
        auth_token: String,
    },
    /// High-frequency movement updates from the client
    InputTick {
        tick_number: u32,
        dir_x: f32,
        dir_y: f32,
        dir_z: f32,
    },
    /// Action requests (Attacking, interacting)
    ActionRequest {
        action_id: u32,
        target_id: i64,
    },
    /// Client wants to send a chat message
    SendChat {
        message: String,
    },
}

#[derive(Archive, Deserialize, Serialize, Debug, PartialEq)]
#[rkyv(compare(PartialEq), derive(Debug))]
pub struct EntitySyncData {
    pub id: i64,
    pub x: f32,
    pub y: f32,
    pub z: f32,
}
