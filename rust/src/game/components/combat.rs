use bevy::ecs::{
    component::Component,
    entity::Entity,
    event::{ Event, EventWriter },
    query::Changed,
    system::Query,
};

const BASIS: i64 = 10_000;
const ROUND: i64 = BASIS / 2;

#[derive(Component, Debug)]
pub struct Health {
    pub current: i32,
    pub max: i32,
}

impl Default for Health {
    fn default() -> Self {
        Health {
            current: 100,
            max: 100,
        }
    }
}

#[derive(Event, Debug)]
pub struct HealthChanged {
    pub entity: Entity,
    pub health: i32,
    pub max_health: i32,
}

pub fn health_changed_system(
    mut ev: EventWriter<HealthChanged>,
    query: Query<(Entity, &Health, Option<&Health>), Changed<Health>>
) {
    for (ent, health, max) in query.iter() {
        let max_hp = max.map_or(health.current, |m| m.current);
        ev.write(HealthChanged {
            entity: ent,
            health: health.current,
            max_health: max_hp,
        });
    }
}

#[derive(Debug)]
pub enum AttackType {
    Melee,
    Bow,
    Spell,
}

#[derive(Component, Debug)]
pub struct Stats {
    pub melee_power: i32,
    pub bow_power: i32,
    pub spell_power: i32,

    pub melee_defense: i32,
    pub bow_defense: i32,
    pub spell_defense: i32,

    /// crit chance in basis points (10000 == 100.00%)
    pub crit_chance: u16,
    /// crit extra damage in basis points (e.g. 5000 => +50% on crit)
    pub crit_damage: u16,
}

impl Default for Stats {
    fn default() -> Self {
        Stats {
            melee_power: 10,
            bow_power: 10,
            spell_power: 10,

            melee_defense: 5,
            bow_defense: 5,
            spell_defense: 5,

            crit_chance: 10,
            crit_damage: 50,
        }
    }
}

impl Stats {
    #[inline]
    pub fn power_for(&self, atk: &AttackType) -> i32 {
        match atk {
            AttackType::Melee => self.melee_power,
            AttackType::Bow => self.bow_power,
            AttackType::Spell => self.spell_power,
        }
    }

    #[inline]
    pub fn defense_for(&self, atk: &AttackType) -> i32 {
        match atk {
            AttackType::Melee => self.melee_defense,
            AttackType::Bow => self.bow_defense,
            AttackType::Spell => self.spell_defense,
        }
    }
}

/// Resolve an attack using integer math and basis-point multipliers.
/// - `ability_multiplier`: optional multiplier in basis points (10000 = 1.0)
/// - `rng_roll_bp`: random u16 in 0..=10000 for crit checks
/// Returns (damage_applied, was_crit)
pub fn resolve_damage(
    target_health: &mut Health,
    attacker: &Stats,
    target: &Stats,
    weapon: &AttackType,
    ability_multiplier: Option<u16>,
    rng_roll: u16
) -> (i32, bool) {
    let mut atk_power = attacker.power_for(weapon);

    if let Some(mult) = ability_multiplier {
        // fixed-point multiply with rounding
        atk_power = (((atk_power as i64) * (mult as i64) + ROUND) / BASIS) as i32;
    }

    let defense = target.defense_for(weapon);
    let mut damage = atk_power.saturating_sub(defense); // clamp to zero via saturating_sub

    let is_crit = rng_roll < attacker.crit_chance;
    if is_crit && damage > 0 {
        // apply crit: damage *= (1.0 + crit_damage)
        let crit_mul = BASIS + (attacker.crit_damage as i64);
        damage = (((damage as i64) * crit_mul + ROUND) / BASIS) as i32;
    }

    target_health.current = target_health.current.saturating_sub(damage);
    (damage, is_crit)
}
