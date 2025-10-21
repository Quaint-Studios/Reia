"""
MIT License

Copyright (c) 2025 2-3-5-41
Converted from Rust to Python 3.14
Original: https://github.com/2-3-5-41/godot_tokio/blob/master/src/lib.rs

AsyncIO integration for Godot Engine using Python
"""

import asyncio
import threading
from typing import Optional, Callable, TypeVar, Coroutine, Any
from concurrent.futures import Future, ThreadPoolExecutor

try:
    from godot import Object, exposed, Engine
except ImportError:
    # Fallback for development without Godot
    class Object:
        pass

    def exposed(cls):
        return cls

    class Engine:
        @staticmethod
        def get_singleton():
            return None


T = TypeVar('T')


@exposed
class AsyncRuntime(Object):
    """
    AsyncRuntime provides integration between Godot's synchronous execution
    and Python's asyncio asynchronous execution model.

    This is the Python equivalent of the Rust Tokio runtime integration.
    """

    SINGLETON: str = "AsyncIO"

    _instance: Optional['AsyncRuntime'] = None
    _loop: Optional[asyncio.AbstractEventLoop] = None
    _thread: Optional[threading.Thread] = None
    _executor: Optional[ThreadPoolExecutor] = None

    def __init__(self):
        """Initialize the AsyncRuntime with a new event loop"""
        super().__init__()

        # Create a new event loop for this runtime
        self._loop = asyncio.new_event_loop()
        self._executor = ThreadPoolExecutor(max_workers=4)

        # Start the event loop in a separate thread
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()

    def _run_loop(self) -> None:
        """Run the event loop in a separate thread"""
        asyncio.set_event_loop(self._loop)
        self._loop.run_forever()

    @classmethod
    def new(cls) -> 'AsyncRuntime':
        """Create a new AsyncRuntime instance"""
        return cls()

    @classmethod
    def singleton(cls) -> Optional['AsyncRuntime']:
        """
        Get the AsyncRuntime singleton instance.

        This function has no real use for the user, only to make it easier
        for this module to access the singleton object.
        """
        engine = Engine.get_singleton()
        if engine is None:
            return None

        singleton = engine.get_singleton(cls.SINGLETON)
        if singleton is not None:
            return singleton
        return None

    @classmethod
    def runtime(cls) -> asyncio.AbstractEventLoop:
        """
        Get the active event loop under the AsyncRuntime singleton.

        Can raise RuntimeError if the singleton is unreachable or
        has not been registered by the engine.
        """
        instance = cls.singleton()

        if instance is None:
            # Fail-safe: try to register the singleton
            engine = Engine.get_singleton()
            if engine is not None:
                engine.register_singleton(
                    cls.SINGLETON,
                    cls.new()
                )
                instance = cls.singleton()

        if instance is None or instance._loop is None:
            raise RuntimeError(
                "Engine was not able to register, or get `AsyncRuntime` singleton!"
            )

        return instance._loop

    @classmethod
    def spawn(cls, coro: Coroutine[Any, Any, T]) -> asyncio.Task[T]:
        """
        Spawn an asynchronous task on the runtime.

        This is a wrapper for asyncio.create_task that runs on the
        AsyncRuntime event loop.

        Args:
            coro: A coroutine to execute asynchronously

        Returns:
            An asyncio.Task that can be awaited or cancelled
        """
        loop = cls.runtime()
        return asyncio.run_coroutine_threadsafe(coro, loop)

    @classmethod
    def block_on(cls, coro: Coroutine[Any, Any, T]) -> T:
        """
        Block the current thread until the coroutine completes.

        This is a wrapper for running a coroutine synchronously.

        Args:
            coro: A coroutine to execute

        Returns:
            The result of the coroutine
        """
        loop = cls.runtime()
        future = asyncio.run_coroutine_threadsafe(coro, loop)
        return future.result()

    def spawn_blocking(self, func: Callable[[], T]) -> Future[T]:
        """
        Spawn a blocking function to run in a thread pool.

        This is useful for CPU-intensive operations that would
        block the event loop.

        Args:
            func: A callable that performs blocking work

        Returns:
            A Future that will contain the result
        """
        if self._loop is None or self._executor is None:
            raise RuntimeError("AsyncRuntime is not initialized")

        return self._executor.submit(func)

    def free(self) -> None:
        """Clean up the runtime and stop the event loop"""
        if self._loop is not None and self._loop.is_running():
            self._loop.call_soon_threadsafe(self._loop.stop)

        if self._executor is not None:
            self._executor.shutdown(wait=False)

        if self._thread is not None and self._thread.is_alive():
            # Wait for thread to finish (with timeout)
            self._thread.join(timeout=1.0)
