@tool
extends Control


@onready var file_menu = $Main/ToolBar/FileMenu
@onready var debug_menu = $Main/ToolBar/DebugMenu
@onready var add_menu = $Main/ToolBar/AddMenu
@onready var run_menu = $Main/ToolBar/RunMenu
@onready var workspace = $Main/Workspace
@onready var dialogue_background = $DialogueBackground
@onready var dialogue_box = $DialogueBox
@onready var files = $Main/Workspace/SidePanel/Files
@onready var characters = $Main/Workspace/SidePanel/Data/Characters
@onready var version_number = $Main/Statusbar/VersionNumber

var undo_redo : EditorUndoRedoManager
var graph : GraphEdit
var variables : VBoxContainer
var _debug := false
var _add_menu_initialized := false


func _ready():
	file_menu.get_popup().id_pressed.connect(files._on_toolbar_menu_pressed)
	run_menu.get_popup().id_pressed.connect(run_tree)
	debug_menu.get_popup().id_pressed.connect(_on_debug_menu_pressed)
	
	dialogue_box.dialogue_started.connect(_on_dialogue_started)
	dialogue_box.option_selected.connect(_on_dialogue_option_selected)
	dialogue_box.dialogue_signal.connect(_on_dialogue_signal)
	dialogue_box.variable_changed.connect(_on_dialogue_variable_changed)
	dialogue_box.dialogue_ended.connect(_on_dialogue_ended)
	
	var config = ConfigFile.new()
	config.load('res://addons/dialogue_nodes/plugin.cfg')
	version_number.text = config.get_value('plugin', 'version')


func run_tree(start_node_idx: int):
	if not is_instance_valid(graph): return
	
	var start_node = graph.get_node(NodePath(graph.starts[start_node_idx]))
	var data := DialogueData.new()
	data = start_node.tree_to_data(graph, data)
	data.characters = characters.get_data()
	data.variables = variables.get_data()
	
	dialogue_box.set_data(data)
	dialogue_box.start(start_node.start_id)
	dialogue_background.show()


func _on_debug_menu_pressed(idx : int):
	match (idx):
		0:
			var popup = debug_menu.get_popup()
			_debug = !_debug
			popup.set_item_checked(idx, _debug)


func _on_files_changed():
	add_menu.visible = files.item_count > 0
	run_menu.visible = add_menu.visible
	
	if is_instance_valid(graph):
		graph.run_requested.disconnect(run_tree)
	
	if files.item_count == 0: return
	
	var new_metadata = files.get_current_metadata()
	
	if new_metadata.is_empty():
		graph = null
		variables = null
		return
	
	graph = new_metadata['graph']
	graph.run_requested.connect(run_tree)
	variables = new_metadata['variables']
	
	if not _add_menu_initialized and is_instance_valid(graph):
		graph.init_add_menu(add_menu.get_popup())
		_add_menu_initialized = true


func _on_version_number_pressed():
	DisplayServer.clipboard_set('v'+version_number.text)


func _on_run_menu_about_to_popup():
	if not is_instance_valid(graph): return
	
	run_menu.get_popup().clear()
	
	if graph.starts.size() == 0:
		run_menu.get_popup().add_item('Add a Start Node first!')
		run_menu.get_popup().set_item_disabled(0, true)
		return
	
	graph.starts.sort_custom(func (node_name1, node_name2):
		var id1 = graph.get_node(NodePath(node_name1)).start_id
		var id2 = graph.get_node(NodePath(node_name2)).start_id
		return id1 < id2
		)
	
	for start_node_name in graph.starts:
		var start_id = graph.get_node(NodePath(start_node_name)).start_id
		run_menu.get_popup().add_item(start_id)


func _on_dialogue_background_input(event : InputEvent):
	if event is InputEventMouseButton:
		dialogue_box.stop()
		
		if _debug:
			print('Dialogue canceled')


func _on_dialogue_started(id : String):
	if _debug:
		print_debug('Dialogue started: ', id)


func _on_dialogue_option_selected(idx):
	if _debug:
		print('Option selected. idx: ', idx, ', text: "', dialogue_box.options.get_child(idx).text, '"')


func _on_dialogue_variable_changed(var_name, value):
	variables.set_value(var_name, value)
	files.set_modified(files.cur_idx, true)
	
	if _debug:
		print('Variable changed:', var_name, ', value:', value)


func _on_dialogue_signal(value):
	if _debug:
		print('Dialogue emitted signal with value:', value)


func _on_dialogue_ended():
	dialogue_background.hide()

	if _debug:
		print('Dialogue ended')

