// MIT License
//
// Copyright (c) 2025 2-3-5-41
// https://github.com/2-3-5-41/godot_tokio/blob/master/src/lib.rs

use std::{ future::Future, rc::Rc };

use godot::{ classes::Engine, prelude::* };
use tokio::{ runtime::{ self, Runtime }, task::JoinHandle };

#[derive(GodotClass)]
#[class(base = Object)]
pub struct AsyncRuntime {
    base: Base<Object>,
    runtime: Rc<Runtime>,
}

#[godot_api]
impl IObject for AsyncRuntime {
    fn init(base: Base<Object>) -> Self {
        let runtime = runtime::Builder::new_multi_thread().enable_all().build().unwrap();

        Self {
            base,
            runtime: Rc::new(runtime),
        }
    }
}

#[godot_api]
impl AsyncRuntime {
    pub const SINGLETON: &'static str = "Tokio";

    /// This function has no real use for the user, only to make it easier
    /// for this crate to access the singleton object.
    fn singleton() -> Option<Gd<AsyncRuntime>> {
        match Engine::singleton().get_singleton(Self::SINGLETON) {
            Some(singleton) => Some(singleton.cast::<Self>()),
            None => None,
        }
    }

    /// **Can Panic**
    ///
    /// Gets the active runtime under the [`AsyncRuntime`] singleton. This can panic if the singleton is unreachable,
    /// or has no ability to be registered by the engine.
    pub fn runtime() -> Rc<Runtime> {
        match Self::singleton() {
            Some(singleton) => {
                let bind = singleton.bind();
                Rc::clone(&bind.runtime)
            }
            None => {
                // Assuming the user forgot to register the singleton, let's do it for them as a fail safe.
                Engine::singleton().register_singleton(
                    AsyncRuntime::SINGLETON,
                    &AsyncRuntime::new_alloc()
                );

                // We can panic here because something fundementally wrong has happend.
                let singleton = Self::singleton().expect(
                    "Engine was not able to register, or get `AsyncRuntime` singleton!"
                );

                let bind = singleton.bind();
                Rc::clone(&bind.runtime)
            }
        }
    }

    /// A wrapper function for the [`tokio::spawn`] function.
    pub fn spawn<F>(future: F) -> tokio::task::JoinHandle<F::Output>
        where F: Future + Send + 'static, F::Output: Send + 'static
    {
        Self::runtime().spawn(future)
    }

    /// A wrapper function for the [`tokio::block_on`] function.
    pub fn block_on<F>(future: F) -> F::Output where F: Future {
        Self::runtime().block_on(future)
    }

    /// A wrapper function for the [`tokio::spawn_blocking`] function.
    pub fn spawn_blocking<F, R>(&self, func: F) -> JoinHandle<R>
        where F: FnOnce() -> R + Send + 'static, R: Send + 'static
    {
        Self::runtime().spawn_blocking(func)
    }
}
