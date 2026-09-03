use crate::net::error::NetworkInitError;
use crate::net::packets::{IncomingPacket, LifecycleEvent, OutgoingPacket};
use crate::state::world_state::WorldState;

use dashmap::DashMap;
use flume::{Receiver, Sender};
use quinn::crypto::rustls::QuicServerConfig;
use quinn::{Connection, Endpoint, ServerConfig, TransportConfig};
use std::net::SocketAddr;
use std::sync::Arc;
use std::sync::atomic::{AtomicI64, Ordering};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

pub async fn start_quinn_server(
    port: u16,
    tx: Sender<IncomingPacket>,
    rx_out: Receiver<OutgoingPacket>,
    tx_life: Sender<LifecycleEvent>,
    _state: Arc<WorldState>,
) -> Result<(), NetworkInitError> {
    // Explicitly install the Crypto Provider for rustls
    let _ = rustls::crypto::ring::default_provider().install_default();

    // Generate dummy TLS certificate for QUIC using rcgen
    let cert = rcgen::generate_simple_self_signed(vec!["localhost".into()])
        .map_err(|e| NetworkInitError::CertGenerationFailed(e.to_string()))?;

    let cert_der = rustls::pki_types::CertificateDer::from(cert.cert.der().to_vec());
    let priv_key = rustls::pki_types::PrivateKeyDer::try_from(cert.signing_key.serialize_der())
        .map_err(|e| NetworkInitError::TlsConfigFailed(e.to_string()))?;

    let mut server_crypto = rustls::ServerConfig::builder()
        .with_no_client_auth()
        .with_single_cert(vec![cert_der], priv_key)
        .map_err(|e| NetworkInitError::TlsConfigFailed(e.to_string()))?;

    server_crypto.alpn_protocols = vec![b"mmo-proto".to_vec()];

    // Explicitly configure transport settings to prevent drops during Godot Scene Loads
    let mut transport_config = TransportConfig::default();
    transport_config.max_idle_timeout(Some(Duration::from_secs(30).try_into().unwrap()));
    transport_config.keep_alive_interval(Some(Duration::from_secs(5)));
    transport_config.datagram_receive_buffer_size(Some(usize::MAX));
    let transport_config = Arc::new(transport_config);

    let quic_config = QuicServerConfig::try_from(server_crypto)
        .map_err(|e| NetworkInitError::TlsConfigFailed(e.to_string()))?;
    let mut server_config = ServerConfig::with_crypto(Arc::new(quic_config));
    server_config.transport_config(transport_config);

    // Bind the UDP endpoint
    let addr = format!("0.0.0.0:{}", port).parse::<SocketAddr>().unwrap();
    let endpoint =
        Endpoint::server(server_config, addr).map_err(|e| NetworkInitError::BindFailed {
            port,
            reason: e.to_string(),
        })?;
    tracing::info!("UDP Server listening on {}", addr);

    // Thread-safe map to store connected clients for routing outbound packets
    let connections: Arc<DashMap<i64, Connection>> = Arc::new(DashMap::new());
    let connections_for_out = connections.clone();

    // Spawn the outgoing packet router task
    tokio::spawn(async move {
        while let Ok(packet) = rx_out.recv_async().await {
            // Find the correct client connection
            if let Some(conn) = connections_for_out.get(&packet.target_id) {
                let mut buffer = Vec::with_capacity(2 + packet.payload.len());
                buffer.extend_from_slice(&packet.op_code.to_le_bytes());
                buffer.extend_from_slice(&packet.payload);

                if conn.value().send_datagram(buffer.into()).is_err() {
                    tracing::warn!("Failed to send datagram to client {}", packet.target_id);
                }
            }
        }
    });

    // Generate pseudo-random client connection IDs using the current microsecond timestamp
    // This acts as a highly unique i64 ID until integrated with Turso DB
    let time_seed = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_micros() as i64;
    let client_id_counter = Arc::new(AtomicI64::new(time_seed));

    // Listen for connections asynchronously
    while let Some(conn) = endpoint.accept().await {
        let tx_clone = tx.clone();
        let tx_life_clone = tx_life.clone();
        let connections_clone = connections.clone();
        let id_counter = client_id_counter.clone();

        tokio::spawn(async move {
            match conn.await {
                Ok(connection) => {
                    let client_id = id_counter.fetch_add(1, Ordering::SeqCst);
                    connections_clone.insert(client_id, connection.clone());
                    tracing::info!(
                        "Client Connected: {} (Connection ID: {})",
                        connection.remote_address(),
                        client_id
                    );

                    // Notify Godot
                    let _ = tx_life_clone
                        .send_async(LifecycleEvent::ServerClientConnected(client_id))
                        .await;

                    // Route to connection handler (reading streams/datagrams)
                    crate::net::connection::handle_client(
                        client_id,
                        connection,
                        tx_clone,
                        tx_life_clone,
                        connections_clone,
                    )
                    .await;
                }
                Err(e) => tracing::error!("Connection failed: {}", e),
            }
        });
    }

    Ok(())
}
