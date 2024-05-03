@tool
extends GraphNode


signal modified
signal character_list_requested(dialogue_node : GraphNode)
signal disconnection_from_request(from_node : String, from_port : int)
signal connection_shift_request(from_node : String, old_port : int, new_port : int)

@export var max_options = 4
@export var resize_timer : Timer
@export var custom_speaker_timer : Timer
@export var dialogue_timer : Timer

@onready var speaker = %Speaker
@onready var custom_speaker := %CustomSpeaker
@onready var character_toggle = %CharacterToggle
@onready var dialogue = %Dialogue
@onready var dialogue_panel = %DialoguePanel
@onready var dialogue_expanded = %DialogueExpanded

var undo_redo : EditorUndoRedoManager
var last_size := size
var last_custom_speaker := ''
var cur_speaker := -1
var last_dialogue := ''
var OptionScene := preload("res://addons/dialogue_nodes/nodes/DialogueNodeOption.tscn")
var options : Array = []
var empty_option : BoxContainer
var first_option_index := -1
var base_color : Color = Color.WHITE


func _ready():
	options.clear()
	for idx in range(get_child_count() - 1, -1, -1):
		var child = get_child(idx)
		if child.is_in_group('dialogue_node_options'):
			add_option(child)
			first_option_index = child.get_index()
			break
	update_slots()


func _to_dict(graph):
	var dict = {}
	
	if custom_speaker.visible:
		custom_speaker.text = custom_speaker.text.replace('{', '').replace('}', '')
		dict['speaker'] = custom_speaker.text
	elif speaker.visible:
		var speaker_idx := -1
		if speaker.item_count > 0:
			speaker_idx = cur_speaker
		dict['speaker'] = speaker_idx
	
	dict['dialogue'] = dialogue.text
	dict['size'] = size
	
	# get options connected to other nodes
	var options_dict = {}
	for connection in graph.get_connections(name):
		var idx : int = connection['from_port'] # this returns index starting from 0
		
		options_dict[idx] = {}
		options_dict[idx]['text'] = options[idx].text
		options_dict[idx]['link'] = connection['to_node']
		options_dict[idx]['condition'] = options[idx].get_condition() if options[idx].text != '' else {}
	
	# get options not connected
	for i in range(options.size()):
		if not options_dict.has(i) and options[i].text != '':
			options_dict[i] = {}
			options_dict[i]['text'] = options[i].text
			options_dict[i]['link'] = 'END'
			options_dict[i]['condition'] = options[i].get_condition()
	
	# single empty disconnected option
	if options_dict.is_empty():
		options_dict[0] = {}
		options_dict[0]['text'] = ''
		options_dict[0]['link'] = 'END'
		options_dict[0]['condition'] = {}
	
	# store options info in dict
	dict['options'] = options_dict
	
	return dict


func _from_dict(dict : Dictionary):
	var next_nodes = []
	
	# set values
	if dict['speaker'] is String:
		custom_speaker.text = dict['speaker']
		last_custom_speaker = custom_speaker.text
	elif dict['speaker'] is int:
		cur_speaker = dict['speaker']
		character_toggle.set_pressed_no_signal(true)
		toggle_speaker_input(true)
	dialogue.text = dict['dialogue']
	dialogue_expanded.text = dialogue.text
	last_dialogue = dialogue.text
	
	# remove any existing options (if any)
	for option in options:
		option.queue_free()
		option.tree_exited
	options.clear()
	
	# add new options
	for idx in dict['options']:
		var condition = {}
		if dict['options'][idx].has('condition'):
			condition = dict['options'][idx]['condition']
		var new_option = OptionScene.instantiate()
		add_option(new_option, first_option_index + int(idx))
		new_option.set_text(dict['options'][idx]['text'])
		new_option.set_condition(condition)
		next_nodes.append(dict['options'][idx]['link'])
	# add empty option is any space left
	if options.size() < max_options and options[-1].text != '':
		var new_option = OptionScene.instantiate()
		add_option(new_option)
	update_slots()
	
	# set size of node
	if dict.has('size'):
		var new_size: Vector2
		if dict['size'] is Vector2:
			new_size = dict['size']
		else: # for dialogue files created before v1.0.2
			new_size = Vector2( float(dict['size']['x']), float(dict['size']['y']) )
		size = new_size
		last_size = size
	
	return next_nodes


