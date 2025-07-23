// This file is current structured in a way to quickly test the Sustenet library.
// It is not the final structure of the library.

// The next steps will be cleaning up the code with macros and refining the approach
// to make things easier to use and prettier.

// For now, the master, cluster, and client all run perfectly. And it generates and loads
// the config file correctly as well as the AES keys.

use bytes::Bytes;
use std::{ sync::{ Arc, Mutex }, thread::sleep, time::Duration };
use tokio::{ io::BufReader, net::tcp::ReadHalf };

use godot::{ global::godot_print, prelude::* };
use godot_tokio::AsyncRuntime;

use sustenet::{cluster::{cluster::LOGGER, ClusterServer}, shared::{PluginPin, SenderBytes, ServerPlugin}};
use sustenet::{ client, master };

struct Reia {
    logs: Arc<Mutex<Vec<String>>>,
}
impl ServerPlugin for Reia {
    fn set_sender(&self, _tx: SenderBytes) {
        todo!()
    }

    fn receive<'plug>(
        &self,
        tx: SenderBytes,
        command: u8,
        _reader: &'plug mut BufReader<ReadHalf<'_>>
    ) -> PluginPin<'plug> {
        let logs = self.logs.clone();
        Box::pin(async move {
            if let Ok(mut logs) = logs.lock() {
                logs.push(format!("Received External Command: {}", command));
            }
            if let Err(e) = tx.send(Bytes::from_static(&[20])).await {
                if let Ok(mut logs) = logs.lock() {
                    logs.push(format!("Failed to send message. {e}"));
                }
                LOGGER.error(format!("Failed to send message. {e}").as_str());
            }
        })
    }

    fn info(&self, message: &str) {
        if let Ok(mut logs) = self.logs.lock() {
            logs.push(message.to_string());
        }
    }
}

#[derive(GodotClass)]
#[class(init)]
struct SustenetCluster;

#[godot_api]
impl SustenetCluster {
    #[func]
    fn start_server(&self) {
        let reia = Reia {
            logs: Arc::new(Mutex::new(vec![])),
        };

        let logs = reia.logs.clone();
        let master_logs = reia.logs.clone();
        let cluster_logs = reia.logs.clone();
        let client_logs = reia.logs.clone();

        let master_thread = AsyncRuntime::spawn(async move {
            let _master = match master::MasterServer::new_from_config().await {
                Ok(master) => master,
                Err(e) => {
                    let mut logs_guard = master_logs.lock().unwrap();
                    logs_guard.push(format!("Failed to start Master server: {e}"));
                    LOGGER.error(format!("Failed to start Master server: {e}").as_str());
                    return;
                }
            };
            {
                let mut logs_guard = master_logs.lock().unwrap();
                logs_guard.push("Master server started.".to_string());
            }
            sleep(Duration::from_secs(1));
        });
        godot_print!("The master has been started!");

        let cluster_thread = AsyncRuntime::spawn(async move {
            // let server = ClusterServer::new_from_config(reia).await;
            // server but resolve the result
            let _server = match ClusterServer::new_from_config(reia).await {
                Ok(server) => server,
                Err(e) => {
                    let mut logs_guard = cluster_logs.lock().unwrap();
                    logs_guard.push(format!("Failed to start Cluster server: {e}"));
                    LOGGER.error(format!("Failed to start Cluster server: {e}").as_str());
                    return;
                }
            };
            // cluster::cleanup().await;
            {
                let mut logs_guard = cluster_logs.lock().unwrap();
                logs_guard.push("Cluster server started.".to_string());
            }
            sleep(Duration::from_secs(1));
        });
        godot_print!("The cluster has been started!");

        let client_thread = AsyncRuntime::spawn(async move {
            let address = "0.0.0.0";
            let port = 6256;
            let _client = client::Client::connect(address, port);
            {
                let mut logs_guard = client_logs.lock().unwrap();
                logs_guard.push("Client server started.".to_string());
            }
            sleep(Duration::from_secs(1));
        });
        godot_print!("The client has been started!");

        // Debug
        sleep(Duration::from_secs(3));

        if master_thread.is_finished() {
            godot_print!("Master thread finished.");
        } else {
            godot_print!("Master thread is still running.");
        }
        if cluster_thread.is_finished() {
            godot_print!("Cluster thread finished.");
        } else {
            godot_print!("Cluster thread is still running.");
        }
        if client_thread.is_finished() {
            godot_print!("Client thread finished.");
        } else {
            godot_print!("Client thread is still running.");
        }

        godot_print!("Printing logs.");

        if let Ok(logsvec) = logs.lock() {
            for log in logsvec.iter() {
                godot_print!("{log}");
            }
        }
    }
}
