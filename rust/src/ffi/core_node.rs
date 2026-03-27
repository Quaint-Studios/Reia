use flume::Receiver;
use godot::prelude::*;
use std::sync::Arc;
use tokio::runtime::Runtime;

use crate::net::packets::IncomingPacket;
use crate::net::server::start_quinn_server;
use crate::state::world_state::WorldState;

#[derive(GodotClass)]
#[class(base = Node)]
pub struct RustCore {
    base: Base<Node>,

    // The async brain
    tokio_runtime: Option<Arc<Runtime>>,

    // The FFI Bridge (Receives packets from Tokio)
    rx_from_net: Option<Receiver<IncomingPacket>>,

    // High-performance concurrent state for math
    world_state: Arc<WorldState>,
}

#[godot_api]
impl INode for RustCore {
    fn init(base: Base<Node>) -> Self {
        RustCore {
            base,
            tokio_runtime: None,
            rx_from_net: None,
            world_state: Arc::new(WorldState::new()),
        }
    }
}

#[godot_api]
impl RustCore {
    /// Signal emitted SAFELY on the Godot main thread
    #[signal]
    pub fn on_network_event(client_id: i64, op_code: StringName, payload: PackedByteArray);

    /// Called by ServerMain.gd in _ready()
    #[func]
    pub fn start_backend(&mut self, port: u16) {
        let _ = tracing_subscriber::fmt::try_init(); // Initialize high-perf logging safely

        let rt = Arc::new(tokio::runtime::Runtime::new().unwrap());
        self.tokio_runtime = Some(rt.clone());

        // Create the cross-thread bridge
        let (tx, rx) = flume::unbounded::<IncomingPacket>();
        self.rx_from_net = Some(rx);

        // Spawn the Quinn Server in the background
        let state_clone = self.world_state.clone();
        rt.spawn(async move {
            start_quinn_server(port, tx, state_clone).await;
        });

        godot_print!("[Rust] Backend initialized successfully.");
    }

    /// Called by ServerMain.gd inside _physics_process() EVERY FRAME
    #[func]
    pub fn poll_network(&mut self) {
        let Some(rx) = &self.rx_from_net.clone() else {
            return;
        };

        // Drain the channel completely without blocking Godot
        for packet in rx.try_iter() {
            let bytes = PackedByteArray::from(packet.payload.as_slice());

            self.base_mut().emit_signal(
                "on_network_event",
                vslice![packet.client_id, packet.op_code, bytes]
            );
        }
    }
}
