@tool
## A node for displaying branching dialogues, primarily created using the Dialogue Nodes editor.[br]
## NOTE: This node is not good at handling long paragraphs of text. It is recommended to use [DialogueBox] instead, or create your custom implementation using [DialogueParser].
## @experimental
class_name DialogueBubble
extends RichTextLabel


## Triggered when a dialogue has started. Passes [param id] of the dialogue tree as defined in the StartNode.
signal dialogue_started(id : String)
## Triggered when a single dialogue block has been processed.
## Passes [param speaker] which can be a [String] or a [param Character] resource, a [param dialogue] containing the text to be displayed
## and an [param options] list containing the texts for each option.
signal dialogue_processed(speaker : Variant, dialogue : String, options : Array[String])
## Triggered when an option is selected
signal option_selected(idx : int)
## Triggered when a SignalNode is encountered while processing the dialogue.
## Passes a [param value] of type [String] that is defined in the SignalNode in the dialogue tree.
signal dialogue_signal(value : String)
## Triggered when a variable value is changed.
## Passes the [param variable_name] along with it's [param value]
signal variable_changed(variable_name : String, value)
## Triggered when a dialogue tree has ended processing and reached the end of the dialogue.
signal dialogue_ended

@export_group('Data')
## Contains the [param DialogueData] resource created using the Dialogue Nodes editor.
@export var data : DialogueData :
	get:
		return data
	set(value):
		data = value
		if _dialogue_parser:
			_dialogue_parser.data = value
			variables = _dialogue_parser.variables
			characters = _dialogue_parser.characters
## The default start ID to begin dialogue from. This is the value you set in the Dialogue Nodes editor.
@export var start_id : String

@export_group('Bubble')
## The node the dialogue bubble would follow. Only accepts [Node2D], [Node3D] or their derivitives.
@export var follow_node : Node :
	set(value):
		if (not value) or (value is Node2D) or (value is Node3D):
			follow_node = value
		else:
			printerr('Follow node must be of the type Node2D, Node3D or any of their sub classes.')
## The speed at which the [DialogueBubble] moves towards the [member follow_node]'s location
@export_range(1, 60) var smooth_follow := 10
## The distance at which the [DialogueBubble] would be positioned from the [member follow_node].[br]
## NOTE: The size of the [DialogueBubble] is also taken as a factor when calculating the distance.
@export var bubble_offset := 72
## The color of the tail of the [DialogueBubble].
@export var tail_color := Color('#222') :
	set(value):
		tail_color = value
		if tail:
			tail.color = tail_color
## The distance between the origin point of the [member follow_node] and the end of the tail.
@export var tail_offset := 32
## The width of the base of the tail.
@export var tail_base := 8

@export_group('Speaker')
## The default color for the speaker label.
@export var default_speaker_color := Color.WHITE :
	set(value):
		default_speaker_color = value
		if speaker_label: speaker_label.modulate = default_speaker_color
@export_group('Dialogue')
## Input action used to skip dialogue animation
@export var skip_input_action := 'ui_cancel'
## Custom RichTextEffects that can be used in the dialogue as bbcodes.[br]
## Example: [code][ghost]Spooky dialogue![/ghost][/code]
@export var dialogue_custom_effects : Array[RichTextEffect] = [
	RichTextWait.new(),
	RichTextGhost.new(),
	RichTextMatrix.new()
	]

@export_group('Options')
## The maximum number of options to show in the dialogue box.
@export var max_options_count := 2 :
	get:
		return max_options_count
	set(value):
		max_options_count = max(value, 1)
		
		if not options_container: return
		# clear all options
		for option in options_container.get_children():
			options_container.remove_child(option)
			option.queue_free()
		
		for idx in range(max_options_count):
			var button = Button.new()
			options_container.add_child(button)
			button.text = 'Option '+str(idx+1)
			button.pressed.connect(select_option.bind(idx))
		options_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		options_container.set_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		options_container.position.y = 32
## Icon displayed when no text options are available.
@export var next_icon := preload('res://addons/dialogue_nodes/icons/Play.svg')

