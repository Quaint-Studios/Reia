class_name DroppedItems2 extends Node3D

var items: Array[Item]
@export var loot_pivot: Node3D
@export var rot_speed: float = 0.5

func _ready():
	if loot_pivot == null:
		loot_pivot = %LootPivot

	update_pos()

func evenly_rotate_around(index: int, count: int, radius: float):
	if count <= 0:
		count = 1
	var degree = (360.0 / count) * PI / 180.0 * index

	return Vector2(radius * deg_to_rad(cos(degree)), radius * deg_to_rad(sin(degree)))

func _process(delta: float):
	loot_pivot.rotate_y(rot_speed * delta)
	update_pos()

func update_pos():
	var children = loot_pivot.get_children()
	var index = -1
	for loot in children:
		index += 1
		var offset = 0.69
		var radius = offset * (50.4 + (offset * 10.0))
		var new_pos = evenly_rotate_around(index, children.size(), radius)
		loot.position = Vector3(new_pos.x, 0.0, new_pos.y)

func add_all(_items: Array[Item]):
	items = _items

func pickup(player: Player):
	pass
