# Godot + GECS Hybrid MMO Architecture (Production Edition)

> Still actively being improved but the core architecture is now stable. Expect new sections and code samples to be added over time.

This document outlines the architecture for a hybrid MMO/Offline game using Godot 4.x and `gecs`. It enforces a strict **Simulation (ECS)** vs. **Presentation (Godot Nodes)** split, ensuring maximum performance, network authority, and code maintainability, utilizing native GECS patterns (Prefabs, Observers, Relationships, and Command Buffers).

## 1\. Massive Scale Project Structure

When dealing with tens of thousands of files across complex MMO systems, we use **Domain-Driven Design**. Everything is grouped by feature, and named using GECS conventions (`C_Component`, `SystemNameSystem`, `e_entity_name.gd`).

```
res://
├── core/                               # The ECS Brain (Pure Logic & Data)
│   ├── network/                        # Custom GDExtension Networking Wrapper
│   │   ├── packets/                    # Serializers for byte-packing
│   │   ├── error_category.gd           # Global bit-packed error registry
│   │   └── NetworkCore.gd
│   ├── utils/                          # Pure functional helpers
│   ├── features/                       # **DOMAIN-DRIVEN FEATURE FOLDERS**
│   │   ├── bestiary/
│   │   │   ├── components/             # c_monster_tag.gd, c_boss.gd
│   │   │   └── systems/                # s_monster_ai.gd
│   │   ├── combat/
│   │   │   ├── components/             # c_damage_event.gd, c_dead.gd
│   │   │   └── systems/                # s_damage_calculation.gd
│   │   ├── inventory/
│   │   │   ├── components/             # c_inventory_data.gd, c_has_item.gd
│   │   │   ├── inventory_errors.gd     # Feature-specific packed errors
│   │   │   └── systems/
│   │   │       ├── validators/         # s_dungeon_stash_validator.gd, s_bank_access.gd
│   │   │       └── s_inventory_execution.gd
│   │   ├── physics_and_movement/
│   │   │   ├── components/             # c_transform.gd, c_velocity.gd, c_network_sync.gd
│   │   │   └── systems/                # s_server_physics.gd, s_client_interpolation.gd
│   │   ├── spawning_and_zones/
│   │   │   ├── components/             # c_spawn_point.gd, c_chunk_active.gd
│   │   │   └── systems/                # s_zone_sleep.gd, s_spawner.gd
│   └── default_systems.tscn            # Scene-based System Group execution order
│
├── shared_nodes/                       # The Body (Physics, Visuals & Hitboxes)
│   ├── entities/
│   │   ├── e_player.tscn               # Entity Root Node extending e_player.gd
│   │   └── bestiary/
│   │       └── e_crystal_arachnid.tscn # Godot Scene acting as a GECS Prefab
│   └── maps/
│       └── chunks/                     # Seamless world chunks
│
├── server/                             # Server-Only Logic
│   ├── database/
│   │   └── daos/                       # Data Access Objects
│   └── ServerMain.gd
│
└── client/                             # Client-Only Logic (Presentation)
    ├── observers/                      # GECS Observers bridging ECS to UI & VFX
    │   ├── o_inventory_ui.gd           # Listens for C_HasItem changes, updates UI
    │   ├── o_health_ui.gd              # Listens for C_Health changes, updates HUD
    │   ├── o_combat_vfx.gd
    │   └── o_animation_state.gd
    ├── ui/                             # UI Scenes & Scripts (The Reverse Hybrid Approach)
    │   ├── core/                       # Global UI Managers
    │   │   ├── ui_colors.gd            # Global color namespace registry (UIColors.Base.PURE_WHITE)
    │   │   ├── ui_window_manager.gd    # Handles Z-sorting, window dragging, focus
    │   │   ├── ui_event_bus.gd         # Routes UI clicks to the ECS Command Buffer
    │   │   └── ui_tooltip_manager.gd   # Global tooltip singleton
    │   │
    │   ├── themes/                     # Programmatic Styling (ThemeGen)
    │   │   ├── generators/             # @tool scripts that build the themes
    │   │   │   └── global_theme_gen.gd
    │   │   ├── generated/              # The resulting .tres files
    │   │   │   └── global_theme.tres
    │   │   └── assets/                 # UI-specific raw assets (Atlases, Fonts)
    │   │       ├── fonts/
    │   │       └── atlas/
    │   │           ├── ui_icons.png    # Single draw-call atlas for all UI icons
    │   │           └── ui_icons.tres   # AtlasTexture definitions
    │   │
    │   ├── components/                 # Atomic Design Hierarchy
    │   │   ├── atoms/                  # Base primitives (Pure GDScript wrappers)
│   │   │   │   ├── primary_action_button.gd # Handles its own hover/click audio & states
    │   │   │   ├── header_label.gd          # Enforces H1/H2 typography tokens
    │   │   │   ├── body_text_label.gd       # Enforces standard body typography tokens
    │   │   │   ├── window_panel_bg.gd       # Base 9-slice background for all windows
    │   │   │   ├── item_icon_rect.gd        # TextureRect enforcing standard atlas sizes
    │   │   │   ├── svg_icon.gd              # TextureRect wrapper strictly for scalable SVGs
    │   │   │   └── base_line_edit.gd        # Base text input field wrapper
    │   │   │
    │   │   ├── molecules/              # Composites of Atoms (Pure GDScript)
    │   │   │   ├── main_menu_button.gd      # header_label + 2x svg_icon with hover logic
    │   │   │   ├── pill_button.gd           # StyleBox panel + svg_icon + body_text_label
    │   │   │   ├── labeled_input_field.gd   # body_text_label + base_line_edit
    │   │   │   ├── loot_slot.gd             # item_icon_rect + body_text_label (Qty)
    │   │   │   ├── stat_block.gd            # header_label + body_text_label
    │   │   │   └── drag_titlebar.gd         # window_panel_bg + header_label + close button
    │   │   │
    │   │   └── organisms/              # Complex, reusable UI modules (Godot Scenes)
    │   │       ├── main_menu_cluster.tscn   # VBox container for main_menu_button.gd instances
    │   │       ├── login_credentials_form.tscn # Container for labeled_input_field.gd instances
    │   │       ├── inventory_grid.tscn      # Grid container for loot_slot.gd instances
    │   │       ├── action_bar.tscn          # Scene handling layout of hotkey bindings
    │   │       └── unit_frame.tscn          # Arranges Player/Target health and mana bars
    │   │
    │   └── screens/                    # Top-level window containers (Godot Scenes)
    │       ├── hud/                    # Static, non-closable UI
    │       │   ├── main_hud.tscn
    │       │   └── chat_box.tscn
    │       │
    │       ├── windows/                # Draggable, overlapping panels
    │       │   ├── inventory_window.tscn
    │       │   ├── character_sheet.tscn
    │       │   └── bank_window.tscn
    │       │
    │       └── menus/                  # Full-screen blocking UI
    │           ├── login_screen.tscn   # Root canvas composing the menu organisms
    │           ├── login_screen.gd     # State machine switching the organisms
    │           └── game_menu.tscn
    │
    ├── renderers/                      # ECS-to-Visual interpolation systems
    ├── assets/                         # Heavy asset storage
    └── ClientMain.gd
```

