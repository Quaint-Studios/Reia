"""
Combat systems for the ECS game logic.

Converted from Rust to Python 3.14
"""

from dataclasses import dataclass
from enum import Enum
from typing import Protocol, Any, Optional

from ..components.combat import (
    AttackType,
    Health,
    HealthChanged,
    Stats,
    resolve_damage,
)
from .rng import GameRng


class Entity(Protocol):
    """Protocol for entity types"""
    id: Any


class EventReader(Protocol):
    """Protocol for event readers"""
    def read(self):
        """Read events from the event queue"""
        ...


class EventWriter(Protocol):
    """Protocol for event writers"""
    def write(self, event: Any) -> None:
        """Write an event to the event queue"""
        ...


class Query(Protocol):
    """Protocol for ECS queries"""
    def get(self, entity: Entity):
        """Get component for entity"""
        ...

    def get_mut(self, entity: Entity):
        """Get mutable component for entity"""
        ...

    def iter(self):
        """Iterate over query results"""
        ...


class Commands(Protocol):
    """Protocol for ECS commands"""
    def entity(self, entity: Entity):
        """Get entity commands"""
        ...


@dataclass
class AttackEvent:
    """
    Event describing a single attack intent. Minimal and cheap.

    Attributes:
        attacker: Entity performing the attack
        target: Entity being attacked
        weapon: Type of attack being used
        ability_multiplier_bp: Optional ability multiplier in basis points (10000 = 1.0)
    """
    attacker: Any  # Entity
    target: Any  # Entity
    weapon: AttackType
    ability_multiplier_bp: Optional[int] = None


def apply_attack_events(
    ev_reader: EventReader,
    health_q: Query,
    stats_q: Query,
    rng: GameRng,
    health_changed: EventWriter,
) -> None:
    """
    Consume AttackEvent and apply damage.

    Note: `events` must be provided and the event type registered with the app.

    Args:
        ev_reader: Event reader for AttackEvent
        health_q: Query for Health components (mutable)
        stats_q: Query for Stats components
        rng: Game RNG resource
        health_changed: Event writer for HealthChanged events
    """
    for ev in ev_reader.read():
        # Get attacker stats
        try:
            attacker_stats = stats_q.get(ev.attacker)
        except Exception:
            # Attacker missing stats -> skip
            continue

        # Get target stats
        try:
            target_stats = stats_q.get(ev.target)
        except Exception:
            # Target missing stats -> skip
            continue

        # Apply damage if target has health
        try:
            health = health_q.get_mut(ev.target)
            roll = rng.next_u16_in_basis()
            damage, was_crit = resolve_damage(
                health,
                attacker_stats,
                target_stats,
                ev.weapon,
                ev.ability_multiplier_bp,
                roll
            )

            # Emit health changed event (keep this cheap)
            health_changed.write(HealthChanged(
                entity=ev.target,
                health=health.current,
                max_health=health.max,
            ))

            # TODO: add lightweight hooks for crits / VFX in other systems
            # that listen to HealthChanged
            _ = was_crit  # Placeholder to avoid unused warnings

        except Exception:
            # Target doesn't have health component
            continue


class CombatSet(Enum):
    """Simple label for combat system ordering"""
    DAMAGE = "damage"
    DEATH = "death"


def death_system(commands: Commands, query: Query) -> None:
    """
    System to mark/process dead entities.

    Args:
        commands: Commands for entity manipulation
        query: Query for entities with Health component that have changed
    """
    for entity, health in query.iter():
        if health.current <= 0:
            # Handle death: state change, drop loot, remove components, or despawn
            # Keep heavy effects (spawn particles, sound) in a separate system
            # that listens to DeathEvent.

            # Remove combat components we want to clear
            # commands.entity(entity).remove(...)

            # Maybe despawn the entity
            # commands.entity(entity).despawn_recursive()
            pass
