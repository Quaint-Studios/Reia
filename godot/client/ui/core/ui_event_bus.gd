extends Node
## AUTOLOAD: UIEventBus
## Global routing hub for UI interactions. Observers emit to this, and UI listens.

# Inventory Signals
signal inventory_updated()
signal item_equipped(item_id: int)

# Combat / HUD Signals
signal player_health_changed(current: int, max_health: int)
signal player_mana_changed(current: int, max_mana: int)

# Global Requests (UI -> Server/ECS)
signal request_teleport(zone_id: int)
signal request_inventory_sort()
