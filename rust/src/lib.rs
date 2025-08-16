use godot::prelude::*;

use bevy::prelude::*;
use godot_bevy::prelude::*;

mod game;
mod network;

#[bevy_app]
pub fn register_bevy(app: &mut App) {
    app.add_plugins(GodotDefaultPlugins);

    game::register(app);
    network::register(app);
}
