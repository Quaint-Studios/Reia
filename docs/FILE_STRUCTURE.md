```.
├── godot/
│   ├── addons/
│   │   ├── game_manager/ # This is an in-house addon that handles a wide-range of tasks for us.
│   │   └── ...
│   ├── common/ # These are files that are frequently reused in multiple places.
│   │   ├── components/
│   │   ├── shaders/
│   │   └── drop_shadow.gdshader
│   ├── models/ # Characters, enemies, props, environment, skills, just the .glb file goes here.
│   │   ├── characters/
│   │   │   └── player/
│   │   └── enemies/
│   ├── rsc/ # Shader files go here and they can be utilized in the src folder.
│   │   ├── audio/
│   │   │   ├── bg/
│   │   │   ├── interface/
│   │   │   ├── title/ # Specific to the main menu screen.
│   │   │   └── audio_bus.tres # The bus layout that contains the Master, Music, SFX, Interface, and Dialogue busses.
│   │   ├── fonts/
│   │   │   ├── poppins-latin-400-normal.ttf # This is the format for all fonts now.
│   │   ├── icons/ # Holds SVG files mostly but some png icons are included.
│   │   ├── logos/ # Holds the logos for the app. Most have been converted to SVGs. Also holds the splash screen.
│   │   ├── skyboxes/
│   │   └── themes/ # There really should only need to be one theme for now but in the future this may grow. This also contains the theme_gen script and colors.
│   ├── scenes/ # Maps for each regions, global managers, and dungeons go here. Each map should have their own folder if they have scripts tied to them.
│   │   ├── main/
│   │   │   ├── managers/
│   │   │   ├── scene_selector/
|   │   │   │   ├── scene_selector.gd
│   │   │   │   └── scene_selector.tscn
│   │   │   ├── title_screen/
|   │   │   │   ├── components/
|   │   │   │   │   ├── menu_button.gd
│   │   │   │   │   └── menu_button.tscn
|   │   │   │   ├── title_screen.gd
│   │   │   │   └── title_screen.tscn
│   │   ├── regions/
│   │   │   ├── jadewater_falls/
│   │   │   ├── waterbrook_city/
│   └── src/
│   │   ├── mob/ # Movable objects like players, npcs, enemies, sentries, etc. Anything that requires momentum.
│   │   │   └── attackable/ # All Attackable objects.
│   │   │   │   ├── player/
│   │   │   │   │   ├── abilities/ # TODO: May need some restructuring before active development.
│   │   │   │   │   │   ├── offense/
│   │   │   │   │   │   │   └── electro/
│   │   │   │   │   │   │       └── ...
│   │   │   │   │   │   ├── defense/
│   │   │   │   │   │   ├── movement/
│   │   │   │   │   │   │   ├── dash.gd
│   │   │   │   │   │   │   ├── double_jump.gd
│   │   │   │   │   │   │   └── teleport.gd
│   │   │   │   │   │   └── abilities.gd
│   │   │   │   │   ├── components/
│   │   │   │   │   │   ├── player_camera_tps.gd
│   │   │   │   │   │   └── player_inventory.gd
│   │   │   │   │   └── minimap_markers/ # Used for the minimap. It goes under the player and appears on the minimap in place of the player's model
│   │   │   │   │       └── map_marker.tscn
│   │   │   │   ├── enemy/
│   │   │   │   └── attackable.gd
│   │   ├── ui/ # UI components go here and they're used in scenes.
│   │   │   └── changelogs/
│   │   │       └── ...
│   │   └── networking/
├── rust/
│   ├── db/
│   ├── networking/
└── zig/
│   └── generation/
```
