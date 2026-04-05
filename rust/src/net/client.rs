use crate::net::op_codes::OpCode;
use crate::net::packets::{ IncomingPacket, OutgoingPacket };
use flume::{ Receiver, Sender };
use quinn::{ ClientConfig, Endpoint };
use std::net::SocketAddr;
use std::sync::Arc;

/// A dummy verifier to accept our self-signed rcgen certificates during development.
#[derive(Debug)]
struct SkipServerVerification;

impl rustls::client::danger::ServerCertVerifier for SkipServerVerification {
    fn verify_server_cert(
        &self,
        _end_entity: &rustls::pki_types::CertificateDer<'_>,
        _intermediates: &[rustls::pki_types::CertificateDer<'_>],
        _server_name: &rustls::pki_types::ServerName<'_>,
        _ocsp_response: &[u8],
        _now: rustls::pki_types::UnixTime
    ) -> Result<rustls::client::danger::ServerCertVerified, rustls::Error> {
        Ok(rustls::client::danger::ServerCertVerified::assertion())
    }

    fn verify_tls12_signature(
        &self,
        _message: &[u8],
        _cert: &rustls::pki_types::CertificateDer<'_>,
        _dss: &rustls::DigitallySignedStruct
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        Ok(rustls::client::danger::HandshakeSignatureValid::assertion())
    }

    fn verify_tls13_signature(
        &self,
        _message: &[u8],
        _cert: &rustls::pki_types::CertificateDer<'_>,
        _dss: &rustls::DigitallySignedStruct
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        Ok(rustls::client::danger::HandshakeSignatureValid::assertion())
    }

    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        vec![
            rustls::SignatureScheme::RSA_PKCS1_SHA256,
            rustls::SignatureScheme::ED25519,
            rustls::SignatureScheme::RSA_PSS_SHA256
        ]
    }
}

pub async fn start_quinn_client(
    ip: String,
    port: u16,
    tx_in: Sender<IncomingPacket>,
    rx_out: Receiver<OutgoingPacket>
) {
    let _ = rustls::crypto::ring::default_provider().install_default();

    // Configure the Client to skip cert validation
    let mut crypto = rustls::ClientConfig
        ::builder()
        .dangerous()
        .with_custom_certificate_verifier(Arc::new(SkipServerVerification))
        .with_no_client_auth();

    // Apply ALPN protocols directly to the rustls config
    crypto.alpn_protocols = vec![b"mmo-proto".to_vec()];

    // Quinn requires wrapping the rustls config in `QuicClientConfig`
    let quic_config = quinn::crypto::rustls::QuicClientConfig::try_from(crypto).unwrap();
    let client_config = ClientConfig::new(Arc::new(quic_config));

    // Bind to a random local port (0.0.0.0:0) and connect
    let mut endpoint = Endpoint::client("0.0.0.0:0".parse().unwrap()).unwrap();
    endpoint.set_default_client_config(client_config);

    let server_addr: SocketAddr = format!("{}:{}", ip, port).parse().unwrap();

    // "localhost" here matches the dummy cert generated on the server
    match endpoint.connect(server_addr, "localhost").unwrap().await {
        Ok(connection) => {
            tracing::info!("Connected to Server: {}", server_addr);

            // Spawn a task to READ incoming datagrams from Server
            let conn_read = connection.clone();
            tokio::spawn(async move {
                loop {
                    match conn_read.read_datagram().await {
                        Ok(bytes) => {
                            if bytes.len() < 2 {
                                continue;
                            }

                            let op_code_raw = u16::from_le_bytes([bytes[0], bytes[1]]);

                            // Validate against our generated registry
                            if let Ok(_valid_op) = OpCode::try_from(op_code_raw) {
                                let packet = IncomingPacket {
                                    client_id: 0, // 0 signifies the Server
                                    op_code: op_code_raw,
                                    payload: bytes.to_vec(),
                                };
                                let _ = tx_in.send_async(packet).await;
                            } else {
                                tracing::warn!("Server sent unknown OpCode: {}", op_code_raw);
                            }
                        }
                        Err(_) => {
                            break;
                        } // Disconnected
                    }
                }
            });

            // Loop to WRITE outgoing datagrams to Server
            while let Ok(outgoing) = rx_out.recv_async().await {
                // Pack the 2-byte OpCode and the Godot Payload into a single network buffer
                let mut buffer = Vec::with_capacity(2 + outgoing.payload.len());
                buffer.extend_from_slice(&outgoing.op_code.to_le_bytes());
                buffer.extend_from_slice(&outgoing.payload);

                if connection.send_datagram(buffer.into()).is_err() {
                    tracing::error!("Failed to send datagram to server. Connection lost.");
                    break;
                }
            }
        }
        Err(e) => tracing::error!("Failed to connect: {}", e),
    }
}
