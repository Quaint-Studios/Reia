class_name FireballAbility
extends Ability

const FIREBALL_SCENE: PackedScene = preload("res://features/abilities/fireball/fireball.tscn")

func _init() -> void:
	name = "Fireball"
	description = "Launches a fiery projectile that deals area damage."
	# icon = preload("res://assets/icons/fireball.png")
	
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

	var caster_node_ref: C_Node3DRef = caster.get_component(C_Node3DRef)
	var target_node_ref: C_Node3DRef = target.get_component(C_Node3DRef)
	if caster_node_ref == null or target_node_ref == null:
		push_error("FireballAbility: Missing C_Node3DRef component on caster or target.")
		return
	
	var caster_node: Node3D = caster_node_ref.node
	var target_node: Node3D = target_node_ref.node
	if caster_node == null or target_node == null:
		push_error("FireballAbility: Invalid Node3D reference on caster or target.")
		return


	# Now that the caster and target are both cached, if we wanted to, we can spawn
	# 1,000,000 fireballs faster.

	# Spawn fireball projectile
	# This can be an entity that has its target set. Great for large scale abilities.
	var fireball_instance := FIREBALL_SCENE.instantiate()
	var fireball_entity: Entity = fireball_instance
	
	var c_fireball: C_Fireball = fireball_entity.get_component(C_Fireball)
	var fireball_node_ref: C_Node3DRef = fireball_entity.get_component(C_Node3DRef)
	
	if c_fireball == null or fireball_node_ref == null:
		push_error("Fireball entity is missing required components.")
		return

	c_fireball.start_position = caster_node.global_transform.origin
	c_fireball.target = target_node_ref
	c_fireball.direction = (target_node.global_position - c_fireball.start_position).normalized()

	fireball_node_ref.node = fireball_instance

	ECS.world.add_entity(fireball_entity)
