use std::{sync::{Arc, Mutex}, thread::sleep, time::Duration};

use cluster::{error, start};
use godot::{global::godot_print, prelude::*};
use godot_tokio::AsyncRuntime;
use shared::Plugin;
use tokio::sync::mpsc::Sender;

struct Reia {
    logs: Arc<Mutex<Vec<String>>>,
}
impl Plugin for Reia {
    fn receive(
        &self,
        tx: Sender<Box<[u8]>>,
        command: u8,
    ) -> std::pin::Pin<Box<dyn std::future::Future<Output = ()> + Send>> {
        Box::pin(async move {
            println!("Reia plugin handling command: {}", command);
            if let Err(e) = tx.send(Box::new([20])).await {
                error(format!("Failed to send message. {e}").as_str());
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
    fn start(&self) {
        let reia = Reia { logs: Arc::new(Mutex::new(vec![])) };
        let logs = reia.logs.clone();
        godot_print!("Starting the cluster server...");
        // Pass a reference or clone if needed
        AsyncRuntime::spawn(start(reia));
        godot_print!("The cluster has been started!");
        sleep(Duration::from_secs(1));
        godot_print!("Printing logs.");

        if let Ok(logsvec) = logs.lock() {
            for log in logsvec.iter() {
                godot_print!("{log}");
            }
        }
    }
}
