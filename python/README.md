# Reia - Python 3.14 Version

This is the Python 3.14 conversion of the Reia game engine extension, originally written in Rust.

## Overview

Reia is an open-source RPG/MMO game engine extension that integrates with Godot Engine. The Python version maintains the same architecture and functionality as the Rust version while leveraging Python's ease of development.

## Architecture

### Modules

- **extras/godot_asyncio.py** - AsyncIO integration for Godot (converted from Tokio)
- **game/components/** - ECS component definitions
  - `combat.py` - Health, Stats, AttackType, damage resolution
  - `movement.py` - Position, Rotation, Velocity, Speed
- **game/systems/** - ECS system implementations
  - `combat.py` - Attack events, damage application, death handling
  - `rng.py` - Deterministic RNG for gameplay
  - `ai.py` - AI systems (placeholder)
  - `replication.py` - Network replication (placeholder)
- **network/** - Multiplayer networking (placeholder)
  - `client.py` - Client network communication
  - `server.py` - Game server
  - `protocol.py` - Message serialization
  - `master.py` - Master server for matchmaking
- **db/** - Database integration (placeholder)
  - `turso.py` - Turso/LibSQL database client

### Key Conversions

| Rust | Python 3.14 |
|------|-------------|
| Tokio runtime | asyncio event loop |
| Bevy ECS | Custom component system / esper library |
| SmallRng | random.Random |
| Turso crate | libsql-client |
| godot-rust | godot-python |

## Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Or install in development mode
pip install -e ".[dev]"
```

## Development

### Running Tests

```bash
pytest
```

### Code Formatting

```bash
# Format code
black src/

# Lint code
ruff check src/
```

### Type Checking

```bash
mypy src/
```

## Key Features

### Async Runtime Integration

The `AsyncRuntime` class provides integration between Godot's synchronous execution and Python's asyncio:

```python
from extras.godot_asyncio import AsyncRuntime

# Spawn async task
task = AsyncRuntime.spawn(my_coroutine())

# Block until complete
result = AsyncRuntime.block_on(my_coroutine())

# Run blocking function in thread pool
future = runtime.spawn_blocking(my_blocking_function)
```

### Combat System

The combat system uses fixed-point math with basis points (10000 = 100%) to avoid floating-point precision issues:

```python
from game.components.combat import Health, Stats, AttackType, resolve_damage

attacker = Stats(melee_power=15, crit_chance=500)  # 5% crit
target_health = Health(current=100, max=100)
target_stats = Stats(melee_defense=5)

damage, was_crit = resolve_damage(
    target_health,
    attacker,
    target_stats,
    AttackType.MELEE,
    ability_multiplier=15000,  # 1.5x damage
    rng_roll=250  # Random 0-10000
)
```

### Deterministic RNG

The `GameRng` class provides both seeded (deterministic) and entropy-based RNG:

```python
from game.systems.rng import GameRng

# Deterministic (for multiplayer/replays)
rng = GameRng.from_seed(12345)

# Non-deterministic (for single-player)
rng = GameRng.from_entropy()

# Generate values
roll = rng.next_u16_in_basis()  # 0-10000
value = rng.next_f32()  # 0.0-1.0
```

## Differences from Rust Version

1. **Type Safety** - Python uses type hints instead of Rust's compile-time type checking
2. **Memory Management** - Python uses garbage collection instead of Rust's ownership system
3. **Performance** - Rust version will be faster; Python version prioritizes development speed
4. **Dependencies** - Some Rust-specific libraries replaced with Python equivalents
5. **ECS** - Simplified component system; can use external library like esper if needed

## Project Status

This is an alpha version with core systems implemented:
- ✅ AsyncIO integration
- ✅ Combat components and systems
- ✅ Movement components
- ✅ RNG system
- ⚠️  Network systems (placeholder)
- ⚠️  Database integration (placeholder)
- ⚠️  Game world entities (placeholder)
- ⚠️  AI systems (placeholder)

## Contributing

This project is converted from Rust to Python 3.14. Please maintain consistency with the original architecture when contributing.

## License

MIT License (same as original Rust version)

## Original Rust Version

The original Rust implementation can be found in the `/rust` directory.
