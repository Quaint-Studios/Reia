use godot::prelude::*;

use bevy::prelude::*;
use godot_bevy::prelude::*;

mod sustenet;

#[bevy_app]
fn build_app(app: &mut App) {
    // GodotDefaultPlugins provides all standard godot-bevy functionality
    // For minimal setup, use individual plugins instead:
    // app.add_plugins(GodotTransformSyncPlugin)
    //     .add_plugins(GodotAudioPlugin)
    //     .add_plugins(BevyInputBridgePlugin);

    app.add_systems(Startup, hello_world);

    app.add_systems(Update, hello_world_system);
}

fn hello_world() {
    godot::prelude::godot_print!("Hello from godot-bevy!");
}

fn hello_world_system(mut state: Local<TickState>, time: Res<Time>) {
    // This runs every frame in Bevy's Update schedule
    state.tick_timer += time.delta_secs();
    let ticks_this_frame = (state.tick_timer / TICK_PERIOD).floor() as u64;

    if ticks_this_frame > 0 {
        state.ticks += ticks_this_frame;
        state.ticks_this_second += ticks_this_frame;
        state.tick_timer -= (ticks_this_frame as f32) * TICK_PERIOD;
        // Here we would run our fixed-tick game logic ticks_this_frame times (in a loop).
    }

    state.second_timer += time.delta_secs();
    if state.second_timer > 1.0 {
        state.second_timer -= 1.0;
        godot_print!(
            "Ticks: {}, Ticks per second: {}, Time: {:.2}, Delta this tick: {:.10}",
            state.ticks,
            state.ticks_this_second,
            time.elapsed_secs(),
            time.delta_secs()
        );
    }
}

//#region Tick Test
const TICK_RATE: f32 = 20.0;
const TICK_PERIOD: f32 = 1.0 / TICK_RATE;

struct TickState {
    tick_timer: f32,
    second_timer: f32,
    ticks: u64,
    ticks_this_second: u64,
}

impl Default for TickState {
    fn default() -> Self {
        Self {
            tick_timer: 0.0,
            second_timer: 0.0,
            ticks: 0,
            ticks_this_second: 0,
        }
    }
}
//#endregion Tick Test
