use crate::net::{
    op_codes::OpCode,
    packets::{IncomingPacket, LifecycleEvent},
};
use dashmap::DashMap;
use flume::Sender;
use quinn::Connection;
use std::sync::Arc;

pub async fn handle_client(
    client_id: i64,
    conn: Connection,
    tx: Sender<IncomingPacket>,
    tx_life: Sender<LifecycleEvent>,
    connections: Arc<DashMap<i64, Connection>>,
) {
    // Loop to read Unreliable Datagrams (Movement/Physics)
    loop {
        match conn.read_datagram().await {
            Ok(bytes) => {
                // NOTE: With rkyv, we would use zero-copy checking here:
                // let archived = rkyv::check_archived_root::<PlayerInput>(&bytes).unwrap();
                // For the FFI bridge, we can just forward the bytes to Godot.

                // Minimum length check (OpCode is 2 bytes)
                if bytes.len() < 2 {
                    tracing::warn!(
                        "Received malformed packet (too short) from Client {}",
                        client_id
                    );
                    continue;
                }

                // Extract the OpCode from the packet header
                // (little-endian serialization for the first 2 bytes)
                let op_code_raw = u16::from_le_bytes([bytes[0], bytes[1]]);

                // Strict Validation using the auto-generated TryFrom trait
                match OpCode::try_from(op_code_raw) {
                    Ok(_valid_op) => {
                        // The packet is verified against our protocol registry!

                        // NOTE: If Rust needs to do heavy math on a specific packet,
                        // we can intercept it right here before (or while) sending it to Godot.
                        // if valid_op == OpCode::InputTick { crate::math::process_input(...) }

                        let packet = IncomingPacket {
                            client_id,                    // Safely stamp with server-generated ID
                            op_code: op_code_raw,         // Pass the raw u16 up the bridge
                            payload: bytes[2..].to_vec(), // Pass the full payload for Godot/rkyv to parse
                        };

                        // Push to the Flume channel so Godot can pop it in poll_network()
                        if tx.send_async(packet).await.is_err() {
                            tracing::error!("Flume bridge disconnected. Shutting down connection.");
                            break;
                        }
                    }
                    Err(_) => {
                        // Gatekeeper: Instantly drop unknown packets.
                        // This prevents bad actors from crashing the Godot ECS loop.
                        tracing::warn!(
                            "Client {} sent unknown/invalid OpCode: {}",
                            client_id,
                            op_code_raw
                        );
                    }
                }
            }
            Err(_) => {
                tracing::info!("Client {} disconnected.", client_id);
                break;
            }
        }
    }

    // Clean up connection map on disconnect
    connections.remove(&client_id);

    // Notify Godot that this client has disconnected
    let _ = tx_life
        .send_async(LifecycleEvent::ServerClientDisconnected(client_id))
        .await;
}
