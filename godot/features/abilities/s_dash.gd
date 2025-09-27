class_name DashAbilitySystem
extends System

const DASH_SPEED: float = 18.0
const DASH_DURATION: float = 0.18
const DASH_COOLDOWN: float = 0.7

func query() -> QueryBuilder:
	return q.with_all([C_DashIntent, C_Velocity, C_CharacterBodyRef])

func process(entity: Entity, delta: float) -> void:
	var dash_intent: C_DashIntent = entity.get_component(C_DashIntent)
	var velocity_comp: C_Velocity = entity.get_component(C_Velocity)
	var body_ref: C_CharacterBodyRef = entity.get_component(C_CharacterBodyRef)
	var character := body_ref.node

	if character == null or not character is CharacterBody3D:
		push_error("DashAbilitySystem: Invalid CharacterBody3D reference for entity %s" % entity)
		return

	# Handle cooldown
	if dash_intent.cooldown > 0.0:
		dash_intent.cooldown = max(0.0, dash_intent.cooldown - delta)
		return

	# Dash state tracking
	if dash_intent.dash_time_left > 0.0:
		dash_intent.dash_time_left = max(0.0, dash_intent.dash_time_left - delta)
		if dash_intent.dash_time_left == 0.0:
			velocity_comp.velocity = Vector3(0, velocity_comp.velocity.y, 0)
			dash_intent.reset()
		return

	# Process dash intent
	if dash_intent.triggered:
		var dash_dir: Vector3 = dash_intent.direction.normalized()
		if dash_dir == Vector3.ZERO:
			dash_dir = - character.transform.basis.z.normalized()
		velocity_comp.velocity = dash_dir * DASH_SPEED

		dash_intent.cooldown = DASH_COOLDOWN
		dash_intent.dash_time_left = DASH_DURATION
		dash_intent.triggered = false