func set_custom_speaker(new_custom_speaker):
	if custom_speaker.text != new_custom_speaker:
		custom_speaker.text = new_custom_speaker
	last_custom_speaker = custom_speaker.text


func toggle_speaker_input(use_speaker_list):
	custom_speaker.visible = not use_speaker_list
	speaker.visible = use_speaker_list


func set_dialogue_text(new_text):
	if dialogue.text != new_text:
		dialogue.text = new_text
	if dialogue_expanded.text != new_text:
		dialogue_expanded.text = dialogue.text
	last_dialogue = dialogue.text


func add_option(option : BoxContainer, to_idx := -1):
	if option.get_parent() != self: add_child(option, true)
	if to_idx > -1: move_child(option, to_idx)
	
	option.undo_redo = undo_redo
	option.text_changed.connect(_on_option_text_changed.bind(option))
	option.focus_exited.connect(_on_option_focus_exited.bind(option))
	options.append(option)
	
	# sort options in the array
	options.sort_custom(func (op1, op2):
		return op1.get_index() < op2.get_index()
		)
	
	# shift slot connections
	var idx = options.find(option)
	for i in range(options.size() - 1, idx, -1):
		if options[i].text != '':
			connection_shift_request.emit(name, i - 1, i)


func remove_option(option : BoxContainer):
	# shift slot connections
	var idx = options.find(option)
	for i in range(idx, options.size() - 1):
		if options[i + 1].text != '':
			connection_shift_request.emit(name, i + 1, i)
	
	options.erase(option)
	option.text_changed.disconnect(_on_option_text_changed.bind(option))
	option.focus_exited.disconnect(_on_option_focus_exited.bind(option))
	
	if option.get_parent() == self: remove_child(option)


func update_slots():
	if options.size() == 1:
		set_slot(options[0].get_index(), false, 0, base_color, true, 0, base_color)
		return
	
	for option in options:
		var enabled = option.text != ''
		set_slot(option.get_index(), false, 0, base_color, enabled, 0, base_color)


func _on_resize(_new_size):
	resize_timer.stop()
	resize_timer.start()


func _on_resize_timer_timeout():
	if not undo_redo: return
	
	undo_redo.create_action('Set node size')
	undo_redo.add_do_method(self, 'set_size', size)
	undo_redo.add_do_property(self, 'last_size', size)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_property(self, 'last_size', last_size)
	undo_redo.add_undo_method(self, 'set_size', last_size)
	undo_redo.commit_action()


func _on_custom_speaker_changed(_new_text):
	custom_speaker_timer.stop()
	custom_speaker_timer.start()


func _on_custom_speaker_timer_timeout():
	if not undo_redo: return
	
	undo_redo.create_action('Set custom speaker')
	undo_redo.add_do_method(self, 'set_custom_speaker', custom_speaker.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_custom_speaker', last_custom_speaker)
	undo_redo.commit_action()


func _on_characters_updated(character_list : Array[Character]):
	speaker.clear()
	
	for character in character_list:
		speaker.add_item(character.name)
	
	if character_list.size() > 0:
		if cur_speaker > character_list.size():
			cur_speaker = 0
		speaker.select(cur_speaker)
	else:
		speaker.select(-1)


func _on_speaker_selected(idx : int):
	if not undo_redo: return
	
	undo_redo.create_action('Set speaker')
	undo_redo.add_do_property(self, 'cur_speaker', idx)
	undo_redo.add_do_method(speaker, 'select', idx)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_property(self, 'cur_speaker', cur_speaker)
	undo_redo.add_undo_method(speaker, 'select', cur_speaker)
	undo_redo.commit_action()


func _on_speaker_toggled(toggled_on : bool):
	if not undo_redo: return
	
	undo_redo.create_action('Toggle character list')
	undo_redo.add_do_method(character_toggle, 'set_pressed_no_signal', toggled_on)
	undo_redo.add_do_method(self, 'toggle_speaker_input', toggled_on)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'toggle_speaker_input', not toggled_on)
	undo_redo.add_undo_method(character_toggle, 'set_pressed_no_signal', not toggled_on)
	undo_redo.commit_action()


