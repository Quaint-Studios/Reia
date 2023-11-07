class_name DroppedItems extends Node3D

@export var loot_model: PackedScene
@export var loot_pivot: Node3D

var items: Array[Item]
var rot_speed := 0.5
var offset := 0.69
var deleting := false

func _ready():
	if loot_pivot == null:
		loot_pivot = %LootPivot

	if loot_model == null:
		loot_model = preload("res://rsc/models/dropped_items/loot.tscn")

	update_pos()
	update_scale()
	update_count()

func evenly_rotate_around(index: int, count: int, radius: float):
	if count <= 0:
		count = 1
	var degree = (360.0 / count) * PI / 180.0 * index

	return Vector2(radius * deg_to_rad(cos(degree)), radius * deg_to_rad(sin(degree)))

func _process(delta: float):
	loot_pivot.rotate_y(rot_speed * delta)
	update_count()
	update_pos()
	update_scale()

func update_count():
	if deleting && items.size() == 0:
		self.queue_free()
		return

	var child_count := loot_pivot.get_child_count()
	var items_size := items.size()

	if child_count == items_size:
		deleting = items.size() == 0 # TODO: Simplify this whole function?
		return

	if child_count > items_size:
		# Downsize
		for i in child_count - items_size:
			var child = loot_pivot.get_child(0)
			loot_pivot.remove_child(child)
			child.queue_free()
	else:
		# Up[Dog]size
		for i in items_size - child_count:
			loot_pivot.add_child(loot_model.instantiate())

	# Refactor all children
	for i in loot_pivot.get_child_count():
		var loot: Node3D = loot_pivot.get_child(i)
		loot.name = "Loot_%s_%s" % ["Legendary", i]
		# TODO: Set color as well

	# There's no way this could ever be true? Because item.size() has to be positive to get down here...?
	# Consider being more efficient and just setting it to false and not using a statement.
	deleting = items.size() == 0 # If empty, queue for deletion the next time the node updates.

func update_scale():
	# Scale the core up based on count
	# Scale the orbs down to compensate for the core's increased size
	# Result: More orbs able to be around the core when there's more loot
	pass

func update_pos():
	# TODO: Use sin() to animate the core.
	var children = loot_pivot.get_children()
	var index = -1
	for loot in children:
		index += 1
		var radius = offset * (50.4 + (offset * 10.0))
		var new_pos = evenly_rotate_around(index, children.size(), radius)
		loot.position = Vector3(new_pos.x, 0.0, new_pos.y)

func add_all(_items: Array[Item]):
	items = _items

func pickup(player: Player):
	pass
