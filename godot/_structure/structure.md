# Project Structure

---

## `addons/`
**Purpose:**
Custom Godot plugins and editor extensions.
**Contents:**
- In-house or third-party tools that extend the Godot editor.
- Asset pipeline utilities, e.g., importers, batch processors.
- Should be modular, reusable, and versioned independently where possible.

---

## `assets/`
**Purpose:**
All raw and processed artistic assets used by the project.
**Contents:**
- `audio/` — BGM and SFX, organized by context (bosses, regions, enemies, player, UI, etc.).
- `fonts/` — Font files for UI and localization.
- `icons/` — All 2D icons for UI, items, abilities, etc., further organized by category.
- `models/` — 3D models, grouped by type (enemies, player, props, etc.).
- `textures/` — All 2D textures, grouped by context (enemies, player, props, effects, UI).
- **Best Practice:** Do not place code, scenes, or scripts here; this directory is strictly for media assets.

---

## `entities/`
**Purpose:**
Game entity feature bundles—each folder contains everything needed for a specific in-game object (player, enemy, NPC, props).
**Contents:**
- Scripts, scenes, configs, and references for each entity.
- Subfolders for base logic or traits (e.g., `base/attackable.gd`), and for each entity type (e.g., `enemies/`, `npcs/`, `player/`).
- Promotes modularity, easy content addition, and clear asset ownership.

---

## `features/`
**Purpose:**
Modular, reusable gameplay systems not tied to a single entity.
**Contents:**
- Systems like inventory, chat, party, quest, guild, etc.
- Each feature is self-contained and can be used or extended by multiple entities.
- Typically includes logic, UI, and resource files relevant to the feature.

---

## `presentation/`
**Purpose:**
All visual presentation logic and assets, decoupled from core gameplay logic.
**Contents:**
- UI scenes/components (HUD, menus, dialogs, inventory screens, etc.).
- Visual effects and post-processing scripts.
- Theming and style resources.
- Helps enforce a clean MVC separation between game logic and user-facing presentation.

---

## `scenes/`
**Purpose:**
Spatial and structural scenes representing the game world and its regions.
**Contents:**
- World, region, dungeon, and map scenes.
- Spawn points, environmental compositions, and navigation meshes.
- Should not contain reusable entity or feature logic (that belongs in `entities/` or `features/`), but can reference entities as needed.

---

## `scripts/`
**Purpose:**
Standalone scripts, utilities, or code that supports the build, import, or data migration process.
**Contents:**
- One-off or batch processing scripts (e.g., `batch_import.gd`, `cleanup_unused_assets.gd`).
- Build tools, editor helpers, and migration logic.
- Not intended for core gameplay logic.

---

## `systems/`
**Purpose:**
Core infrastructural systems that underpin the game's operation, often cross-cutting concerns.
**Contents:**
- Networking (client, server logic, protocol handlers).
- Save/load and persistence.
- Analytics and telemetry.
- These are foundational and may be referenced by both features and entities.

---

## `tests/`
**Purpose:**
Automated tests for code, logic, and asset validation.
**Contents:**
- Unit, integration, and presentation/UI tests.
- Data validation scripts.
- Should be organized to mirror the structure of the codebase it tests.

---

## `tools/`
**Purpose:**
Custom project tools to aid development, asset management, and localization.
**Contents:**
- Editor plugins, asset validators, scene generators, localization checkers, etc.
- May include scripts or binaries for integration with build/CI pipelines.
- Should not contain core game logic.

---

## `tree.log`
**Purpose:**
An example of the structure of this project.
**Contents:**
- Used for audits, onboarding, or documentation purposes.
- Not required for the game to function.

---

## General Notes

- **Keep each directory focused** on its primary purpose to avoid messy logic, assets, or presentation.
- **Maintain consistent naming and organization** to ensure long-term maintainability and scalability.
