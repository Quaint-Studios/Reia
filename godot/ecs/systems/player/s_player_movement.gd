class_name PlayerMovementSystem
extends System

func query() -> QueryBuilder:
    return q.with_all([C_Transform, C_Velocity])

func process(entity: Entity, delta: float) -> void:
    # Apply velocity to position
    pass
