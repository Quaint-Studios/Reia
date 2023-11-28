@tool extends MarginContainer

@export var item_name = "Wooden Sword":
	set(value):
		item_name = value
		if is_node_ready():
			update_name()
		print("New name is %s" % value)
	get:
		return item_name

@export var grade: Item.ItemGrade:
	set(value):
		grade = value
		if is_node_ready():
			update_grade()
		print("New grade is %s" % value)
	get:
		return grade

func update_all():
	update_name()
	update_grade()

func update_name():
	%Label.text = item_name
	pass

func update_grade():
	reset_grades()

	match grade:
		Item.ItemGrade.COMMON:
			%Common.show()
		Item.ItemGrade.UNCOMMON:
			%Uncommon.show()
		Item.ItemGrade.RARE:
			%Rare.show()
		Item.ItemGrade.SACRED:
			%Sacred.show()
		Item.ItemGrade.ARCANE:
			%Arcane.show()
		Item.ItemGrade.RADIANT:
			%Radiant.show()

	pass

func reset_grades():
	for gradeBG in %GradeBGs.get_children():
		gradeBG.hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_all()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
