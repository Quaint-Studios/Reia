class_name PlayerUI extends Control
## The entrypoint for the player UI, which manages the inventory and HUD

@onready var inventory: PlayerUI_Inventory = %Inventory
@onready var hud: PlayerUI_HUD = %HUD

func _ready() -> void:
		if PlayerManager.instance.player == null:
			disable() # Disable the UI by default until a player is created

func enable() -> void:
		show()
		process_mode = Node.PROCESS_MODE_INHERIT

func disable() -> void:
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED