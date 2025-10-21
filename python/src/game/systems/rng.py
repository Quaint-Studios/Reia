"""
Random number generation for gameplay.

Converted from Rust to Python 3.14
"""

import random
from typing import Optional


class GameRng:
    """
    Deterministic / fast RNG wrapper for gameplay needs (crit rolls, etc.)

    Supports both seeded (deterministic) and entropy-based (random) construction.
    This is the Python equivalent of Rust's SmallRng.
    """

    def __init__(self, seed: Optional[int] = None):
        """
        Initialize the RNG.

        Args:
            seed: Optional seed for deterministic RNG. If None, uses system entropy.
        """
        if seed is not None:
            self._rng = random.Random(seed)
        else:
            self._rng = random.Random()

    @classmethod
    def from_seed(cls, seed: int) -> 'GameRng':
        """
        Create from explicit seed (deterministic across runs).

        Args:
            seed: Seed value for deterministic RNG

        Returns:
            GameRng instance with specified seed
        """
        return cls(seed=seed)

    @classmethod
    def from_entropy(cls) -> 'GameRng':
        """
        Create from system entropy (non-deterministic).

        Returns:
            GameRng instance with random seed
        """
        return cls(seed=None)

    def next_u16_in_basis(self) -> int:
        """
        Generate a random integer in range 0..=10000 basis points.

        This is useful for crit checks stored in basis points.

        Returns:
            Random integer in range [0, 10000]
        """
        return self._rng.randint(0, 10000)

    def next_f32(self) -> float:
        """
        Generate a random float in range [0.0, 1.0).

        Returns:
            Random float
        """
        return self._rng.random()

    def next_u32(self) -> int:
        """
        Generate a random unsigned 32-bit integer.

        Returns:
            Random integer in range [0, 2^32-1]
        """
        return self._rng.randint(0, 0xFFFFFFFF)

    def randint(self, a: int, b: int) -> int:
        """
        Generate a random integer in range [a, b].

        Args:
            a: Lower bound (inclusive)
            b: Upper bound (inclusive)

        Returns:
            Random integer in range [a, b]
        """
        return self._rng.randint(a, b)

    def choice(self, seq):
        """
        Choose a random element from a non-empty sequence.

        Args:
            seq: Sequence to choose from

        Returns:
            Random element from seq
        """
        return self._rng.choice(seq)

    def shuffle(self, seq):
        """
        Shuffle a sequence in place.

        Args:
            seq: Sequence to shuffle
        """
        self._rng.shuffle(seq)