## 2\. Entity Composition: GECS Scene Prefabs & Mass Spawning

GECS leans into Godot's greatest strength: the `.tscn` file. Game Designers assemble enemies natively in the Editor, attaching components in the Inspector.

However, calling `.instantiate()` on a scene with 3D meshes and audio players 10,000 times will freeze a dedicated server. We solve this using a **Headless Prefab Cache**.

### 2.1 The Headless Prefab Cache

When the server boots, it strips the visuals from the `.tscn` exactly _once_, repacks it into active RAM, and caches it.

```gdscript
# res://server/utils/ServerPrefabCache.gd (Autoload on Server)
class_name ServerPrefabCache extends Node

var headless_prefabs: Dictionary = {}

func get_headless_prefab(original_scene: PackedScene) -> PackedScene:
    var scene_path = original_scene.resource_path

    if headless_prefabs.has(scene_path):
        return headless_prefabs[scene_path]

    var temp_instance = original_scene.instantiate()
    _strip_visuals(temp_instance)

    var headless_scene = PackedScene.new()
    headless_scene.pack(temp_instance)

    headless_prefabs[scene_path] = headless_scene
    temp_instance.queue_free()

    return headless_scene

func _strip_visuals(node: Node):
    for child in node.get_children():
        if child is VisualInstance3D or child is AudioStreamPlayer3D or child is GPUParticles3D:
            child.queue_free()
        else:
            _strip_visuals(child)
```

