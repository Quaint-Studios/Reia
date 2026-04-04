extends Node

## AUTOLOAD: EntityMap
## An O(1) lookup table connecting Network IDs to ECS Entities.

var _net_id_to_entity: Dictionary[int, Entity] = {}
var _entity_to_net_id: Dictionary[int, int] = {}

## Called when an entity (Player or Monster) spawns into the world
func register(network_id: int, entity: Entity) -> void:
	_net_id_to_entity[network_id] = entity
	# Store the internal ECS ID for reverse lookups
	_entity_to_net_id[entity.id as int] = network_id

func unregister(network_id: int) -> void:
	if _net_id_to_entity.has(network_id):
		var entity := _net_id_to_entity[network_id]
		var success_to_id := _entity_to_net_id.erase(entity.id as int)
		if not success_to_id:
			push_error("EntityMap: Failed to erase entity ID from reverse lookup.")
		var success_to_entity := _net_id_to_entity.erase(network_id)
		if not success_to_entity:
			push_error("EntityMap: Failed to erase network ID from lookup.")

## O(1) Lookup: Get the ECS Entity for an incoming network packet
func get_entity(network_id: int) -> Entity:
	return _net_id_to_entity.get(network_id, null)

## O(1) Lookup: Get the Network ID for an outgoing ECS broadcast
func get_network_id(entity: Entity) -> int:
	return _entity_to_net_id.get(entity.id as int, 0)
