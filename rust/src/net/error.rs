use thiserror::Error;

#[derive(Error, Debug)]
pub enum NetworkInitError {
    #[error("TLS cert generation failed: {0}")]
    CertGenerationFailed(String),

    #[error("TLS configuration failed: {0}")]
    TlsConfigFailed(String),

    #[error("Failed to bind QUIC endpoint on port {port}: {reason}")]
    BindFailed { port: u16, reason: String },

    #[error("Invalid server address \"{0}\" - expected IP:PORT")]
    InvalidAddress(String),

    #[error("Could not connect to server: {0}")]
    ConnectionFailed(String),
}
