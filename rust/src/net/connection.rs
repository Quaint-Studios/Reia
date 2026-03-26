use crate::net::packets::IncomingPacket;
use flume::Sender;
use quinn::Connection;

pub async fn handle_client(conn: Connection, tx: Sender<IncomingPacket>) {
    let client_id = 1; // In reality, establish this during auth handshake

    // Loop to read Unreliable Datagrams (Movement/Physics)
    loop {
        match conn.read_datagram().await {
            Ok(bytes) => {
                // With rkyv, we would use zero-copy checking here:
                // let archived = rkyv::check_archived_root::<PlayerInput>(&bytes).unwrap();
                // For the FFI bridge, we can just forward the bytes to Godot.

                let packet = IncomingPacket {
                    client_id,
                    op_code: "INPUT_TICK".to_string(), // Extracted from bytes/rkyv header
                    payload: bytes.to_vec(),
                };

                // Send across the Flume bridge to Godot
                if tx.send_async(packet).await.is_err() {
                    break; // Flume channel disconnected (Server shutting down)
                }
            }
            Err(_) => {
                tracing::info!("Client {} disconnected.", client_id);
                break;
            }
        }
    }
}
