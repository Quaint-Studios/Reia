class_name UIEventBus extends Node

## Minimal event router. UI emits intent. Simulation consumes via systems later.
## Keep this UI-only: it must not mutate ECS state directly.

signal intent_emitted(intent: StringName, payload: Variant)

func emit_intent(intent: StringName, payload: Variant = null) -> void:
	assert(intent != &"", "UIEventBus.emit_intent requires a non-empty intent")
	intent_emitted.emit(intent, payload)
