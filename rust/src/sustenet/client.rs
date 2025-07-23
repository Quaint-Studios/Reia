use std::future::Future;
use std::pin::Pin;
use std::sync::OnceLock;
use std::{ net::IpAddr, str::FromStr };

use godot::prelude::{ GodotClass, godot_api };

use godot_tokio::AsyncRuntime;
use tokio::io::BufReader;
use tokio::net::tcp::ReadHalf;
use tokio::sync::mpsc::Sender;

use sustenet::client;
use sustenet::client::{ ConnectionType, LOGGER };
use sustenet::shared::ClientPlugin;

static SENDER: OnceLock<Sender<Box<[u8]>>> = OnceLock::new();

#[derive(GodotClass)]
#[class(init)]
struct SustenetClient;
#[godot_api]
impl SustenetClient {
    #[signal]
    fn on_connected(conn: String);

    #[signal]
    fn on_timeout(conn: String);

    #[signal]
    fn on_disconnected(conn: String);

    /// Accepts a connection value in the format of:
    /// - "example.com:port",
    /// - "example.com" defaulting to port 6256
    /// - "#.#.#.#:port"
    /// - "#.#.#.#" defaulting to port 6256
    /// - If the value is empty, it defaults to "localhost:6256"
    #[func]
    pub fn connect(&self, conn: String) {
        let default_host = "localhost".to_string();
        let default_port = 6256u16;

        let (host, port) = if conn.trim().is_empty() {
            (default_host, default_port)
        } else if let Some((h, p)) = conn.rsplit_once(':') {
            // Try to parse the port
            if let Ok(port) = p.parse::<u16>() {
                (h.to_string(), port)
            } else {
                (conn, default_port)
            }
        } else {
            (conn, default_port)
        };

        let plugin = Plugin {
			sender: OnceLock::new(),
		};
        AsyncRuntime::spawn(async move {
            let mut addrs = tokio::net::lookup_host((host, port)).await.ok();
            let ip = addrs
                .as_mut()
                .and_then(|iter| iter.next())
                .map(|sockaddr| sockaddr.ip())
                .unwrap_or(IpAddr::from_str("127.0.0.1").unwrap());

            {
                let mut guard = client::CONNECTION.write().await;
                *guard = Some(client::Connection {
                    ip,
                    port,
                    connection_type: ConnectionType::MasterServer,
                });
            }

            client::start(plugin).await;
        });
    }
}

struct Plugin {
    sender: OnceLock<Sender<Box<[u8]>>>,
}
impl ClientPlugin for Plugin {
    fn set_sender(&self, tx: Sender<Box<[u8]>>) {
		if SENDER.set(tx.clone()).is_err() {
			LOGGER.error("Failed to set static sender.");
		}
        if self.sender.set(tx).is_err() {
            LOGGER.error("Failed to set sender.");
        }
    }

    fn receive_master<'plug>(
        &self,
        _tx: Sender<Box<[u8]>>,
        _command: u8,
        _reader: &'plug mut BufReader<ReadHalf<'_>>
    ) -> Pin<Box<dyn Future<Output = ()> + Send>> {
        Box::pin(async move {
            // if let Err(e) = tx.send(Box::new([20])).await {
            //     LOGGER.error(format!("Failed to send message. {e}").as_str());
            // }
        })
    }

    fn receive_cluster<'plug>(
        &self,
        _tx: Sender<Box<[u8]>>,
        _command: u8,
        _reader: &'plug mut BufReader<ReadHalf<'_>>
    ) -> Pin<Box<dyn Future<Output = ()> + Send>> {
        Box::pin(async move {
            // if let Err(e) = tx.send(Box::new([20])).await {
            //     LOGGER.error(format!("Failed to send message. {e}").as_str());
            // }
        })
    }

    fn info(&self, _message: &str) {}
}
