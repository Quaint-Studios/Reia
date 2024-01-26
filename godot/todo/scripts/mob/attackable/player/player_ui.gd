class_name PlayerUI extends Node

@export var inventory: UI_Inventory
@export var hud: PlayerHUD

func _ready() -> void:
	UIManager.player_ui = self
