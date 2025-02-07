use godot::prelude::*;

struct ReiaExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ReiaExtension {}

mod db;
mod game;
mod network;
