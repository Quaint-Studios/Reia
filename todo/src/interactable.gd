class_name Interactable extends Area3D

@export var interact_name: String = "Interactable"

func _ready():
	add_to_group("interactable")

func interact():
	pass