### 2.2 The Real-World Spawning Ecosystem

Servers do not spawn monsters globally. They use **Spawn Points** governed by **Zone Proximity**. If no players are in the "Ice Cave" chunk, the spawn points sleep.

```gdscript
# c_spawn_point.gd
class_name C_SpawnPoint extends Component
@export var prefab: PackedScene
@export var max_active: int = 5
@export var current_active: int = 0
@export var respawn_delay: float = 30.0
@export var timer: float = 0.0

# c_spawned_by.gd (Relationship marker)
class_name C_SpawnedBy extends Component
```

```gdscript
# res://core/features/spawning_and_zones/systems/s_spawner.gd
class_name SpawnerSystem extends System

func query():
    # Only process spawn points that are inside an ACTIVE chunk
    return q.with_all([C_SpawnPoint, C_Transform, C_ChunkActive])

func process(entities: Array[Entity], components: Array, delta: float):
    for entity in entities:
        var spawner = entity.get_component(C_SpawnPoint) as C_SpawnPoint

        if spawner.current_active < spawner.max_active:
            spawner.timer -= delta

            if spawner.timer <= 0.0:
                # 1. Get the RAM-cached headless prefab
                var prefab = ServerPrefabCache.get_headless_prefab(spawner.prefab)
                var monster = prefab.instantiate() as Entity

                var pos = (entity.get_component(C_Transform) as C_Transform).transform.origin
                monster.global_position = pos + _get_random_offset()

                # 2. Add Relationship: Tell the monster who spawned it
                monster.add_relationship(Relationship.new(C_SpawnedBy.new(), entity))

                get_tree().current_scene.add_child(monster)
                ECS.world.add_entity(monster)

                spawner.current_active += 1
                spawner.timer = spawner.respawn_delay
```

_Note: When the `DeathSystem` kills a monster, it queries for `C_SpawnedBy`, finds the parent Spawner, and decrements `current_active` so the timer restarts._

## 3\. Advanced Multi-Inventory (Banks & Relationships)

Inventories aren't fixed arrays; they are GECS Relationships. This allows infinite scaling for items, bags, banks, and guild stashes.

### 3.1 Adding Stacked Items

The quantity of an item lives inside the relationship component itself.

```gdscript
# c_has_item.gd
class_name C_HasItem extends Component
@export var quantity: int = 1
func _init(qty: int = 1): quantity = qty

# Usage: Adding 5 Health Potions to a bag
func give_potions(bag_entity: Entity):
    var item_type = C_HealthPotion.new() # The target type
    var relation = C_HasItem.new(5)      # The relation data (quantity)

    bag_entity.add_relationship(Relationship.new(relation, item_type))
```

### 3.2 Bank Access Validator (Spatial Querying)

A Bank is an inventory that requires physical proximity to an NPC. We enforce this in the Validator Pipeline using standard spatial distance checks.

```gdscript
# res://core/features/inventory/systems/validators/s_bank_access_validator.gd
class_name BankAccessValidator extends System

func query():
    # Find anyone trying to open an inventory, not already blocked
    return q.with_all([C_InventoryOpenRequest, C_Transform]).with_none([C_ActionBlocked])

func process(entities: Array[Entity], components: Array, delta: float):
    # Get all Bank NPCs in the world
    var bank_npcs = ECS.world.query.with_all([C_BankNPC, C_Transform]).execute()

    for entity in entities:
        var request = entity.get_component(C_InventoryOpenRequest) as C_InventoryOpenRequest

        if request.target_inventory_entity.has_component(C_BankTag):
            var player_pos = (entity.get_component(C_Transform) as C_Transform).transform.origin
            var is_near_bank = false

            for npc in bank_npcs:
                var npc_pos = (npc.get_component(C_Transform) as C_Transform).transform.origin
                if player_pos.distance_to(npc_pos) <= 5.0: # 5 meters
                    is_near_bank = true
                    break

            if not is_near_bank:
                # VETO! Safely block the action using command buffer
                var err = InventoryErrors.pack(InventoryErrors.TOO_FAR_FROM_BANK)
                cmd.add_component(entity, C_ActionBlocked.new(err))
```

