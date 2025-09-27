# Rust — Project Structure

---

## The goal of the Rust side 
Host authoritative game logic, high-performance networking (tokio), Turso DB access, and a gdext bridge to Godot. Keep nearly all Rust source under `src/` for IDE ergonomics and conventional crate layout.

---

## `Top-level` (what remains outside `src/`)
**Purpose:**  
Cargo-required artifacts and CI/bench/test drivers.

**Contents:**
- `Cargo.toml` — workspace / crate manifest(s) and feature declarations (declare features like `trace_tracy` here).
- `Config.toml` — Default settings for Sustenet.
- `README.md` — crate-level notes.
- `tests/` — integration tests (cargo expects this top-level).
- `benches/` — microbenchmarks (cargo bench).

---

## `src/`
**Purpose:**  
All primary library and binaries. Everything developers edit daily lives here.

**Contents:** Brief overview of folders inside `src/` below.

---

## `src/lib.rs`
**Purpose:**  
gdextension entrypoint; minimal registration only.

**Contents:**
- Register gdext singletons.
- Setup adapters and plugins.
- Keep minimal. No game logic here.

---

## `src/app/`
**Purpose:**  
Bevy integration entrypoints, app configuration, and tick driver.

**Contents:**
- `app_builder.rs` — build_app equivalent, plugin & schedule registration.
- `tick.rs` — fixed/flexible tick driver to pull from queues and run Bevy schedules.
- `mod.rs` — reexports and integration utilities.

---

## `src/game/`
**Purpose:**  
Bevy ECS domain code (components, bundles, systems, resources).

**Contents:**
- `components/` — data-only components (Health, Stealth, Position, Cooldowns).
- `bundles/` — spawn bundles (player, mob, region).
- `systems/` — domain systems (combat/, replication/, ai/, persistence/).
- `resources/` — shared resources (NetQueues, DbClientHandle, ShardRouting).
- `spawn/` — deterministic spawn/orchestration helpers.

---

## `src/network/`
**Purpose:**  
High-performance mio-based transport, framing, protocol, and queue adapters.

**Contents:**
- `socket/` — cross-platform socket helpers, SO_REUSEPORT logic.
- `driver/` — reactor/acceptor loops and IO worker scaffolding.
- `framing.rs` — size-prefix, compact framing, compression helpers.
- `protocol.rs` — packet shapes, handshake, versioning, reliability primitives.
- `queue/` — two-queue primitives (Server→Bevy, Bevy→Server), sharding-aware queues.
- `adapters.rs` — mapping between queue messages and Bevy resources.

---

## `src/bridge/`
**Purpose:**  
gdext exported types and thin Godot-facing wrappers.

**Contents:**
- `godot.rs` — registration helpers, class auto-registration calls.
- `player_bridge.rs` — PlayerBridge exposing `u64` entity id + typed signals.
- `net_bridge.rs` — snapshot send/recv wrappers (prefer zero-copy).

---

## `src/db/`
**Purpose:**  
Turso / libSQL async client, caching, and migrations.

**Contents:**
- `turso.rs` — async client wrapper (uses AsyncRuntime).
- `cache.rs` — small in-memory LRU caches for hot reads.
- `migrations/` — embedded SQL migrations & helpers.

---

## `src/util/`
**Purpose:**  ****
Small, reusable helpers and zero-cost abstractions.

**Contents:**
- `time.rs` — monotonic helpers and ms/µs conversions.
- `bytes.rs` — bytes::Bytes helpers (zero-copy framing), BytesMut utilities.
- `serdes.rs` — compact serde helpers / bitpacking primitives.
- `errors.rs` — crate error types and Result aliases.
- `metrics.rs` — counters and histograms (exposed to CI/bench).

---

## `src/externals/`
**Purpose:**  
Isolated vendored or patched third-party stacks.

**Contents:**
- `sustenet/` — vendored sustenet and local patches.
- `bindings/` — other C/Rust glue kept isolated.

---

## `src/tools/` and `src/bin/`
**Purpose:**  
CLI tools and binaries (kept inside `src/` to avoid top-level clutter).

**Contents:**
- `bin/server_main.rs` — headless server binary (network + game driver).
- `bin/migrate.rs` — migration CLI (calls `db::migrations`).
- `tools/` — helper CLIs used by CI/devs.

---

## `src/tests_unit/`
**Purpose:**  
Unit-test helpers and mocks kept inside `src/` for easier referencing.

**Contents:**
- Mock implementations for network queues and DB clients to accelerate tests.

---

## General Notes
- **Two-queue pattern** bounded, backpressured queues in `src/network/queue` (use `crossbeam`/`flume`).
  - **Server→Bevy: IO threads** push `Bytes`/events → Bevy tick systems dequeue.
  - **Bevy→Server: systems** push frames → IO threads dequeue and flush.
- **Start single Bevy** `World`; measure and shard by region only when needed.
- **Prefer zero-copy** (`bytes::Bytes`) for framing; minimize allocations on Godot thread.
- **Explicitly declare features** in `Cargo.toml` (e.g., `trace_tracy`) to avoid `unexpected_cfgs` warnings.
- **Document ownership** list which thread owns each queue/resource and crossing points.

## Example Structure

```


src/
├── lib.rs              // Crate root, wires up plugins
├── bridge/             // Godot gdext bindings
├── db/                 // Database layer
├── network/            // Network protocol and session management
└── game/
    ├── mod.rs          // Publicly exports modules for the main lib
    ├── common/         // Truly global types (Health, Mana, AppState, custom Vec3)
    │
    ├── features/       // Self-contained, reusable "Lego bricks" of gameplay
    │   ├── mod.rs
    │   ├── combat/       // All logic for combat mechanics (damage, abilities, effects)
    │   │   ├── components.rs
    │   │   ├── systems.rs
    │   │   ├── events.rs
    │   │   └── plugin.rs // Bevy plugin for the combat feature
    │   ├── movement/     // All logic for movement and navigation
    │   │   └── ...
    │   ├── inventory/    // All logic for item management
    │   │   └── ...
    │   └── replication/  // Your network replication logic is a core feature
    │       └── ...
    │
    └── world/            // Concrete entities that compose features
        ├── mod.rs
        ├── player/       // Player-specific logic and assembly
        │   ├── components.rs // Components ONLY for the player (e.g., IsPlayer)
        │   ├── systems.rs  // Systems ONLY for the player (e.g., input handling)
        │   └── plugin.rs   // Bevy plugin that assembles a player from various features
        │
        ├── npcs/         // Non-player characters
        │   ├── mod.rs
        │   ├── vendor.rs   // Logic for a vendor NPC
        │   └── quest_giver.rs
        │
        └── creatures/    // AI-driven mobs
            ├── mod.rs
            ├── wolf/       // Logic specific to wolves (e.g., pack AI)
            │   └── plugin.rs
            └── dragon/     // Logic specific to dragons
                └── plugin.rs
```