## Contains the variable data from the [param DialogueData] parsed in an easy to access dictionary.[br]
## Example: [code]{ "COINS": 10, "NAME": "Obama", "ALIVE": true }[/code]
var variables : Dictionary
## Contains all the [param Character] resources loaded from the path in the [member data].
var characters : Array[Character]
## The tail of the dialogue bubble.
var tail : Polygon2D
## Displays the name of the speaker in the [DialogueBox]. Access the speaker name by [code]DialogueBox.speaker_label.text[/code]. This value is automatically set while running a dialogue tree.
var speaker_label : Label
## Contains all the option buttons. The currently displayed options are visible while the rest are hidden. This value is automatically set while running a dialogue tree.
var options_container : BoxContainer

# [param DialogueParser] used for parsing the dialogue [member data].
# NOTE: Using [param DialogueParser] as a child instead of extending from it, because [DialogueBox] needs to extend from Panel.
var _dialogue_parser : DialogueParser
var _visible_on_screen_notifier : VisibleOnScreenNotifier3D
var _wait_effect : RichTextWait
var _fade_tween : Tween
var _running := false

# All the children nodes are created in this function
func _enter_tree():
	if get_child_count() > 0:
		for child in get_children():
			remove_child(child)
			child.queue_free()
	
	if Engine.is_editor_hint():
		bbcode_enabled = true
		fit_content = true
		size = Vector2.ZERO
		text = 'Sample dialogue.'
		autowrap_mode = TextServer.AUTOWRAP_OFF
		clip_contents = false
		for effect in dialogue_custom_effects:
			if not custom_effects.has(effect):
				custom_effects.append(effect)
		if not theme:
			theme = preload('res://addons/dialogue_nodes/themes/bubblyClean.theme')
	
	tail = Polygon2D.new()
	add_child(tail)
	tail.color = tail_color
	tail.polygon = [
		Vector2(-32, 0),
		Vector2(0, 0),
		Vector2(0, 16)
	]
	tail.show_behind_parent = true
	
	speaker_label = Label.new()
	add_child(speaker_label)
	speaker_label.text = 'Speaker'
	speaker_label.position = Vector2(6, -32)
	
	options_container = BoxContainer.new()
	add_child(options_container)
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER
	max_options_count = max_options_count
	options_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	options_container.set_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	options_container.position.y = 32
	
	_visible_on_screen_notifier = VisibleOnScreenNotifier3D.new()
	add_child(_visible_on_screen_notifier)
	_visible_on_screen_notifier.screen_entered.connect(_on_screen_entered)
	_visible_on_screen_notifier.screen_exited.connect(_on_screen_exited)
	
	_dialogue_parser = DialogueParser.new()
	add_child(_dialogue_parser)
	_dialogue_parser.data = data
	variables = _dialogue_parser.variables
	characters = _dialogue_parser.characters
	
	_dialogue_parser.dialogue_started.connect(_on_dialogue_started)
	_dialogue_parser.dialogue_processed.connect(_on_dialogue_processed)
	_dialogue_parser.option_selected.connect(_on_option_selected)
	_dialogue_parser.dialogue_signal.connect(_on_dialogue_signal)
	_dialogue_parser.variable_changed.connect(_on_variable_changed)
	_dialogue_parser.dialogue_ended.connect(_on_dialogue_ended)


func _ready():
	for effect in custom_effects:
		if effect is RichTextWait:
			_wait_effect = effect
			_wait_effect.wait_finished.connect(_on_wait_finished)
			break
	
	if not Engine.is_editor_hint():
		scale = Vector2.ZERO
		modulate = Color.TRANSPARENT
		hide()


