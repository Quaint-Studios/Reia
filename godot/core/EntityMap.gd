extends Node
## AUTOLOAD: EntityMap
## An O(1) lookup table connecting Network IDs to ECS Entities.

class EntityMapNamespace extends RefCounted:
	## Forward Lookup: Network ID (int) -> Entity (Object reference)
	var _net_id_to_entity: Dictionary[int, Entity] = {}

	## Reverse Lookup: ECS ID (int) -> Network ID (int)
	var _ecs_id_to_net_id: Dictionary[int, int] = {}

	# Notes:
	# print(network_id) # e.g. If you use C_NetworkId.new(10) it's 10
	# print(entity.id) # e.g. c8e3c209-6169-4d96-bf86-a0e748e70f4a
	# print(entity.id as int) # e.g. 9223372036854775807, UUID is too large to be represented at an 64-bit int and will error
	# print(entity.get_instance_id()) # e.g. 82996889288
	# print(instance_from_id(entity.get_instance_id())) # e.g. @Node@36:<Node#82996889288>
	# print(entity.ecs_id) # 1 because it's the first entity created, and increments from there

	## Called when an entity (Player or Monster) spawns into the world
	func register(network_id: int, entity: Entity) -> void:
		_net_id_to_entity[network_id] = entity
		# Store the internal ECS ID for reverse lookups
		_ecs_id_to_net_id[entity.ecs_id] = network_id

	func unregister(network_id: int) -> void:
		if _net_id_to_entity.has(network_id):
			var entity := _net_id_to_entity[network_id]
			var success_to_id := _ecs_id_to_net_id.erase(entity.ecs_id)
			if not success_to_id:
				push_error("[EntityMap] Failed to erase entity ID from reverse lookup.")
			var success_to_entity := _net_id_to_entity.erase(network_id)
			if not success_to_entity:
				push_error("[EntityMap] Failed to erase network ID from lookup.")

	## O(1) Lookup: Get the ECS Entity for an incoming network packet
	func get_entity(network_id: int) -> Entity:
		return _net_id_to_entity.get(network_id, null)

	## O(1) Lookup: Get the Network ID for an outgoing ECS broadcast
	func get_network_id(entity: Entity) -> int:
		return _ecs_id_to_net_id.get(entity.id as int, 0)

	func clear() -> void:
		_net_id_to_entity.clear()
		_ecs_id_to_net_id.clear()

# ==========================================
# INSTANTIATED NAMESPACES
# ==========================================

var server := EntityMapNamespace.new()
var client := EntityMapNamespace.new()

func clear_all() -> void:
	server.clear()
	client.clear()
