class_name InteractorUI extends Control

@export var object_name: Label

func _ready() -> void:
	if object_name == null:
		object_name = get_node("HBoxContainer/ObjectName") as Label