func _process(delta):
	if Engine.is_editor_hint(): return
	if not _running: return
	if not follow_node: return
	
	var camera
	var screen_center : Vector2
	var follow_pos : Vector2
	var target_pos : Vector2
	
	if follow_node is Node2D:
		camera = get_viewport().get_camera_2d()
		screen_center = camera.global_position if camera else get_viewport_rect().size * 0.5
		follow_pos = follow_node.global_position
	elif follow_node is Node3D:
		camera = get_viewport().get_camera_3d()
		screen_center = get_viewport_rect().size * 0.5
		follow_pos = camera.unproject_position(follow_node.global_position)
		_visible_on_screen_notifier.global_position = follow_node.global_position
	
	var angle := screen_center.angle_to_point(follow_pos)
	var size_offset := Vector2(cos(angle) * size.x * 0.5, sin(angle) * size.y * 0.5)
	target_pos = follow_pos + follow_pos.direction_to(screen_center) * (bubble_offset) - size_offset
	if follow_pos == screen_center:
		target_pos += Vector2(1, -1).normalized() * bubble_offset
	
	if follow_node is Node3D and target_pos.distance_to(position) > screen_center.distance_to(Vector2.ZERO) * 1.8:
		position = target_pos
	
	pivot_offset = follow_pos - position
	position = lerp(position, target_pos - size * 0.5, smooth_follow * delta)
	
	var dir : Vector2 = follow_pos.direction_to(position + size * 0.5)
	var perp = dir.rotated(PI * 0.5)
	tail.polygon[0] = follow_pos - position + dir * tail_offset
	tail.polygon[1] = size * 0.5 + perp * (size.y * 0.4 + tail_base)
	tail.polygon[2] = size * 0.5 - perp * (size.y * 0.4 + tail_base)


func _input(_event):
	if is_running() and Input.is_action_just_pressed(skip_input_action):
		if _wait_effect:
			_wait_effect.skip = true
		_on_wait_finished()


## Starts processing the dialogue [member data], starting with the Start Node with its ID set to [param start_id].
func start(id := start_id):
	if not _dialogue_parser: return
	_dialogue_parser.start(id)


## Stops processing the dialogue tree.
func stop():
	if not _dialogue_parser: return
	_dialogue_parser.stop()


## Continues processing the dialogue tree from the node connected to the option at [param idx].
func select_option(idx : int):
	if not _dialogue_parser: return
	_dialogue_parser.select_option(idx)


## Returns [code]true[/code] if the [DialogueBubble] is processing a dialogue tree.
func is_running():
	return _running


func _on_dialogue_started(id : String):
	_running = true
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, 'scale', Vector2.ONE, 0.3)
	tween.parallel().tween_property(self, 'modulate', Color.WHITE, 0.3)
	show()
	dialogue_started.emit(id)


func _on_dialogue_processed(speaker : Variant, dialogue : String, options : Array[String]):
	# set speaker
	speaker_label.text = ''
	if speaker is Character:
		speaker_label.text = speaker.name
		speaker_label.modulate = speaker.color
	elif speaker is String:
		speaker_label.text = speaker
		speaker_label.modulate = Color.WHITE
	speaker_label.size = Vector2.ZERO
	
	# set dialogue
	text = _dialogue_parser._update_wait_tags(self, dialogue)
	size = Vector2.ZERO
	_wait_effect.skip = false
	
	# set options
	for idx in range(options_container.get_child_count()):
		var option : Button = options_container.get_child(idx)
		if idx >= options.size():
			option.hide()
			continue
		option.text = options[idx].replace('[br]', '\n')
		option.show()
	options_container.get_child(0).icon = next_icon if options.size() == 1 and options[0] == '' else null
	options_container.hide()
	
	dialogue_processed.emit(speaker, dialogue, options)


func _on_option_selected(idx : int):
	option_selected.emit(idx)


func _on_dialogue_signal(value : String):
	dialogue_signal.emit(value)


func _on_variable_changed(variable_name : String, value):
	variable_changed.emit(variable_name, value)


func _on_dialogue_ended():
	_running = false
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(self, 'scale', Vector2.ZERO, 0.3)
	tween.parallel().tween_property(self, 'modulate', Color.TRANSPARENT, 0.3)
	await tween.finished
	hide()
	dialogue_ended.emit()


func _on_screen_entered():
	if _running:
		_dialogue_parser._running = true
		options_container.get_child(0).grab_focus()
		if _fade_tween: _fade_tween.kill()
		_fade_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		_fade_tween.tween_property(self, 'modulate', Color.WHITE, 0.2)
		show()


func _on_screen_exited():
	if _running:
		_dialogue_parser._running = false
		if _fade_tween: _fade_tween.kill()
		_fade_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_fade_tween.tween_property(self, 'modulate', Color.TRANSPARENT, 0.2)
		await _fade_tween.finished
		hide()


func _on_wait_finished():
	options_container.show()
	options_container.get_child(0).grab_focus()
