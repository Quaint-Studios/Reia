class_name LootSpawner extends Node3D

static var instance: LootSpawner
@export var dropped_items_model: PackedScene

func _init():
	if instance == null:
		instance = self
	else:
		self.queue_free()

func _ready():
	if dropped_items_model == null:
		dropped_items_model = preload("res://rsc/models/dropped_items/dropped_items.tscn")

func spawn(items: Array[Item], pos: Vector3):
	var dropped_items: DroppedItems = dropped_items_model.instantiate() as DroppedItems
	dropped_items.add_all(items)
	dropped_items.position = pos
	add_child(dropped_items)
