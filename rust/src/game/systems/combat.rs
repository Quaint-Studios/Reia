use crate::game::components::combat::{ AttackType, Health, HealthChanged, Stats, resolve_damage };
use crate::game::systems::rng::GameRng;
use bevy::prelude::*;

/// Event describing a single attack intent. Minimal and cheap.
#[derive(Event)]
pub struct AttackEvent {
    pub attacker: Entity,
    pub target: Entity,
    pub weapon: AttackType, // small enum (passed by ref to resolve)
    pub ability_multiplier_bp: Option<u16>, // 10000 = 1.0
}

/// Consume AttackEvent and apply damage.
/// Note: `events` must be provided and the event type registered with `app.add_event::<AttackEvent>()`.
pub fn apply_attack_events(
    mut ev_reader: EventReader<AttackEvent>,
    mut health_q: Query<&mut Health>,
    stats_q: Query<&Stats>,
    mut rng: ResMut<GameRng>,
    mut health_changed: EventWriter<HealthChanged> // emit health changes for other systems
) {
    for ev in ev_reader.read() {
        // get attacker stats
        let attacker_stats = match stats_q.get(ev.attacker) {
            Ok(s) => s,
            Err(_) => {
                continue;
            } // attacker missing stats to skip
        };

        // get target stats
        let target_stats = match stats_q.get(ev.target) {
            Ok(s) => s,
            Err(_) => {
                continue;
            } // target missing stats -> skip or treat as zero-def (choice)
        };

        // apply damage if target has health
        if let Ok(mut health) = health_q.get_mut(ev.target) {
            let roll = rng.next_u16_in_basis();
            let (damage, was_crit) = resolve_damage(
                &mut *health,
                attacker_stats,
                target_stats,
                &ev.weapon, // pass by ref
                ev.ability_multiplier_bp,
                roll
            );

            // emit health changed event (keep this cheap)
            health_changed.write(HealthChanged {
                entity: ev.target,
                health: health.current,
                max_health: health.max,
            });

            // todo: add lightweight hooks for crits / VFX in other systems that listen to HealthChanged
            let _ = was_crit; // placeholder to avoid unused warnings if you don't use it yet
        }
    }
}

/// Simple label (or event) to mark death handling systems
#[derive(SystemSet, Clone, Hash, PartialEq, Eq, Debug)]
pub enum CombatSet {
    Damage,
    Death,
}

/// System: mark / process dead entities
pub fn death_system(mut commands: Commands, query: Query<(Entity, &Health), Changed<Health>>) {
    for (entity, health) in query.iter() {
        if health.current <= 0 {
            // handle death: state change, drop loot, remove components, or despawn
            // keep heavy effects (spawn particles, sound) in a separate system that listens to DeathEvent.
            commands.entity(entity).remove::<(/* combat components we want to clear */)>();
            // And maybe we'll despawn them.
            // commands.entity(entity).despawn_recursive();
        }
    }
}
