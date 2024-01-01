class_name MapHandler extends Node

@onready var players : Node = %Players
@export var load_player := true

func _ready():
	GameManager.instance.load_player()
	
