use bevy::{
    app::{ App, FixedUpdate },
    ecs::{ schedule::IntoScheduleConfigs, system::{ Local, Res } },
    time::{ Fixed, Time },
};
use godot::global::godot_print;

use crate::game::{
    components::combat::{ HealthChanged, health_changed_system },
    systems::{
        combat::{ AttackEvent, CombatSet, apply_attack_events, death_system },
        rng::GameRng,
    },
};

mod components;
mod nodes;
mod plugins;
mod systems;

pub fn register(app: &mut App) {
    // deterministic / authoritative tick rate for simulation (20 Hz)
    app.insert_resource(Time::<Fixed>::from_hz(20.0));

    // RNG, events, and combat registration
    app.insert_resource(GameRng::default());

    app.add_event::<AttackEvent>();
    app.add_event::<HealthChanged>();

    app.add_systems(FixedUpdate, apply_attack_events.in_set(CombatSet::Damage));
    app.add_systems(FixedUpdate, health_changed_system.after(CombatSet::Damage));
    app.add_systems(FixedUpdate, death_system.in_set(CombatSet::Death).after(CombatSet::Damage));

    // Diagnostic: counts FixedUpdate ticks and prints once per second
    app.add_systems(FixedUpdate, count_updates_system);
}

/// Diagnostic helper: counts FixedUpdate invocations per second.
/// Uses Local state to avoid global mutation and to be safe across threads.
fn count_updates_system(
    mut counter: Local<u32>,
    mut last_print: Local<f32>,
    time: Res<Time<Fixed>>
) {
    *counter += 1;

    // elapsed seconds since app start (Fixed time)
    let elapsed = time.elapsed_secs();

    // print once per second
    if elapsed - *last_print >= 1.0 {
        godot_print!("FixedUpdate ticks/sec: {}", *counter);
        *counter = 0;
        *last_print = elapsed;
    }
}
