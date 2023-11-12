class_name PlayerUI extends Node

@export var inventory: PlayerInventory
@export var hud: PlayerHUD

func _ready() -> void:
	UIManager.player_ui = self
