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
All raw and processed assets used by the project.
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
- Shaders (materials, post processing, ui, particles, etc.).
- Helps enforce a clean MVC separation between game logic and user-facing presentation.

---

## `scenes/`
**Purpose:**
The game world and regions.
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
Core logic that holds up and runs the entire game.
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

## General Notes

- **Keep each directory focused** on its primary purpose to avoid messy logic, assets, or presentation.
- **Maintain consistent naming and organization** to ensure long-term maintainability and scalability.

```

./
├── addons
├── assets/
│   ├── audio/
│   │   ├── bgm/
│   │   │   ├── bosses/
│   │   │   │   └── king_slime_theme.gitkeep
│   │   │   ├── main_theme.gitkeep
│   │   │   └── regions/
│   │   │       ├── jadewater_falls.gitkeep
│   │   │       └── waterbrook_city.gitkeep
│   │   └── sfx/
│   │       ├── enemies/
│   │       │   ├── common/
│   │       │   │   ├── goblin_attack_swipe.gitkeep
│   │       │   │   ├── goblin_laugh.gitkeep
│   │       │   │   ├── slime_attack_ram.gitkeep
│   │       │   │   └── slime_died_regular.gitkeep
│   │       │   ├── goblin/
│   │       │   │   └── laugh.gitkeep
│   │       │   ├── king_slime/
│   │       │   │   ├── attack.gitkeep
│   │       │   │   ├── died.gitkeep
│   │       │   │   ├── jump.gitkeep
│   │       │   │   └── roar.gitkeep
│   │       │   └── slime/
│   │       │       ├── attack.gitkeep
│   │       │       ├── hurt.gitkeep
│   │       │       └── jump.gitkeep
│   │       ├── npcs
│   │       ├── player/
│   │       │   ├── abilities/
│   │       │   │   └── dash.gitkeep
│   │       │   ├── combat/
│   │       │   │   ├── blunt_attack_hit.gitkeep
│   │       │   │   ├── bow_attack_hit.gitkeep
│   │       │   │   ├── pierce_attack_hit.gitkeep
│   │       │   │   ├── slash_attack_hit.gitkeep
│   │       │   │   ├── slash_attack_swing.gitkeep
│   │       │   │   └── spell_attack_hit.gitkeep
│   │       │   └── movement/
│   │       │       ├── sprint_start.gitkeep
│   │       │       └── sprint_stop.gitkeep
│   │       ├── props/
│   │       │   ├── chest/
│   │       │   │   ├── chest_close.gitkeep
│   │       │   │   └── chest_open.gitkeep
│   │       │   └── lever/
│   │       │       └── lever_pull.gitkeep
│   │       └── ui/
│   │           ├── chat/
│   │           │   ├── friend_request_accepted.gitkeep
│   │           │   ├── friend_request_received.gitkeep
│   │           │   ├── friend_request_rejected.gitkeep
│   │           │   ├── friend_request_sent.gitkeep
│   │           │   ├── message_received.gitkeep
│   │           │   └── message_sent.gitkeep
│   │           └── common/
│   │               ├── click.gitkeep
│   │               ├── error.gitkeep
│   │               └── notification.gitkeep
│   ├── fonts/
│   │   └── poppins-latin-400-normal.gitkeep
│   ├── icons/
│   │   ├── abilities/
│   │   │   └── dash.gitkeep
│   │   ├── items/
│   │   │   ├── consumables/
│   │   │   │   └── potion.gitkeep
│   │   │   └── weapons/
│   │   │       └── sword_a.gitkeep
│   │   ├── status/
│   │   │   ├── poison.gitkeep
│   │   │   └── stun.gitkeep
│   │   └── ui/
│   │       └── button_play.gitkeep
│   ├── models/
│   │   ├── effects
│   │   ├── enemies/
│   │   │   ├── goblin/
│   │   │   │   └── goblin.gitkeep
│   │   │   ├── king_slime/
│   │   │   │   ├── king_slime.gitkeep
│   │   │   │   └── king_slime_lod1.gitkeep
│   │   │   └── slime/
│   │   │       ├── eye_albedo.gitkeep
│   │   │       ├── slime.gitkeep
│   │   │       └── slime_lod1.gitkeep
│   │   ├── player/
│   │   │   ├── body_a.gitkeep
│   │   │   └── body_b.gitkeep
│   │   └── props/
│   │       ├── buildings/
│   │       │   ├── generic_building_a.gitkeep
│   │       │   ├── jadewater_falls_building_1.gitkeep
│   │       │   ├── wall_left_a.gitkeep
│   │       │   └── waterbrook_building_1.gitkeep
│   │       ├── cave/
│   │       │   └── cave_rock.gitkeep
│   │       ├── city/
│   │       │   ├── bench.gitkeep
│   │       │   └── lamp_post.gitkeep
│   │       ├── dungeon/
│   │       │   ├── brazier.gitkeep
│   │       │   └── dungeon_altar.gitkeep
│   │       ├── forest/
│   │       │   └── forest_tree.gitkeep
│   │       ├── grass/
│   │       │   ├── dark_grass.gitkeep
│   │       │   └── light_grass.gitkeep
│   │       └── interactive/
│   │           ├── chest.gitkeep
│   │           └── lever.gitkeep
│   └── textures/
│       ├── effects/
│       │   ├── fire_noise.gitkeep
│       │   └── water_normal.gitkeep
│       ├── enemies/
│       │   ├── goblin_albedo.gitkeep
│       │   ├── slime_body_albedo_g.gitkeep
│       │   └── slime_eye_albedo_g.gitkeep
│       ├── player/
│       │   ├── body_albedo_g.gitkeep
│       │   └── body_normal_g.gitkeep
│       ├── props
│       └── ui
├── entities/
│   ├── base/
│   │   └── attackable.gd.gitkeep
│   ├── enemies
│   ├── npcs
│   └── player/
│       ├── player.gd.gitkeep
│       ├── player_animator.gd.gitkeep
│       ├── player_inventory.gd.gitkeep
│       ├── player_scene.tscn.gitkeep
│       └── player_stats.tres.gitkeep
├── features/
│   ├── chat/
│   │   ├── chat_filter.gd.gitkeep
│   │   ├── chat_manager.gd.gitkeep
│   │   └── chat_ui.tscn.gitkeep
│   ├── guild/
│   │   ├── guild_manager.gd.gitkeep
│   │   └── guild_ui.tscn.gitkeep
│   ├── interactable/
│   │   └── interactable.gd.gitkeep
│   ├── inventory/
│   │   ├── equipment.gd.gitkeep
│   │   ├── inventory_manager.gd.gitkeep
│   │   └── item.gd.gitkeep
│   ├── party/
│   │   ├── party_invite.gd.gitkeep
│   │   ├── party_manager.gd.gitkeep
│   │   └── party_ui.gd.gitkeep
│   └── quest/
│       ├── quest.gd.gitkeep
│       ├── quest_manager.gd.gitkeep
│       └── quest_objectives.gd.gitkeep
├── presentation/
│   ├── effects/
│   │   ├── particles/
│   │   │   ├── fireball.tscn.gitkeep
│   │   │   └── heal_effect.tscn.gitkeep
│   │   └── post_process/
│   │       ├── bloom.gd.gitkeep
│   │       └── vignette.gd.gitkeep
│   ├── shaders/
│   │   ├── materials/
│   │   │   └── pbr_water.gdshader.gitkeep
│   │   ├── particles/
│   │   │   └── dissolve.gdshader.gitkeep
│   │   ├── post_process/
│   │   │   ├── outline.gdshader.gitkeep
│   │   │   └── bloom.gdshader.gitkeep
│   │   └── ui/
│   │       └── grayscale.gdshader.gitkeep
│   └── ui/
│       ├── components/
│       │   ├── health_bar.gitkeep
│       │   └── xp_bar.gitkeep
│       ├── hud/
│       │   ├── hud.gitkeep
│       │   └── minimap.gitkeep
│       ├── inventory
│       ├── main_menu
│       └── themes
├── scenes/
│   ├── dungeons
│   ├── regions/
│   │   ├── jadewater_falls/
│   │   │   └── jadewater_falls.tscn.gitkeep
│   │   └── waterbrook_city/
│   │       └── waterbrook_city.tscn.gitkeep
│   └── world/
│       ├── world_manager.gd.gitkeep
│       ├── world_map.tscn.gitkeep
│       └── world_navmesh.tres.gitkeep
├── scripts/
│   ├── batch_import.gd.gitkeep
│   ├── build_tools.gd.gitkeep
│   ├── cleanup_unused_assets.gd.gitkeep
│   ├── debug_draw.gd.gitkeep
│   └── migrate_data.gd.gitkeep
├── systems/
│   ├── analytics/
│   │   └── analytics_manager.gd.gitkeep
│   ├── networking/
│   │   └── net_manager.gd.gitkeep
│   └── save_load/
│       ├── load_manager.gd.gitkeep
│       └── save_manager.gd.gitkeep
├── tests/
│   ├── data/
│   │   ├── test_item_table.gd.gitkeep
│   │   └── test_skill_defs.gd.gitkeep
│   ├── integration/
│   │   ├── test_network_sync.gd.gitkeep
│   │   ├── test_party_system.gd.gitkeep
│   │   └── test_trading_flow.gd.gitkeep
│   ├── presentation/
│   │   ├── test_chat_ui.gd.gitkeep
│   │   └── test_hud_ui.gd.gitkeep
│   └── unit/
│       ├── test_combat_manager.gd.gitkeep
│       ├── test_inventory_manager.gd.gitkeep
│       └── test_quest_manager.gd.gitkeep
└── tools/
    ├── asset_validator.gd.gitkeep
    ├── localization_checker.gd.gitkeep
    ├── map_importer.gd.gitkeep
    └── scene_generator.gd.gitkeep
```