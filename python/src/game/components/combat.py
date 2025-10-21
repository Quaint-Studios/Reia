"""
Combat components and systems for the ECS game logic.

Converted from Rust to Python 3.14
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional, Tuple, Protocol, Any


# Basis points constants for fixed-point math
BASIS: int = 10_000
ROUND: int = BASIS // 2


class Entity(Protocol):
    """Protocol for entity types (to be implemented by ECS system)"""
    id: Any


class Component:
    """Base class for all components"""
    pass


class Event:
    """Base class for all events"""
    pass


@dataclass
class Health(Component):
    """Health component for entities"""
    current: int = 100
    max: int = 100

    def __post_init__(self):
        """Ensure health values are valid"""
        if self.current < 0:
            self.current = 0
        if self.current > self.max:
            self.current = self.max


@dataclass
class HealthChanged(Event):
    """Event fired when an entity's health changes"""
    entity: Any  # Entity reference
    health: int
    max_health: int


def health_changed_system(entities, event_writer) -> None:
    """
    System that detects health changes and emits HealthChanged events.

    Args:
        entities: Query of entities with Health component that have changed
        event_writer: Event writer for HealthChanged events
    """
    for entity, health in entities:
        event_writer.write(HealthChanged(
            entity=entity,
            health=health.current,
            max_health=health.max,
        ))


class AttackType(Enum):
    """Types of attacks in the combat system"""
    MELEE = "melee"
    BOW = "bow"
    SPELL = "spell"


@dataclass
class Stats(Component):
    """
    Combat statistics for an entity.

    Power and defense values for three attack types.
    Crit chance and damage use basis points (10000 = 100.00%)
    """
    melee_power: int = 10
    bow_power: int = 10
    spell_power: int = 10

    melee_defense: int = 5
    bow_defense: int = 5
    spell_defense: int = 5

    # Crit chance in basis points (10000 == 100.00%)
    crit_chance: int = 10
    # Crit extra damage in basis points (e.g. 5000 => +50% on crit)
    crit_damage: int = 50

    def power_for(self, attack_type: AttackType) -> int:
        """Get the power value for a specific attack type"""
        match attack_type:
            case AttackType.MELEE:
                return self.melee_power
            case AttackType.BOW:
                return self.bow_power
            case AttackType.SPELL:
                return self.spell_power

    def defense_for(self, attack_type: AttackType) -> int:
        """Get the defense value for a specific attack type"""
        match attack_type:
            case AttackType.MELEE:
                return self.melee_defense
            case AttackType.BOW:
                return self.bow_defense
            case AttackType.SPELL:
                return self.spell_defense


def resolve_damage(
    target_health: Health,
    attacker: Stats,
    target: Stats,
    weapon: AttackType,
    ability_multiplier: Optional[int] = None,
    rng_roll: int = 0
) -> Tuple[int, bool]:
    """
    Resolve an attack using integer math and basis-point multipliers.

    Args:
        target_health: The health component to modify
        attacker: Stats of the attacking entity
        target: Stats of the target entity
        weapon: Type of attack being used
        ability_multiplier: Optional multiplier in basis points (10000 = 1.0)
        rng_roll: Random value in 0..=10000 for crit checks

    Returns:
        Tuple of (damage_applied, was_crit)
    """
    atk_power = attacker.power_for(weapon)

    # Apply ability multiplier if present
    if ability_multiplier is not None:
        # Fixed-point multiply with rounding
        atk_power = int((atk_power * ability_multiplier + ROUND) / BASIS)

    # Calculate base damage (clamped to zero)
    defense = target.defense_for(weapon)
    damage = max(0, atk_power - defense)

    # Check for critical hit
    is_crit = rng_roll < attacker.crit_chance
    if is_crit and damage > 0:
        # Apply crit: damage *= (1.0 + crit_damage)
        crit_mul = BASIS + attacker.crit_damage
        damage = int((damage * crit_mul + ROUND) / BASIS)

    # Apply damage to target (clamped to zero)
    target_health.current = max(0, target_health.current - damage)

    return (damage, is_crit)
