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

### /rust
Rust integration with Godot using gdext.

```
/rust
├── /src
│   ├── lib.rs      # Main library file
│   ├── /auth       # Authentication system
│   │   └── /supabase    # Supabase authentication implementation
│   ├── /db         # Database implementations
│   │   ├── /turso       # Turso database integration
│   │   ├── /steam       # Steam integration
│   │   └── /analytics   # Analytics system
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

## Backend Architecture

### Authentication (Supabase)
- User authentication and authorization
- Session management
- User profiles and roles
- OAuth integrations

### Database (Turso)
- Primary game data storage
- Structured SQL database for:
  - Player data
  - Game state
  - Inventory
  - Quests
  - Achievements
  - Settings

### Additional Integrations
- Steam integration for platform-specific features
- Analytics for game metrics and player behavior
- Future database integrations can be added under /db

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

### Database Practices
- Use prepared statements for all SQL queries
- Implement proper error handling and retries
- Cache frequently accessed data
- Use transactions for related operations
- Implement proper migration strategies
