extends Node
## AUTOLOAD: UIEventBus
## Global routing hub for UI interactions.
## Divided into nested classes for scalability. If a class grows too large,
## extract it into its own file (e.g., session_events.gd) and instantiate it here.

# ==========================================
# EVENT CLASSES
# ==========================================

class SessionEvents extends RefCounted:
	signal intent_play_online(ip: String, port: int)
	signal intent_play_solo()
	signal intent_host_and_play(port: int)
	signal intent_host_only(port: int)

class AuthEvents extends RefCounted:
	signal request_login(username: String, token: String)
	signal login_success()
	signal login_failed(reason: String)

class InventoryEvents extends RefCounted:
	signal inventory_updated()
	signal item_equipped(item_id: int)
	signal request_inventory_sort()

class CombatEvents extends RefCounted:
	signal player_health_changed(current: int, max_health: int)
	signal player_mana_changed(current: int, max_mana: int)

class WorldEvents extends RefCounted:
	signal request_teleport(zone_id: int)

# ==========================================
# INSTANTIATED BUSES
# ==========================================

## Access via UIEventBus.session.intent_play_solo.emit()
var session := SessionEvents.new()

## Access via UIEventBus.auth.request_login.emit()
var auth := AuthEvents.new()

## Access via UIEventBus.inventory.inventory_updated.emit()
var inventory := InventoryEvents.new()

## Access via UIEventBus.combat.player_health_changed.emit()
var combat := CombatEvents.new()

## Access via UIEventBus.world.request_teleport.emit()
var world := WorldEvents.new()