func _on_dialogue_text_changed():
	dialogue_timer.stop()
	dialogue_timer.start()


func _on_dialogue_timer_timeout():
	if not undo_redo: return
	
	undo_redo.create_action('Set dialogue text')
	if dialogue_panel.visible:
		undo_redo.add_do_method(self, 'set_dialogue_text', dialogue_expanded.text)
	else:
		undo_redo.add_do_method(self, 'set_dialogue_text', dialogue.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(dialogue_expanded, 'release_focus')
	undo_redo.add_undo_method(self, 'set_dialogue_text', last_dialogue)
	undo_redo.commit_action()


func _on_expand_button_pressed():
	dialogue_panel.popup_centered()
	dialogue_expanded.grab_focus()


func _on_close_button_pressed():
	dialogue_panel.hide()


func _on_option_text_changed(new_text : String, option : BoxContainer):
	if not undo_redo: return
	
	var idx = option.get_index()
	
	# case 0 : option was queued for deletion but changed from '' to 'something'
	if option == empty_option:
		if new_text == '': return
		undo_redo.create_action('Set option text')
		undo_redo.add_do_method(option, 'set_text', new_text)
		undo_redo.add_do_method(self, 'update_slots')
		undo_redo.add_do_method(self, '_on_modified')
		undo_redo.add_undo_method(self, '_on_modified')
		undo_redo.add_undo_method(option, 'set_text', option.text)
		undo_redo.add_undo_method(self, 'update_slots')
		undo_redo.commit_action()
		empty_option = null
		return
	
	if new_text == option.text: return
	
	# case 1 : option changed from '' to 'something'
	if option.text == '':
		if idx == (get_child_count() - 1) and options.size() < max_options:
			var new_option = OptionScene.instantiate()
			
			undo_redo.create_action('Set option text')
			undo_redo.add_do_method(option, 'set_text', new_text)
			undo_redo.add_do_method(self, 'add_option', new_option)
			undo_redo.add_do_method(self, 'update_slots')
			undo_redo.add_do_reference(new_option)
			undo_redo.add_do_method(self, '_on_modified')
			undo_redo.add_undo_method(self, '_on_modified')
			undo_redo.add_undo_method(option, 'set_text', option.text)
			undo_redo.add_undo_method(self, 'remove_option', new_option)
			undo_redo.add_undo_method(self, 'update_slots')
			undo_redo.add_undo_method(self, 'set_size', size)
			undo_redo.commit_action()
			return
	
	# case 2 : option changed from 'something' to ''
	elif new_text == '':
		if idx != (get_child_count() - 1):
			empty_option = option
			return
		disconnection_from_request.emit(name, idx - first_option_index)
	
	# case 3 : text changed from something to something else (neither are '')
	undo_redo.create_action('Set option text')
	undo_redo.add_do_method(option, 'set_text', new_text)
	undo_redo.add_do_method(self, 'update_slots')
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(option, 'set_text', option.text)
	undo_redo.add_undo_method(self, 'update_slots')
	undo_redo.commit_action()


func _on_option_focus_exited(option : BoxContainer):
	if not undo_redo: return
	
	# case 2 : remove option when focus exits
	if option == empty_option:
		var idx = option.get_index()
		
		disconnection_from_request.emit(name, idx - first_option_index)
		
		undo_redo.create_action('Remove option')
		undo_redo.add_do_method(self, 'remove_option', option)
		# if the last option has some text, then create a new empty option
		if options[-1].text != '':
			var new_option = OptionScene.instantiate()
			undo_redo.add_do_method(self, 'add_option', new_option)
			undo_redo.add_do_reference(new_option)
			undo_redo.add_undo_method(self, 'remove_option', new_option)
		undo_redo.add_do_method(self, 'update_slots')
		undo_redo.add_do_method(self, '_on_modified')
		undo_redo.add_undo_method(self, '_on_modified')
		undo_redo.add_undo_method(self, 'add_option', option, idx)
		undo_redo.add_undo_method(option, 'set_text', option.text)
		undo_redo.add_undo_method(self, 'update_slots')
		undo_redo.commit_action()
		empty_option = null


func _on_modified():
	modified.emit()
