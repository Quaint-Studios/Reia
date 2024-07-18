class_name PlayerUI extends Control
## The entrypoint for the player UI, which manages the inventory and HUD

@onready var inventory: PlayerUI_Inventory = %Inventory
@onready var hud: PlayerUI_HUD = %HUD

func _ready():
		if PlayerManager.instance.player == null:
			disable() # Disable the UI by default until a player is created

func enable():
		show()
		process_mode = Node.PROCESS_MODE_INHERIT

func disable():
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED