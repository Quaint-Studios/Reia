@tool
extends Panel
## A node for displaying branching dialogues, primarily created using the Dialogue Nodes editor.
class_name DialogueBox


## Triggered when a dialogue has started. Passes [param id] of the dialogue tree as defined in the StartNode.
signal dialogue_started(id: String)
## Triggered when a single dialogue block has been processed.
signal dialogue_proceeded(node_type: String)
## Triggered when a SignalNode is encountered while processing the dialogue. Passes a [param value] of type [String] that is defined in the SignalNode in the tree.
signal dialogue_signal(value: String)
## Triggered when a dialogue tree has ended processing and reached the end of the dialogue. The [DialogueBox] may hide based on the [member DialogueBox.hide_on_dialogue_end] property.
signal dialogue_ended
## Triggered when a SetNode is encountered while processing the dialogue and the value of a variable is changed. Passes the name of the variable changed: [param var_name] of type [String] & the new [param value] of the variable which can be one of the types: [String], [int], [float] or [bool].
signal variable_changed(var_name: String, value)
## Triggered when an option is selected
signal option_selected(idx: int)

@export_group('Data')
## Contains the dialogue data created using the Dialogue Nodes editor. Use [method DialogueBox.set_data] to set its value.
@export var dialogue_data : DialogueData = null : set = set_data
## Start ID to begin dialogue from. The is the value you set in the Dialogue Nodes editor.
@export var start_id: String

@export_group('Visuals')
## Maximum possible number of options to display.
@export_range(1, 8) var max_options = 4: set = _set_options_count
## Alignment of options.
@export_enum('Begin', 'Center', 'End') var options_alignment = 2: set = _set_options_alignment
## Orientation of options.
@export var options_vertical : bool = false: set = _set_options_vertical
## Position of options along the dialogue box.
@export_enum('Top', 'Left', 'Right', 'Bottom') var options_position = 3: set = _set_options_position
## Icon displayed when no text options are available.
@export var next_icon := preload('res://addons/dialogue_nodes/icons/Play.svg')
## Sample portrait image that is visible in editor. This will not show in-game.
@export var sample_portrait := preload('res://addons/dialogue_nodes/icons/Portrait.png'): set = _set_sample_portrait
## The default color for the speaker label.
@export var default_speaker_color := Color.WHITE: set = _set_default_speaker_color
## Hide the character portrait (useful for custom character portrait implementations).
@export var hide_portrait := false: set = _set_portrait_visibility

@export_group('Misc')
## Input action used to skip dialogue animation
@export var skip_input_action := 'ui_cancel'
## Speed of scroll when using joystick/keyboard input
@export var scroll_speed := 4
## Hide dialogue box at the end of a dialogue
@export var hide_on_dialogue_end := true
## Custom RichTextEffects used (Ex: wait, ghost)
@export var custom_effects : Array[RichTextEffect] = [
		RichTextWait.new(),
		RichTextGhost.new()
		]

## Displays the name of the speaker in the [DialogueBox]. Access the speaker name by [member DialogueBox.speaker.text]. This value is automatically set while running a dialogue tree.
var speaker : Label
## Displays the portrait image of the speaker in the [DialogueBox]. Access the speaker's texture by [member DialogueBox.portrait.texture]. This value is automatically set while running a dialogue tree.
var portrait : TextureRect
## Displayed the dialogue text. This value is automatically set while running a dialogue tree.
var dialogue : RichTextLabel
## Contains all the option buttons. The currently displayed options are visible while the rest are hidden. This value is automatically set while running a dialogue tree.
var options : BoxContainer
var _hbox_container : HBoxContainer
var _vbox_container : VBoxContainer

## Stores whether a dialogue tree is running or not. Do not change this value directly.
var running = false
## [Dictionary] containing all the variables defined in the [member DialogueBox.dialogue_data].
var variables = {}
## [Array] of all the [Character] used for the dialogue dialogue_data.
var character_list : CharacterList = null

var _bbcode_regex : RegEx


func _enter_tree():
	if get_child_count() > 0:
		for child in get_children():
			remove_child(child)
			child.queue_free()

	## dialogue box setup code ##
	# note : edit the code below to change the layout of your dialogue box

	# setup dialog panel
	custom_minimum_size = Vector2(256, 128)

	# setup containers
	var margin_container := MarginContainer.new()
	add_child(margin_container)
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.offset_left = 4
	margin_container.offset_top = 4
	margin_container.offset_right = -4
	margin_container.offset_bottom = -4

	_hbox_container = HBoxContainer.new()
	margin_container.add_child(_hbox_container)

	# setup portrait image
	portrait = TextureRect.new()
	_hbox_container.add_child(portrait)
	portrait.texture = sample_portrait
	portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	portrait.size_flags_stretch_ratio = 0


	_vbox_container = VBoxContainer.new()
	_hbox_container.add_child(_vbox_container)
	_vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# setup speaker, dialogue
	speaker = Label.new()
	_vbox_container.add_child(speaker)
	speaker.text = 'Speaker'

	dialogue = RichTextLabel.new()
	_vbox_container.add_child(dialogue)
	dialogue.text = 'Sample dialogue.\nLoad a [u]dialogue file[/u].'
	dialogue.bbcode_enabled = true
	dialogue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue.custom_effects = custom_effects

	# setup options
	options = BoxContainer.new()
	_vbox_container.add_child(options)
	options.alignment = options_alignment

	for i in range(max_options):
		var button = Button.new()
		button.text = 'Option '+str(i+1)
		options.add_child(button)


func _ready():
	_set_options_alignment(options_alignment)
	_set_options_vertical(options_vertical)
	_set_options_position(options_position)

	hide()
	if hide_portrait:
		portrait.hide()

	if dialogue_data:
		_init_variables(dialogue_data.variables)

	_bbcode_regex = RegEx.new()
	_bbcode_regex.compile('\\n|\\[img\\].*?\\[\\/img\\]|\\[.*?\\]')
	
	for effect in custom_effects:
		if effect is RichTextWait:
			effect.wait_finished.connect(show_options)
			break


func _process(delta):
	# scrolling for longer dialogues
	if not running:
		return

	var scroll_amt := 0.0
	if options_vertical:
		scroll_amt = Input.get_axis("ui_left", "ui_right")
	else:
		scroll_amt = Input.get_axis("ui_up", "ui_down")

	if scroll_amt:
		dialogue.get_v_scroll_bar().value += int(scroll_amt * scroll_speed)


func _input(event):
	if Input.is_action_just_pressed(skip_input_action):
		custom_effects[0].skip = true
		options.show()


## Sets the value of [member DialogueBox.dialogue_data].
func set_data(new_data : DialogueData):
	if new_data and not new_data is DialogueData:
		printerr('Unsupported file!')
		return
	
	dialogue_data = new_data
	if dialogue_data:
		# load variables from the dialogue_data
		_init_variables(dialogue_data.variables)

		# load characters
		character_list = null
		if dialogue_data.characters.ends_with('.tres'):
			var file = ResourceLoader.load(dialogue_data.characters, '', ResourceLoader.CACHE_MODE_REPLACE)
			if file is CharacterList:
				character_list = file


func _init_variables(var_dict):
	variables.clear()

	for var_name in var_dict:
		var type = int(var_dict[var_name]['type'])
		var value = var_dict[var_name]['value']

		set_variable(var_name, type, value)


## Starts running the dialogue tree with the start id [member DialogueBox.id].
func start(id := start_id):
	if !dialogue_data:
		printerr('No dialogue dialogue_data!')
		return
	elif !dialogue_data.starts.has(id):
		printerr('Start ID not present!')
		return

	running = true
	proceed(dialogue_data.starts[id])
	dialogue_started.emit(id)


## Proceeds the running dialogue to the node with the id defined in the [DialogueData]
func proceed(idx: String):
	if idx == 'END' or not running:
		stop()
		return

	var type = idx.split('_')[0]

	# define how to process the current node type
	match(type):
		'0':
			# start
			show()
			proceed(dialogue_data.nodes[idx]['link'])
		'1':
			# dialogue
			_set_dialogue(dialogue_data.nodes[idx])
		'3':
			# signal
			dialogue_signal.emit(dialogue_data.nodes[idx]['signalValue'])
			proceed(dialogue_data.nodes[idx]['link'])
		'4':
			# set
			var var_dict = dialogue_data.nodes[idx]

			var var_name = var_dict['variable']
			var value = var_dict['value']
			var var_type = typeof(variables[var_name]) if variables.has(var_name) else TYPE_STRING
			var operator = int(var_dict['type'])

			set_variable(var_name, var_type, value, operator)

			if variables.has(var_name):
				variable_changed.emit(var_name, variables[var_name])

			proceed(var_dict['link'])
		'5':
			# condition
			var result = _check_condition((dialogue_data.nodes[idx]))

			# Proceed
			proceed(dialogue_data.nodes[idx][str(result).to_lower()])
		_:
			if dialogue_data.nodes[idx].has('link'):
				proceed(dialogue_data.nodes[idx]['link'])
			else:
				stop()
	dialogue_proceeded.emit(type)


## Stops the running dialogue.
func stop():
	running = false
	if hide_on_dialogue_end:
		reset()
		hide()
	dialogue_ended.emit()


## Resets the speaker, dialogue & portrait of the DialogueBox.
func reset():
	speaker.text = ''
	dialogue.text = ''
	portrait.texture = null


