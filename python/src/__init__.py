"""
Reia - Python 3.14 Game Engine Extension
Converted from Rust to Python
"""

from godot import Engine, exposed, export
from .extras.godot_asyncio import AsyncRuntime

# Module imports
from . import db
from . import extras
from . import network


class Reia:
    """Main Reia extension class for Godot integration"""

    @staticmethod
    def on_level_init(level: str) -> None:
        """Initialize extension at various engine levels"""
        if level == "scene":
            engine = Engine.get_singleton()

            # Register async runtime singleton
            engine.register_singleton(
                AsyncRuntime.SINGLETON,
                AsyncRuntime.new()
            )

    @staticmethod
    def on_level_deinit(level: str) -> None:
        """Deinitialize extension at various engine levels"""
        if level == "scene":
            engine = Engine.get_singleton()

            # Free async runtime singleton from memory
            async_singleton = engine.get_singleton(AsyncRuntime.SINGLETON)
            if async_singleton is not None:
                engine.unregister_singleton(AsyncRuntime.SINGLETON)
                async_singleton.free()
            else:
                print(f"WARNING: Failed to find & free singleton -> {AsyncRuntime.SINGLETON}")


def initialize_extension():
    """Entry point for Godot extension initialization"""
    Reia.on_level_init("scene")


def deinitialize_extension():
    """Entry point for Godot extension deinitialization"""
    Reia.on_level_deinit("scene")
