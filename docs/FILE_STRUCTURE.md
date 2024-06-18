```.
├── godot/
│   ├── addons/
│   │   ├── game_manager/ # This is an in-house addon that handles a wide-range of tasks for us
│   │   └── ...
│   ├── models/ # Characters, enemies, props, environment, skills, just the .glb file goes here.
│   │   ├── characters/
│   │   │   └── player/
│   │   └── enemies/
│   ├── shaders/ # Shader files go here and they can be utilized in the src folder.
│   │   ├── screen_space/
│   │   └── water/
│   └── src/
│       ├── managers/
│       ├── mob/ # Movable Objects like players, npcs, enemies, sentries, etc. Anything that requires momentum.
│       │   └── attackable/ # All Attackable Objects
│       │       ├── player/
│       │       │   ├── abilities/
│       │       │   │   ├── offense/
│       │       │   │   │   └── electro/
│       │       │   │   │       └── ...
│       │       │   │   ├── defense/
│       │       │   │   ├── movement/
│       │       │   │   │   ├── dash.gd
│       │       │   │   │   ├── double_jump.gd
│       │       │   │   │   └── teleport.gd
│       │       │   │   └── abilities.gd
│       │       │   ├── components/
│       │       │   │   ├── player_camera_tps.gd
│       │       │   │   └── player_inventory.gd
│       │       │   └── minimap_markers/ # Used for the minimap. It goes under the player and appears on the minimap in place of the player's model
│       │       │       └── map_marker.tscn
│       │       ├── enemy/
│       │       └── attackable.gd
│       ├── ui/ # UI components go here and they're used in scenes.
│       │   └── changelogs/
│       │       └── ...
│       └── scenes/ # Maps for each regions, global managers, and dungeons go here. Each map should have their own folder if they have scripts tied to them.
│           ├── maps/
│           ├── managers/
│           └── infinite_city/
└── zig/
    ├── db/
    ├── networking/
    └── generation/
```
