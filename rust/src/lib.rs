use godot::prelude::*;

pub mod db;
pub mod ffi;
pub mod math;
pub mod net;
pub mod state;

struct ReiaExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ReiaExtension {}
