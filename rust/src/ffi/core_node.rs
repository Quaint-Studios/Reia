use flume::Receiver;
use godot::prelude::*;
use std::sync::Arc;
use tokio::runtime::Runtime;

use crate::net::client::start_quinn_client;
use crate::net::packets::{ IncomingPacket, OutgoingPacket };
use crate::net::server::start_quinn_server;
use crate::state::world_state::WorldState;

// A simple struct to help Rust group packets rapidly before sending to Godot
#[derive(Default)]
struct PacketBucket {
    ids: Vec<i64>,
    data: Vec<u8>,
    offsets: Vec<i32>,
}

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
    /// Emits a SINGLE dictionary containing our batched buckets.
    /// Format: { OpCode: { "ids": PackedInt64, "data": PackedByteArray, "offsets": PackedInt32 } }
    #[signal]
    pub fn on_network_events(batched_buckets: VarDictionary);

    /// Called by ServerMain.gd in _ready()
    #[func]
    pub fn start_backend(&mut self, port: u16) {
        let _ = tracing_subscriber::fmt::try_init(); // Initialize high-perf logging safely

        let rt = Arc::new(tokio::runtime::Runtime::new().unwrap());
        self.tokio_runtime = Some(rt.clone());

        // Create the cross-thread bridge
        let (tx, rx) = flume::unbounded::<IncomingPacket>();
        let (tx_out, _rx_out) = flume::unbounded::<OutgoingPacket>();

        self.rx_from_net = Some(rx);
        self.tx_to_net = Some(tx_out);

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

        let mut has_data = false;

        let mut buckets: std::collections::HashMap<
            u16,
            PacketBucket
        > = std::collections::HashMap::new();

        // Drain the channel completely without blocking Godot
        for packet in rx.try_iter() {
            let bucket = buckets.entry(packet.op_code).or_default();

            bucket.ids.push(packet.client_id);
            bucket.offsets.push(bucket.data.len() as i32); // Record where this payload starts
            bucket.data.extend(&packet.payload); // Concatenate raw bytes

            has_data = true;
        }

        if !has_data {
            return;
        }

        // Convert to Godot Dictionary exactly ONCE per frame
        let mut godot_buckets = VarDictionary::new();

        for (op_code, bucket) in buckets {
            let mut inner_dict = VarDictionary::new();

            // Zero-copy-ish conversion from Rust Vec to Godot PackedArrays
            inner_dict.set("ids", PackedInt64Array::from(bucket.ids.as_slice()));
            inner_dict.set("data", PackedByteArray::from(bucket.data.as_slice()));
            inner_dict.set("offsets", PackedInt32Array::from(bucket.offsets.as_slice()));

            godot_buckets.set(op_code, inner_dict);
        }

        // Emit the batched dictionary across the FFI bridge
        self.base_mut().emit_signal("on_network_events", &[godot_buckets.to_variant()]);
    }

    /// Safely pushes an array of packets from Godot into the Tokio thread in one call
    #[func]
    pub fn send_packets_batched(
        &self,
        target_ids: PackedInt64Array,
        op_codes: PackedInt32Array,
        payload_data: PackedByteArray,
        offsets: PackedInt32Array
    ) {
        if let Some(tx) = &self.tx_to_net {
            let t_slice = target_ids.as_slice();
            let op_slice = op_codes.as_slice();
            let data_slice = payload_data.as_slice();
            let offsets_slice = offsets.as_slice();

            for i in 0..t_slice.len() {
                let start_idx = offsets_slice[i] as usize;

                // End index is either the start of the next packet, or the end of the byte array
                let end_idx = if i + 1 < offsets_slice.len() {
                    offsets_slice[i + 1] as usize
                } else {
                    data_slice.len()
                };

                let packet = OutgoingPacket {
                    target_id: t_slice[i],
                    op_code: op_slice[i] as u16,
                    payload: data_slice[start_idx..end_idx].to_vec(),
                };

                let _ = tx.send(packet); // Push to Tokio safely
            }
        }
    }

    /// Broadcast: Sends ONE payload to MANY targets instantly.
    /// Perfect for State Syncs (e.g., A monster moved, tell everyone nearby).
    #[func]
    pub fn broadcast_packet(
        &self,
        target_ids: PackedInt64Array,
        op_code: i32,
        payload: PackedByteArray
    ) {
        if let Some(tx) = &self.tx_to_net {
            let targets = target_ids.as_slice();
            let data = payload.to_vec(); // Clone the data ONCE
            let op = op_code as u16;

            for &target_id in targets {
                let packet = OutgoingPacket {
                    target_id,
                    op_code: op,
                    payload: data.clone(), // Arc/Bytes could optimize this further in Quinn
                };
                let _ = tx.send(packet);
            }
        }
    }

    /// Highly optimized broadcast batching. Slices flat arrays natively in Rust memory
    /// to avoid Godot Variant and Array.slice() GC overhead.
    #[func]
    pub fn broadcast_packets_batched(
        &self,
        targets: PackedInt64Array,
        target_offsets: PackedInt32Array,
        op_codes: PackedInt32Array,
        payload_data: PackedByteArray,
        data_offsets: PackedInt32Array
    ) {
        if let Some(tx) = &self.tx_to_net {
            let t_slice = targets.as_slice();
            let t_off_slice = target_offsets.as_slice();

            let op_slice = op_codes.as_slice();

            let d_slice = payload_data.as_slice();
            let d_off_slice = data_offsets.as_slice();

            // Iterate over each broadcast request
            for i in 0..op_slice.len() {
                let op = op_slice[i] as u16;

                // Slice the Data
                let d_start = d_off_slice[i] as usize;
                let d_end = if i + 1 < d_off_slice.len() {
                    d_off_slice[i + 1] as usize
                } else {
                    d_slice.len()
                };
                let payload = d_slice[d_start..d_end].to_vec(); // Clone payload ONCE per broadcast

                // Slice the Targets
                let t_start = t_off_slice[i] as usize;
                let t_end = if i + 1 < t_off_slice.len() {
                    t_off_slice[i + 1] as usize
                } else {
                    t_slice.len()
                };
                let current_targets = &t_slice[t_start..t_end];

                // Dispatch exact clones to all targets
                for &target_id in current_targets {
                    let packet = OutgoingPacket {
                        target_id,
                        op_code: op,
                        payload: payload.clone(), // Arc/Bytes in Quinn can optimize this further later
                    };
                    let _ = tx.send(packet);
                }
            }
        }
    }
}
