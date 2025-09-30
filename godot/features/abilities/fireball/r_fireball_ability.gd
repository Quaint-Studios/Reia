class_name FireballAbility
extends Ability

func _init() -> void:
	name = "Fireball"
	description = "Launches a fiery projectile that deals area damage."
	# icon = preload("res://assets/icons/firebal
	cooldown = 0.25
	skill_power = 5.0
	multiplier = 1.5

	cost = 10
	cost_type = Enums.Resource_Type.ETHER
	mastery = 0.0
	distance = 20.0

	element = Enums.Element_Affinity.PYRO

func get_power(power: int) -> int:
	return ceili(power + skill_power * multiplier)

func execute(caster: Entity, target: Entity) -> void:
	if caster == null or target == null:
		push_error("FireballAbility requires both a caster and a target.")
		return

	var caster_body_ref: C_CharacterBodyRef = caster.get_component(C_CharacterBodyRef)
	var target_node_ref: C_Node3DRef = target.get_component(C_Node3DRef)
	if caster_body_ref == null or target_node_ref == null:
		push_error("FireballAbility: Missing C_Node3DRef component on caster or target.")
		return

	var caster_node: Node3D = caster_body_ref.node
	var target_node: Node3D = target_node_ref.node
	if caster_node == null or target_node == null:
		push_error("FireballAbility: Invalid Node3D reference on caster or target.")
		return


	# Now that the caster and target are both cached, if we wanted to, we can spawn
	# 1,000,000 fireballs faster.

	# Spawn fireball projectile
	# This can be an entity that has its target set. Great for large scale abilities.
	var fireball_tscn := preload("res://features/abilities/fireball/fireball.tscn").instantiate()
	var e_fireball: Entity = fireball_tscn
	ECS.world.add_entity(e_fireball)

	var fireball: Node3D = fireball_tscn
	var node3d_ref: C_Node3DRef = e_fireball.get_component(C_Node3DRef)
	node3d_ref.node = fireball

	var c_fireball: C_Fireball = e_fireball.get_component(C_Fireball)

	if c_fireball == null or node3d_ref == null:
		push_error("Fireball entity is missing required components. %s | %s | %s" % [e_fireball, c_fireball, node3d_ref])
		return

	c_fireball.start_position = caster_node.global_transform.origin
	c_fireball.caster = caster_body_ref
	c_fireball.target = target_node_ref
	c_fireball.direction = (target_node.global_position - c_fireball.start_position).normalized()

	fireball.global_transform.origin = c_fireball.start_position