func _set_dialogue(dict):
	# set speaker and portrait
	speaker.text = ''
	speaker.modulate = default_speaker_color
	portrait.texture = null
	portrait.hide()
	if dict['speaker'] is String:
		speaker.text = dict['speaker']
	elif dict['speaker'] is int and character_list:
		var idx = dict['speaker']
		if idx > -1 and idx < character_list.characters.size():
			speaker.text = character_list.characters[idx].name
			speaker.modulate = character_list.characters[idx].color
			if character_list.characters[idx].image:
				portrait.texture = character_list.characters[idx].image
				portrait.visible = not hide_portrait

	dialogue.text = '' # workaround for bug
	dialogue.text = _process_text(dict['dialogue'])
	dialogue.get_v_scroll_bar().value = 0
	custom_effects[0].skip = false

	# hide all options
	options.hide()
	for option in options.get_children():
		option.icon = null
		option.hide()

	# set options
	for idx in dict['options']:
		var option = options.get_child(int(idx))
		var option_dict = dict['options'][idx]
		option.text = _process_text(option_dict['text'], false)
		if not option.pressed.is_connected(_on_option_pressed):
			option.pressed.connect(_on_option_pressed.bind(int(idx)))
		if option.pressed.is_connected(proceed):
			option.pressed.disconnect(proceed)
		option.pressed.connect(proceed.bind(option_dict['link']))

		if option_dict.has('condition') and not option_dict['condition'].is_empty():
			option.visible = _check_condition(option_dict['condition'])
		else:
			option.show()

	# set single option to show if none visible
	var _options_visible = 0
	for option in options.get_children():
		_options_visible += 1 if option.visible else 0
	if _options_visible == 0:
		var option = options.get_child(0)
		option.text = ''
		option.icon = next_icon
		if option.is_connected('pressed', proceed):
			option.disconnect('pressed', proceed)
		option.pressed.connect(proceed.bind('END'))
		option.show()

	# if single empty option
	if len(dict['options']) == 1 and options.get_child(0).text == '':
		options.get_child(0).icon = next_icon


func _process_text(text : String, is_dialogue = true):
	# Fill if empty
	if text == '' and is_dialogue:
		text = ' '

	# Add variables
	var formatted_variables = {}
	for key in variables.keys():
		if variables[key] is float:
			formatted_variables[key] = '%0.2f' % variables[key]
		else:
			formatted_variables[key] = variables[key]
	text = text.format(formatted_variables, '{{_}}')

	# Add line breaks (if any)
	text = text.replace('[br]', '\n')

	# return text now if not a dialogue
	if not is_dialogue:
		return text

	# Add a wait if none present at beginning
	if not text.begins_with('[wait'):
		text = '[wait]' + text + '[/wait]'

	# Find the actual position of the last character sans bbcode
	var text_length = _bbcode_regex.sub(text, '', true).length()

	# Update [wait] with last attribute for showing options
	var idx = 0
	var char_idx = -1
	var char_count = 0
	var waits = []
	while idx < text.length():
		match text[idx]:
			'[':
				var open_tag_start = text.findn('[wait', idx)
				var open_tag_end = text.findn(']', idx)
				var end_tag = text.findn('[/wait]', idx)

				var img_tag = text.findn('[img', idx)
				var img_tag_end = text.findn('[/img]', idx)

				if open_tag_start == idx:
					var start = char_idx + 1
					waits.push_back({ 'at': open_tag_end, 'start': start })
					idx = open_tag_end + 1
				elif end_tag == idx:
					var start_data = waits.pop_back()
					var insert_text = ' start='+str(start_data.start)+' last='+str(start_data.last)+' length='+str(text_length)
					text = text.insert(start_data.at, insert_text)
					idx = end_tag + insert_text.length() + 7
				elif img_tag == idx:
					idx = img_tag_end + 6
				else:
					idx = open_tag_end + 1
			'\n':
				idx += 1
			_:
				idx += 1
				char_idx += 1
				char_count += 1
				if waits.size():
					waits[-1]['last'] = char_count - 1

	# insert waits if any left
	while len(waits) > 0:
		var start_data = waits.pop_back()
		var insert_text = ' start='+str(start_data.start)+' last='+str(char_count - 1)+' length='+str(text_length)
		text = text.insert(start_data.at, insert_text)

	return text


## Returns the value of the variable with the name passed in [param text].[br]
## Note: the variable name must be in {{ }} in order to be processed. Ex: [code]$DialogueBox.get_variable("{{MY_VARIABLE}}")[/code].
## To read the values of variables, use: [code]DialogueBox.variables["VAR_NAME_HERE"][/code] instead.
func get_variable(text : String):
	# Find tag position
	var tag_start = text.find('{{')+2
	var tag_len = text.find('}}') - tag_start

	# Find variable value
	var var_name = text.substr(tag_start, tag_len)
	var value = 'undefined'
	if variables.has(var_name):
		value = variables[var_name]

	return value


