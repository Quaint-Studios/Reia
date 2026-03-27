use flume::Receiver;
use godot::prelude::*;
use std::sync::Arc;
use tokio::runtime::Runtime;

use crate::net::client::start_quinn_client;
use crate::net::packets::{ IncomingPacket, OutgoingPacket };
use crate::net::server::start_quinn_server;
use crate::state::world_state::WorldState;

#[derive(GodotClass)]
#[class(base = Node)]
pub struct RustCore {
    base: Base<Node>,

    // The async brain
    tokio_runtime: Option<Arc<Runtime>>,

    // The FFI Bridge (Receives packets from Tokio)
    rx_from_net: Option<Receiver<IncomingPacket>>, // Tokio -> Godot channel
    tx_to_net: Option<flume::Sender<OutgoingPacket>>, // Godot -> Tokio channel

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
            tx_to_net: None,
            world_state: Arc::new(WorldState::new()),
        }
    }
}

#[godot_api]
impl RustCore {
    /// BATCHED Signal emitted SAFELY on the Godot main thread.
    /// Passes all network events that occurred this frame in a single FFI crossing.
    #[signal]
    pub fn on_network_events(
        client_ids: PackedInt64Array,
        op_codes: PackedInt32Array,
        payloads: Array<PackedByteArray>
    );

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

    /// Called by ClientMain.gd to connect to the server
    #[func]
    pub fn start_client(&mut self, server_ip: GString, port: u16) {
        let _ = tracing_subscriber::fmt::try_init();

        let rt = Arc::new(tokio::runtime::Runtime::new().unwrap());
        self.tokio_runtime = Some(rt.clone());

        let (tx_in, rx_in) = flume::unbounded::<IncomingPacket>();
        let (tx_out, rx_out) = flume::unbounded::<OutgoingPacket>();

        self.rx_from_net = Some(rx_in);
        self.tx_to_net = Some(tx_out); // Save sender for Godot to use

        let ip_str = server_ip.to_string();
        rt.spawn(async move {
            start_quinn_client(ip_str, port, tx_in, rx_out).await;
        });

        godot_print!("[Rust] Client network task spawned.");
    }

    /// Called by ServerMain.gd inside _physics_process() EVERY FRAME
    #[func]
    pub fn poll_network(&mut self) {
        let Some(rx) = &self.rx_from_net.clone() else {
            return;
        };

        let mut client_ids = PackedInt64Array::new();
        let mut op_codes = PackedInt32Array::new();
        let mut payloads = Array::<PackedByteArray>::new();

        let mut has_data = false;

        // Drain the channel completely without blocking Godot
        for packet in rx.try_iter() {
            client_ids.push(packet.client_id);
            op_codes.push(packet.op_code as i32);

            let bytes = PackedByteArray::from(packet.payload.as_slice());
            payloads.push(&bytes);

            has_data = true;
        }

        // Only pay the FFI signal tax if we actually received data
        if has_data {
            self.base_mut().emit_signal(
                "on_network_events",
                &[client_ids.to_variant(), op_codes.to_variant(), payloads.to_variant()]
            );
        }
    }

    /// Safely pushes an array of packets from Godot into the Tokio thread in one call
    #[func]
    pub fn send_packets_batched(
        &self,
        target_ids: PackedInt64Array,
        op_codes: PackedInt32Array,
        payloads: Array<PackedByteArray>
    ) {
        if let Some(tx) = &self.tx_to_net {
            // We can convert Godot's Packed arrays directly into fast Rust slices
            let target_slice = target_ids.as_slice();
            let op_slice = op_codes.as_slice();

            for i in 0..target_slice.len() {
                let packet = OutgoingPacket {
                    target_id: target_slice[i],
                    op_code: op_slice[i] as u16,
                    payload: payloads.at(i).to_vec(),
                };
                let _ = tx.send(packet); // Lock-free push to Tokio thread
            }
        }
    }
}
