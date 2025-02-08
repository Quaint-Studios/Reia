use godot::prelude::*;

struct ReiaExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ReiaExtension {}

mod auth;
mod db;
mod game;
mod network;

// Re-exports for easier access
pub use auth::supabase;
pub use db::{turso, steam, analytics};
