use crate::net::packets::IncomingPacket;
use crate::state::world_state::WorldState;
use flume::Sender;
use quinn::crypto::rustls::QuicServerConfig;
use quinn::{ Endpoint, ServerConfig };
use std::net::SocketAddr;
use std::sync::Arc;

pub async fn start_quinn_server(port: u16, tx: Sender<IncomingPacket>, _state: Arc<WorldState>) {
    // Explicitly install the Crypto Provider for rustls
    let _ = rustls::crypto::ring::default_provider().install_default();

    // Generate dummy TLS certificate for QUIC using rcgen
    let cert = rcgen::generate_simple_self_signed(vec!["localhost".into()]).unwrap();
    let cert_der = rustls::pki_types::CertificateDer::from(cert.cert.der().to_vec());
    let priv_key = rustls::pki_types::PrivateKeyDer
        ::try_from(cert.signing_key.serialize_der())
        .unwrap();

    let mut server_crypto = rustls::ServerConfig
        ::builder()
        .with_no_client_auth()
        .with_single_cert(vec![cert_der], priv_key)
        .unwrap();

    server_crypto.alpn_protocols = vec![b"mmo-proto".to_vec()];

    let quic_config = QuicServerConfig::try_from(server_crypto).unwrap();
    let server_config = ServerConfig::with_crypto(Arc::new(quic_config));

    // Bind the UDP endpoint
    let addr = format!("0.0.0.0:{}", port).parse::<SocketAddr>().unwrap();
    let endpoint = Endpoint::server(server_config, addr).unwrap();
    tracing::info!("Quinn UDP server listening on {}", addr);

    // Listen for connections asynchronously
    while let Some(conn) = endpoint.accept().await {
        let tx_clone = tx.clone();

        tokio::spawn(async move {
            match conn.await {
                Ok(connection) => {
                    tracing::info!("Client Connected: {}", connection.remote_address());
                    // Route to connection handler (reading streams/datagrams)
                    crate::net::connection::handle_client(connection, tx_clone).await;
                }
                Err(e) => tracing::error!("Connection failed: {}", e),
            }
        });
    }
}
