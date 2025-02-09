@tool
extends GraphEdit

var context_menu := PopupMenu.new()

enum PopupId {
	ADD_NODE,
	ADD_CHARACTER,
	ADD_DIALOGUE,
	ADD_CONDITION,
}

func _ready() -> void:
	setup_context()

	# Connect signals to handle menu item selection
	var __ := context_menu.connect("id_pressed", _on_popup_item_selected)

	__ = connect("popup_request", _on_popup_request)

## Adds menu items to the context menu.
func setup_context() -> void:
	context_menu.submenu_popup_delay = 0.1
	var nodes_menu := PopupMenu.new()
	nodes_menu.name = "Nodes"
	context_menu.add_child(nodes_menu)
	nodes_menu.add_item("Character", PopupId.ADD_CHARACTER)
	nodes_menu.add_item("Dialogue", PopupId.ADD_DIALOGUE)
	nodes_menu.add_item("Condition", PopupId.ADD_CONDITION)
	context_menu.add_submenu_item("Add Node...", "Nodes", PopupId.ADD_NODE)

	context_menu.add_separator()

	add_child(context_menu)

func _on_popup_request(at_position: Vector2) -> void:
	print("Popup requested at position: ", at_position)

	# Display the popup at the requested position
	var new_pos := DisplayServer.window_get_position() + ((global_position + at_position) as Vector2i)
	var rect_position := Rect2i(new_pos, Vector2i(0, 0))
	context_menu.popup(rect_position)
	pass

func _on_popup_item_selected(id: int) -> void:
	print("Popup item selected: ", id)

	if id == 0: # "Add Node" was selected
		# Implement node creation logic here
		pass
	elif id == 1: # "Disconnect Nodes" was selected
		# Implement node disconnection logic here
		pass