## Sets the value and type of a variable in [member DialogueBox.variables]. The function requires
## a [param var_name] for the variable name, the [param type] which can be one of: [code]TYPE_STRING[/code], [code]TYPE_INT[/code], [code]TYPE_FLOAT[/code] or [code]TYPE_BOOL[/code][br]
## The operator variable can be used to perform extra calculations when setting the variable value.[br]
## Example:[codeblock]
## # set HEALTH = 100
## $DialogueBox.set_variable("HEALTH", TYPE_INT, 100)
## 
## # set COIN += 10
## $DialogueBox.set_variable("COIN", TYPE_INT, 10, 1)
## [/codeblock]
## However, for the sake of simplicity, you can also change the variables directly:
## [codeblock]
## # set COIN += 10
## $DialogueBox.variables["COIN"] += 10
## [/codeblock]
func set_variable(var_name: String, type: int, value, operator = 0):

	# Set datatype of value
	match type:
		TYPE_STRING:
			value = str(value)

			# Check for invalud operators
			if operator > 2:
				printerr('Invalid operator for type: String')
				return
		TYPE_INT:
			value = int(value)
		TYPE_FLOAT:
			value = float(value)
		TYPE_BOOL:
			value = (value == 'true') if value is String else bool(value)

			# Check for invalid operators
			if operator > 0:
				printerr('Invalid operator for type: Boolean')
				return

	# Perform operation
	match operator:
		0:
			# =
			variables[var_name] = value
		1:
			# +=
			variables[var_name] += value
		2:
			# -=
			variables[var_name] -= value
		3:
			# *=
			variables[var_name] *= value
		4:
			# /=
			variables[var_name] /= value


func _check_condition(cond_dict: Dictionary):
	var value1 = cond_dict['value1']
	var value2 = cond_dict['value2']
	var type = TYPE_STRING

	# Get variables if needed
	if value1.count('{{') > 0:
		value1 = get_variable(value1)
		type = typeof(value1)
	if value2.count('{{') > 0:
		value2 = get_variable(value2)
		type = typeof(value2)

	# Set datatype of values
	match type:
		TYPE_STRING:
			value1 = str(value1)
			value2 = str(value2)
		TYPE_INT:
			value1 = int(value1)
			value2 = int(value2)
		TYPE_FLOAT:
			value1 = float(value1)
			value2 = float(value2)
		TYPE_BOOL:
			value1 = (value1 == 'true') if value1 is String else value1
			value2 = (value2 == 'true') if value2 is String else value2

	# Perform operation
	var result : bool = false
	match int(cond_dict['operator']):
		0:
			result = value1 == value2
		1:
			result = value1 != value2
		2:
			result = value1 > value2
		3:
			result = value1 < value2
		4:
			result = value1 >= value2
		5:
			result = value1 <= value2

	return result


## Shows the options and grabs focus to the first of the visible options. Automatically called after a dialogue text is done playing the animation.
func show_options():
	if options.is_inside_tree():
		options.show()
		for option in options.get_children():
			if option.visible:
				option.grab_focus()
				break


func _set_options_count(value):
	max_options = value
	
	if options:
		# clear all options
		for option in options.get_children():
			options.remove_child(option)
			option.queue_free()

		for i in range(max_options):
			var button = Button.new()
			button.text = 'Option '+str(i+1)
			options.add_child(button)


func _set_options_alignment(value):
	options_alignment = value
	
	if options:
		options.alignment = options_alignment


func _set_options_vertical(value):
	options_vertical = value
	
	if options:
		options.vertical = options_vertical


func _set_options_position(value):
	options_position = value
	
	if options:
		options.get_parent().remove_child(options)

		match value:
			0:
				# top
				_vbox_container.add_child(options)
				_vbox_container.move_child(options, 0)
			3:
				# bottom
				_vbox_container.add_child(options)
			1:
				# left
				_hbox_container.add_child(options)
				_hbox_container.move_child(options, 0)
			2:
				# right
				_hbox_container.add_child(options)


func _set_sample_portrait(value):
	sample_portrait = value
	
	if portrait:
		portrait.texture = sample_portrait


func _set_default_speaker_color(value):
	default_speaker_color = value
	
	if speaker:
		speaker.modulate = default_speaker_color


func _set_portrait_visibility(value):
	hide_portrait = value
	
	if portrait:
		portrait.visible = not hide_portrait


func _on_option_pressed(idx: int):
	option_selected.emit(idx)
