@tool class_name UI_Item extends MarginContainer

@export var selected: bool:
	set(value):
		selected = value
		if is_node_ready():
			%OutlinePanel.visible = value
			focused = focused

@export var focused: bool:
	set(value):
		focused = value
		if is_node_ready():
			%FocusPanel.visible = value and !selected

@export var item_name = "Wooden Sword":
	set(value):
		item_name = value
		if is_node_ready():
			update_name()
	get:
		return item_name

@export var grade: Item.ItemGrade:
	set(value):
		grade = value
		if is_node_ready():
			update_grade()
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



func _on_button_pressed():
	selected = true

func _on_button_focus_entered():
	focused = true

func _on_button_focus_exited():
	focused = false

func _on_button_toggled(toggled_on):
	print("%s is now %s" % [name, toggled_on])
	selected = toggled_on

func _on_button_mouse_entered():
	focused = true

func _on_button_mouse_exited():
	focused = false