## 4\. Physics, Prediction, and Interpolation

In an MMO, the server runs the physics, but the client must predict movement so the game doesn't feel laggy.

### 4.1 Server Authoritative Physics

The Server runs Godot's `CharacterBody3D.move_and_slide()` and syncs the resulting transform to the ECS component.

```gdscript
# res://core/features/physics/systems/s_server_physics.gd
class_name ServerPhysicsSystem extends System

func query():
    return q.with_all([C_Transform, C_Velocity]).with_none([C_Stunned])

func process(entities: Array[Entity], components: Array, delta: float):
    # ONLY the dedicated server runs actual collision physics
    if not OS.has_feature("dedicated_server"): return

    for entity in entities:
        var vel = entity.get_component(C_Velocity) as C_Velocity

        # Assume Entity extends CharacterBody3D
        entity.velocity = vel.direction * vel.speed
        entity.move_and_slide()

        # Sync the Godot Node position back to the ECS Component for networking
        var c_trans = entity.get_component(C_Transform) as C_Transform
        c_trans.transform = entity.global_transform
```

### 4.2 Client Interpolation & Prediction

The Client receives `C_NetworkSync` updates from the server. It smoothly interpolates other players, but strictly overrides its own local prediction if the server disagrees.

```gdscript
# res://core/features/physics/systems/s_client_interpolation.gd
class_name ClientInterpolationSystem extends System

func query():
    return q.with_all([C_Transform, C_NetworkSync])

func process(entities: Array[Entity], components: Array, delta: float):
    if OS.has_feature("dedicated_server"): return # Clients only

    for entity in entities:
        var target_pos = (entity.get_component(C_NetworkSync) as C_NetworkSync).server_transform.origin

        if entity.has_component(C_LocalPlayer):
            # Local Player: Check if our prediction was wrong (Rubberbanding)
            if entity.global_transform.origin.distance_to(target_pos) > 2.0:
                entity.global_transform.origin = target_pos # Snap back
        else:
            # Other Entities: Smoothly interpolate visually
            entity.global_transform.origin = entity.global_transform.origin.lerp(target_pos, delta * 15.0)
```

## 5\. Client Presentation: VFX and Animations (Observers)

**Systems calculate math; Observers play visuals.** If a fire spell hits an enemy, `DamageSystem` does the math. An `Observer` sees the `C_DamageEvent` component appear and triggers the particles and hit animation.

### 5.1 Combat VFX Observer

```gdscript
# res://client/observers/o_combat_vfx.gd
class_name CombatVFXObserver extends Observer

# 1. We watch for Damage Events
func watch() -> Resource:
    return C_DamageEvent

func on_component_added(entity: Entity, component: Resource):
    var dmg_event = component as C_DamageEvent

    # 2. Defer Godot Node instantiation to avoid locking the ECS loop
    call_deferred("_play_hit_vfx", entity, dmg_event.damage_type)

func _play_hit_vfx(entity: Entity, type: String):
    var vfx_scene = preload("res://client/assets/vfx/hit_blood.tscn")
    if type == "FIRE": vfx_scene = preload("res://client/assets/vfx/hit_fire.tscn")

    var vfx = vfx_scene.instantiate()
    get_tree().current_scene.add_child(vfx)
    vfx.global_position = entity.global_position
```

### 5.2 Animation State Observer

We link Godot's `AnimationTree` directly to ECS state changes.

```gdscript
# res://client/observers/o_animation_state.gd
class_name AnimationStateObserver extends Observer

func watch() -> Resource:
    return C_State  # E.g., IDLE, RUNNING, ATTACKING, DEAD

func on_component_changed(entity: Entity, component: Resource, property: String, new_val: Variant, old_val: Variant):
    if property == "current_state":
        var anim_tree = entity.get_node_or_null("AnimationTree") as AnimationTree
        if anim_tree:
            var state_machine = anim_tree.get("parameters/playback")
            state_machine.travel(new_val) # E.g., travels to "ATTACKING"
```

## 6\. Networking & Scene Loading (Chunking)

MMO servers cannot send the entire world's data to every client. They use **Spatial Chunking**.

