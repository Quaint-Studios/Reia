use extras::godot_tokio::AsyncRuntime;
use godot::{ classes::Engine, prelude::* };

mod db;
mod extras;
mod network;

struct Reia;

#[gdextension]
unsafe impl ExtensionLibrary for Reia {
    fn on_level_init(level: InitLevel) {
        match level {
            InitLevel::Scene => {
                let mut engine = Engine::singleton();

                // This is where we register our async runtime singleton.
                engine.register_singleton(AsyncRuntime::SINGLETON, &AsyncRuntime::new_alloc());
            }
            _ => (),
        }
    }

    fn on_level_deinit(level: InitLevel) {
        match level {
            InitLevel::Scene => {
                let mut engine = Engine::singleton();

                // Here is where we free our async runtime singleton from memory.
                if let Some(async_singleton) = engine.get_singleton(AsyncRuntime::SINGLETON) {
                    engine.unregister_singleton(AsyncRuntime::SINGLETON);
                    async_singleton.free();
                } else {
                    godot_warn!("Failed to find & free singleton -> {}", AsyncRuntime::SINGLETON);
                }
            }
            _ => (),
        }
    }
}
