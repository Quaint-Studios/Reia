"""
Movement components for the ECS game logic.

Converted from Rust to Python 3.14
"""

from dataclasses import dataclass
from typing import NamedTuple


class Vec3(NamedTuple):
    """3D vector for positions, rotations, and velocities"""
    x: float
    y: float
    z: float

    def __add__(self, other: 'Vec3') -> 'Vec3':
        return Vec3(self.x + other.x, self.y + other.y, self.z + other.z)

    def __sub__(self, other: 'Vec3') -> 'Vec3':
        return Vec3(self.x - other.x, self.y - other.y, self.z - other.z)

    def __mul__(self, scalar: float) -> 'Vec3':
        return Vec3(self.x * scalar, self.y * scalar, self.z * scalar)

    def __truediv__(self, scalar: float) -> 'Vec3':
        return Vec3(self.x / scalar, self.y / scalar, self.z / scalar)


@dataclass
class Position:
    """Position component - 3D location of an entity"""
    value: Vec3 = Vec3(0.0, 0.0, 0.0)

    def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0):
        if isinstance(x, Vec3):
            self.value = x
        else:
            self.value = Vec3(x, y, z)


@dataclass
class Rotation:
    """Rotation component - 3D rotation of an entity"""
    value: Vec3 = Vec3(0.0, 0.0, 0.0)

    def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0):
        if isinstance(x, Vec3):
            self.value = x
        else:
            self.value = Vec3(x, y, z)


@dataclass
class Velocity:
    """Velocity component - 3D movement vector"""
    value: Vec3 = Vec3(0.0, 0.0, 0.0)

    def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0):
        if isinstance(x, Vec3):
            self.value = x
        else:
            self.value = Vec3(x, y, z)


@dataclass
class Speed:
    """Speed component - movement speed scalar"""
    value: float = 1.0

    def __init__(self, value: float = 1.0):
        self.value = value