1.  The world is divided into 100x100 meter grids (Chunks).
2.  The Server checks the Player's `C_Transform`.
3.  The Server serializes entities in the player's current chunk (and 8 surrounding chunks) and sends them.
4.  The Client loads these chunks asynchronously.

```gdscript
# res://core/network/handlers/ChunkLoadHandler.gd
class_name ChunkLoadHandler extends Node

# Called when the custom UDP network receives a chunk payload
static func apply_chunk_data(client_id: int, raw_bytes: PackedByteArray):
    # 1. Deserialize the GECS data using the native framework
    var temp_file = _bytes_to_temp_file(raw_bytes)
    var entities = ECS.deserialize(temp_file)

    # 2. Add them to the client's world safely
    for entity in entities:
        # Check if we already have it to avoid duplicates
        if not ECS.world.has_entity(entity.name):
            get_tree().current_scene.add_child(entity)
            ECS.world.add_entity(entity)
```

## 7\. Asset Management & Optimization

### 7.1 GLB Files and 3D Models

Do not store animations inside individual enemy `.glb` files. This duplicates data massively. Use Godot's retargeting to share a `humanoid_rig.glb` across multiple meshes.

### 7.2 Texture Reuse (VRAM Optimization)

-   **ORM Channel Packing:** Pack Ambient Occlusion (R), Roughness (G), and Metallic (B) maps into a single ORM texture to cut memory overhead by 66%.
-   **Texture Atlasing:** Map 100 weapons to **one** 4k texture atlas for a single GPU draw call.
-   **Shared Material Libraries:** Store common environments (e.g., `stone_wall.tres`) in `client/assets/textures/shared_materials/`.

### 7.3 UI Icons and 2D Textures

-   **Avoid separate `.png` files for every icon.** Use Sprite Sheets / Godot AtlasTextures. Pack all "Fire Skills" into a single `fire_skills_sheet.png`. Create `.tres` files of type `AtlasTexture` that slice out the specific 64x64 region.

## 8\. Client UI Architecture (The "Reverse Hybrid" Approach)

In a massive-scale MMO, building complex, overlapping UI menus using Godot's visual scene editor alone leads to severe merge conflicts, messy `.tscn` files, and inconsistent styling. Conversely, building complex layouts purely in code is highly tedious and ignores Godot's robust visual container system.

Therefore, the UI layer employs a **Reverse Hybrid Approach** based on the **Atomic Design methodology**. We write small primitives strictly in GDScript for ultimate version control and consistency, but compose them into massive layouts using `.tscn` files.

### 8.1 The "Dumb UI" Principle (State Separation)

The UI must **never** modify game state directly. It acts strictly as a presentation layer for GECS.

-   **Listening to State:** UI elements are updated exclusively by Observers. If the player drinks a potion, `o_inventory_ui.gd` observes the `C_HasItem` change and visually updates the inventory grid.
-   **Requesting Actions:** When a user interacts with the UI, components emit signals to a global `UIEventBus`. This bus translates clicks into intent, adding network packets or local Command Buffer requests to the ECS.

### 8.2 The File Format Split

Instead of utilizing raw Godot nodes (like `Button` or `Label`) scattered throughout the codebase, developers construct UI using a strict hierarchy of customized components separated by their file type:

-   **Atoms (Base Primitives) -> PURE GDSCRIPT (`.gd`)**: Godot Node wrappers with strictly enforced defaults. Since these handle no visual layout math, pure code prevents accidental editor overrides and enforces absolute design consistency.
    -   `primary_action_button.gd` (Handles internal hover/click audio, base styling).
    -   `item_icon_rect.gd` (Enforces standard 64x64 sizing and handles tooltip binding).
    -   `header_label.gd` (Enforces the H1/H2 font variations).
    -   `svg_icon.gd` (Enforces standard interpolation and sizing for SVGs).
-   **Molecules (Composites) -> PURE GDSCRIPT (`.gd`)**: Reusable groupings of Atoms. These are small enough that the GDScript boilerplate is manageable and ensures zero merge conflicts on highly reused blocks.
    -   `main_menu_button.gd`: Encapsulates hover tweens and dynamically creates decor SVGs.
    -   `pill_button.gd`: Hardcodes strict Figma border-radii via `StyleBoxFlat`.
