use godot::prelude::*;

use bevy::prelude::*;
use godot_bevy::prelude::*;

mod sustenet;

#[bevy_app]
fn build_app(app: &mut App) {
    app.add_systems(Startup, hello_world);
}

fn hello_world() {
    godot::prelude::godot_print!("Hello from godot-bevy!");
}
