# Reia Project Structure

## Overview
This document outlines the organization of the Reia project codebase.

## Directory Structure

### /godot
Main Godot project directory containing all game-related files.

```
/godot
├── /addons         # Godot plugins and extensions
├── /scenes         # Game scenes
│   ├── /ui         # UI scenes (menus, HUD, etc.)
│   ├── /levels     # Game levels and maps
│   ├── /characters # Character scenes
│   ├── /cutscenes  # Cutscene sequences
│   └── /menus      # Menu scenes
├── /src            # GDScript source files
│   ├── /ai         # AI and behavior systems
│   ├── /combat     # Combat-related scripts
│   ├── /dialogue   # Dialogue system
│   ├── /globals    # Global scripts and autoload
│   ├── /inventory  # Inventory system
│   ├── /item       # Item definitions
│   ├── /mob        # NPC and enemy scripts
│   ├── /networking # Multiplayer and network code
│   ├── /player     # Player-related systems
│   ├── /quests     # Quest system
│   ├── /utils      # Utility functions
│   └── /world      # World management and generation
└── /rsc            # Resources
    ├── /interface  # UI elements and interfaces
    ├── /sprites    # 2D sprites and textures
    │   ├── /characters  # Character sprites
    │   ├── /items       # Item sprites
    │   └── /effects     # Effect sprites
    ├── /environment # Environment assets
    │   ├── /textures    # Environment textures
    │   ├── /props       # Props and decorations
    │   └── /materials   # Material definitions
    ├── /characters # Character models and animations
    │   ├── /models      # Character 3D models
    │   ├── /animations  # Animation files
    │   └── /rigs        # Character rigs
    ├── /ui         # UI assets and themes
    │   ├── /icons       # UI icons
    │   ├── /themes      # UI themes
    │   └── /elements    # Reusable UI elements
    ├── /effects    # Visual effects
    │   ├── /particles   # Particle effects
    │   ├── /shaders     # Effect shaders
    │   └── /animations  # Effect animations
    ├── /audio      # Sound effects and music
    │   ├── /music       # Background music
    │   ├── /sfx         # Sound effects
    │   └── /ambient     # Ambient sounds
    ├── /fonts      # Font files
    └── /shaders    # Shader files
```

### /rust_gdext
Rust integration with Godot using gdext.

```
/rust_gdext
├── /src
│   ├── lib.rs      # Main library file
│   ├── /db         # Database implementations
│   │   ├── /models      # Database models
│   │   ├── /mongodb     # MongoDB implementation
│   │   └── /polodb      # PoloDB implementation
│   ├── /game       # Game logic
│   │   ├── /state       # Game state management
│   │   ├── /systems     # Game systems
│   │   └── /events      # Event handling
│   └── /network    # Networking code
│       ├── /protocols   # Network protocols
│       ├── /sync        # State synchronization
│       └── /security    # Network security
└── Cargo.toml      # Rust dependencies and configuration
```

## Database Structure

### Online Mode (MongoDB)
- Used for MMO gameplay
- Handles player data, world state, and economy
- Collections:
  - players
  - characters
  - inventory
  - world_state
  - market
  - guilds
  - quests
  - chat_logs

### Offline Mode (PoloDB)
- Used for single-player and self-hosted gameplay
- Local data storage
- Maintains game state without network dependency
- Tables:
  - player_data
  - game_state
  - inventory
  - quests
  - achievements
  - settings

## Best Practices

### File Naming Conventions
- Use snake_case for GDScript files and directories
- Use PascalCase for scene files (.tscn)
- Use snake_case for resource files
- Prefix interface files with "I" (e.g., IInteractable)
- Suffix manager/controller files with "Manager" or "Controller"

### Scene Organization
- Each major game feature should have its own scene
- Break down complex scenes into smaller, reusable scenes
- Use scene inheritance when appropriate
- Keep UI scenes separate from gameplay scenes

### Resource Management
- Use resource preloading for frequently accessed assets
- Organize resources by type and feature
- Use consistent naming patterns for all resources
- Keep resource paths relative when possible

### Code Organization
- One script per node when possible
- Use autoload sparingly and only for truly global functionality
- Keep scripts focused and single-purpose
- Implement interfaces for common behaviors
- Use signals for loose coupling between systems