-   **Organisms & Screens -> GODOT SCENES (`.tscn`)**: Complex functional modules and full window containers. We use Godot's visual `.tscn` files here because creating highly nested `MarginContainers`, `VBoxContainers`, and `ScrollContainers` purely in code is an exercise in misery. **Crucially, these scenes are treated as dumb layout containers**.

### 8.3 Programmatic Theming (ThemeGen)

Setting visual styles purely through GDScript at runtime (e.g., `button.add_theme_stylebox_override()`) is incredibly slow and memory intensive. Instead, the architecture utilizes `@tool` scripts to generate Godot `.tres` Theme files ahead of time.

Using Godot's **Theme Type Variations**, a master `global_theme.tres` defines standard properties, and variations handle specifics:

```gdscript
# pseudo-code within themes/generators/global_theme_gen.gd
define_style("Button", default_button_style)

# Derive MMO-specific variations from the base Button
define_variation("PrimaryActionButton", "Button", {
    panel = ornate_gold_stylebox,
    font_color = Color.WHITE
})

define_variation("DungeonButton", "Button", {
    panel = dark_stone_stylebox,
    font_color = Color.RED
})
```

When building UI elements programmatically, components merely assign the variation:

```gdscript
# Inside primary_action_button.gd
func _init(): self.theme_type_variation = "PrimaryActionButton"
```

This guarantees an extremely lightweight memory footprint (one theme loaded globally) while preserving the code-centric development experience.

## 9\. Real-World Implementation: The Login Screen

To illustrate the Reverse Hybrid approach in full, here is a complete breakdown of the Login Screen flow. This demonstrates global color management, programmatic atomic styling, and visual layout composition.

### 9.1 The Global Color Registry

Colors are never hardcoded as strings inside components. Instead, we use a global `UIColors` registry. Nested classes act as namespaces, providing rich IDE autocomplete without clutter.

```gdscript
## res://client/ui/core/ui_colors.gd
class_name UIColors extends RefCounted

class Base:
    const CREAMY_WHITE = Color("#F9F3E5")
    const CHIP_BLUE = Color("#558EDD")
    const SOFT_WHITE = Color("#F5F5F5")
    const DEFAULT_TEXT = Color("#07263D")
```

### 9.2 The Atoms (Pure GDScript Primitives)

We wrap raw Godot nodes in our own classes to enforce ThemeGen properties, preventing artists from accidentally modifying font sizes in the `.tscn` inspector.

**1\. The Typography Atoms:**

```gdscript
## res://client/ui/components/atoms/header_label.gd
class_name HeaderLabel extends Label

func _init() -> void:
    theme_type_variation = "HeaderLabel" # Generated via ThemeGen
    add_theme_color_override("font_color", UIColors.Base.CREAMY_WHITE)

## res://client/ui/components/atoms/body_text_label.gd
class_name BodyTextLabel extends Label

func _init() -> void:
    theme_type_variation = "BodyTextLabel"
    add_theme_color_override("font_color", UIColors.Base.SOFT_WHITE)
```

**2\. The Texture Atoms:**

```gdscript
## res://client/ui/components/atoms/svg_icon.gd
class_name SVGIcon extends TextureRect

## Enforces perfect SVG rendering without blurring
func _init() -> void:
    expand_mode = TextureRect.EXPAND_FIT_WIDTH
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
```

**3\. The Input Atoms:**

```gdscript
## res://client/ui/components/atoms/base_line_edit.gd
class_name BaseLineEdit extends LineEdit

func _init() -> void:
    theme_type_variation = "BaseLineEdit"
    add_theme_color_override("font_color", UIColors.Base.DEFAULT_TEXT)
```

### 9.3 The Molecules (Pure GDScript Composites)

Molecules combine our custom Atoms. Because they are written in code, complex logic (like the SVG hover pop-in) is perfectly encapsulated.

**1\. The Main Menu Button:**

```gdscript
## res://client/ui/components/molecules/main_menu_button.gd
class_name MainMenuButton extends MarginContainer
signal clicked

@export var button_text: String = "Play"
@export var decoration_texture: Texture2D

var left_decor: SVGIcon   # Using our Atom
var right_decor: SVGIcon  # Using our Atom
var label: HeaderLabel    # Using our Atom

func _ready() -> void:
    var hbox = HBoxContainer.new()
    add_child(hbox)

    # 1. Left Decor Atom
    left_decor = SVGIcon.new()
    left_decor.texture = decoration_texture
    left_decor.modulate.a = 0.0 # Hidden initially
    hbox.add_child(left_decor)

    # 2. Header Label Atom
    label = HeaderLabel.new()
    label.text = button_text
    hbox.add_child(label)

    # ... right decor setup & hover signals ...

func _on_hover() -> void:
    label.add_theme_color_override("font_color", UIColors.Base.PURE_WHITE)
    # Tween the SVGIcon atoms in
    var t = create_tween().set_parallel(true)
    t.tween_property(left_decor, "modulate:a", 1.0, 0.15)
```

**2\. The Form Input Field:**

```gdscript
## res://client/ui/components/molecules/labeled_input_field.gd
class_name LabeledInputField extends VBoxContainer

@export var label_text: String = "Username"
var input: BaseLineEdit

func _ready() -> void:
    var title = BodyTextLabel.new() # Atom
    title.text = label_text
    add_child(title)

    input = BaseLineEdit.new() # Atom
    add_child(input)
```

### 9.4 The Organisms (Visual .tscn Containers)

Instead of placing 50 buttons directly into `login_screen.tscn`, we group our molecules into `.tscn` organisms. This allows designers to visually build the form layouts, keeping the root screen clean.

-   `main_menu_cluster.tscn`: A `VBoxContainer` holding `MainMenuButton` instances (Play, Play Solo, Settings).
-   `login_credentials_form.tscn`: A `VBoxContainer` holding `LabeledInputField` instances (Username, Password) and a `MainMenuButton` (Login).

### 9.5 The Screen & State Machine (login\_screen.gd)

The root screen acts merely as a visual canvas mapping out the Organisms, and its script acts as a State Machine.

**The Editor Node Tree (`login_screen.tscn`):**

```
LoginScreen (Control - Full Rect)
├── ScreenContainer (MarginContainer - Full Rect)
│   ├── TopSection (MarginContainer - Top 48px)
│   │   └── Logo (SVGIcon - MinSize 312x312)                <-- ATOM
│   ├── BottomSection (Control - Bottom Wide)
│   │   ├── VersionLabel (BodyTextLabel - Bottom Left)      <-- ATOM
│   │   └── ReleaseNotesBtn (PillButton - Bottom Right)     <-- MOLECULE
│   └── FlowStates (CenterContainer - Full Rect)
│       ├── MainMenuCluster (main_menu_cluster.tscn)        <-- ORGANISM
│       └── LoginFormCluster (login_credentials_form.tscn)  <-- ORGANISM (Hidden)
```

**The State Machine Controller:**

```gdscript
## res://client/ui/screens/menus/login_screen.gd
class_name LoginScreen extends Control

enum State { MAIN_MENU, LOGIN_FORM }
var current_state: State = State.MAIN_MENU

@onready var main_menu_cluster = $ScreenContainer/FlowStates/MainMenuCluster
@onready var login_form_cluster = $ScreenContainer/FlowStates/LoginFormCluster

func _ready() -> void:
    # Setup Version Label using our Atom (Font styles are strictly enforced!)
    var version_lbl = $ScreenContainer/BottomSection/VersionLabel
    version_lbl.add_theme_color_override("font_color", Color(UIColors.Base.DEFAULT_TEXT, 0.5))
    version_lbl.text = "v" + ProjectSettings.get_setting("application/config/version", "1.1.0")

    # Connect signals from the Organism down to the controller
    main_menu_cluster.get_node("BtnPlay").clicked.connect(_switch_to_login)

func _switch_to_login() -> void:
    current_state = State.LOGIN_FORM
    _fade_out(main_menu_cluster)
    _fade_in(login_form_cluster)

func _fade_out(node: Control) -> void:
    var t = create_tween()
    t.tween_property(node, "modulate:a", 0.0, 0.2)
    t.tween_callback(node.hide)

func _fade_in(node: Control) -> void:
    node.show()
    var t = create_tween()
    t.tween_property(node, "modulate:a", 1.0, 0.2)
```
