@tool
## A parser for reading and processing [param DialogueData] files
@icon('res://addons/dialogue_nodes/icons/DialogueParser.svg')
class_name DialogueParser
extends Node
# TODO : Fix [wait] bbcode

## Triggered when a dialogue has started. Passes [param id] of the dialogue tree as defined in the StartNode.
signal dialogue_started(id : String)
## Triggered when a single dialogue block has been processed.
## Passes [param speaker] which can be a [String] or a [param Character] resource, a [param dialogue] containing the text to be displayed
## and an [param options] list containing the texts for each option.
signal dialogue_processed(speaker : Variant, dialogue : String, options : Array[String])
## Triggered when an option is selected
signal option_selected(idx : int)
## Triggered when a SignalNode is encountered while processing the dialogue.
## Passes a [param value] defined in the SignalNode in the tree.
signal dialogue_signal(value : String)
## Triggered when a variable value is changed.
## Passes the [param variable_name] along with it's [param value]
signal variable_changed(variable_name : String, value)
## Triggered when a dialogue tree has ended processing and reached the end of the dialogue.
signal dialogue_ended

## Contains the [param DialogueData] resource created using the Dialogue Nodes editor. Use [method load_data] to set its value.
@export var data : DialogueData :
	get:
		return data
	set(value):
		data = value
		
		variables.clear()
		if not data is DialogueData: return
		for var_name in data.variables:
			variables[var_name] = data.variables[var_name].value
		
		characters.clear()
		if not data.characters.ends_with('.tres'): return
		var character_list = ResourceLoader.load(data.characters, '', ResourceLoader.CACHE_MODE_IGNORE)
		if not character_list is CharacterList: return
		characters = character_list.characters

## Contains the variable data from the [param DialogueData] parsed in an easy to access dictionary.[br]
## Example: [code]{ "COINS": 10, "NAME": "Obama", "ALIVE": true }[/code]
var variables : Dictionary
## Contains all the [param Character] resources loaded from the path in the [member data].
var characters : Array[Character]

var _running := false
var _option_links := []


## Loads the [param DialogueData] resource from the given [param path]. The loaded resource can be accessed using [member data].
func load_data(path : String):
	if not path.ends_with('.tres'): return
	
	var new_data := ResourceLoader.load(path, '', ResourceLoader.CACHE_MODE_IGNORE)
	if not new_data is DialogueData: return
	
	data = new_data


## Starts processing the dialogue data set in [member data], starting with the Start Node with its ID set to [param start_id].
func start(start_id : String):
	if not data:
		printerr('No dialogue data loaded!')
		return
	if not data.starts.has(start_id):
		printerr('Start ID ', start_id, ' not found in dialogue data!')
		return
	
	_running = true
	dialogue_started.emit(start_id)
	_proceed(data.starts[start_id])


## Stops processing the dialogue tree.
func stop():
	_running = false
	dialogue_ended.emit()


## Continues processing the dialogue tree from the node connected to the option at [param idx].
func select_option(idx : int):
	if not _running: return
	
	if _option_links.size() == 0 or idx > _option_links.size():
		printerr('Option idx ', idx, ' is not selectable.')
		return
	
	option_selected.emit(idx)
	_proceed(_option_links[idx])


## Returns [code]true[/code] if the [DialogueParser] is processing a dialogue tree.
func is_running(): return _running


# Proceeds the parser to the next node and runs its corresponding _process_* function.
func _proceed(node_name : String):
	if node_name == 'END' or not _running:
		stop()
		return
	
	var process_functions := [
		_process_start,
		_process_dialogue,
		func(): pass, # comment
		_process_signal,
		_process_set,
		_process_condition
	]
	
	var id := int(node_name.split('_')[0])
	
	process_functions[id].call(data.nodes[node_name])


# Processes the start node data (dict).
func _process_start(dict : Dictionary):
	_proceed(dict.link)


# Processes the dialogue node data (dict).
func _process_dialogue(dict : Dictionary):
	var speaker = ''
	
	if dict.speaker is String:
		speaker = dict.speaker
	elif dict.speaker is int and characters.size() > 0 and dict.speaker < characters.size():
		speaker = characters[dict.speaker]
	
	var dialogue_text = _parse_variables(dict.dialogue)
	
	var option_texts : Array[String] = []
	_option_links.clear()
	for option in dict.options.values():
		if option.condition.is_empty() or _check_condition(option.condition):
			option_texts.append(_parse_variables(option.text))
			_option_links.append(option.link)
	
	dialogue_processed.emit(speaker, dialogue_text, option_texts)


# Processes the signal node data (dict).
func _process_signal(dict : Dictionary):
	dialogue_signal.emit(dict.signalValue)
	_proceed(dict.link)


# Processes the set node data (dict).
func _process_set(dict : Dictionary):
	if not variables.has(dict.variable):
		printerr('Variable ', dict.variable, ' not found in variables list')
		_proceed(dict.link)
		return
	
	var type = typeof(variables[dict.variable])
	var value = dict.value
	var operator = dict.type
	
	# set datatype of value
	match typeof(variables[dict.variable]):
		TYPE_STRING:
			value = str(value)

			# check for invalid operators
			if operator > 2:
				printerr('Invalid operator for type: String')
				_proceed(dict.link)
				return
		TYPE_INT:
			value = int(value)
		TYPE_FLOAT:
			value = float(value)
		TYPE_BOOL:
			value = (value == 'true') if value is String else bool(value)

			# check for invalid operators
			if operator > 0:
				printerr('Invalid operator for type: Boolean')
				_proceed(dict.link)
				return

	# perform operation
	match operator:
		0:
			variables[dict.variable] = value
		1:
			variables[dict.variable] += value
		2:
			variables[dict.variable] -= value
		3:
			variables[dict.variable] *= value
		4:
			variables[dict.variable] /= value
	
	variable_changed.emit(dict.variable, variables[dict.variable])
	_proceed(dict.link)


# Processes the condition node data (dict).
func _process_condition(dict : Dictionary):
	var result = _check_condition(dict)
	_proceed(dict[str(result).to_lower()])


# Checks the condition based on dict.value1, dict.value2 and dict.operator
func _check_condition(dict : Dictionary):
	var value1 = dict.value1
	var value2 = dict.value2
	
	# get variables if needed
	if value1.count('{{') > 0:
		value1 = _parse_variables(value1)
	if value2.count('{{') > 0:
		value2 = _parse_variables(value2)
	
	# evaluate values if neither values contain any alphabets (otherwise treat them as strings)
	var regex := RegEx.new()
	regex.compile("[a-zA-Z]+")
	if not regex.search(value1) and not regex.search(value2):
		var expression = Expression.new()
		
		if expression.parse(value1) != OK:
			printerr(expression.get_error_text(), ' ', value1)
			return false
		value1 = expression.execute()
		
		if expression.parse(value2) != OK:
			printerr(expression.get_error_text(), ' ', value2)
			return false
		value2 = expression.execute()
	
	# perform operation
	match dict.operator:
		0: return value1 == value2
		1: return value1 != value2
		2: return value1 > value2
		3: return value1 < value2
		4: return value1 >= value2
		5: return value1 <= value2
		_: return false


# Replaces all {{}} variables with their corresponding values in the value string.
# If variable is not found in [member DialogueParse.variables], it is substituted with an empty string along with a console error.
func _parse_variables(value : String):
	# check for missing }}
	if value.count('{{') != value.count('}}'):
		printerr('Failed to parse variables. Missing {{ or }}.')
		return value
	
	# format floats to display properly
	var formatted_variables := {}
	for key in variables.keys():
		if variables[key] is float:
			formatted_variables[key] = '%0.2f' % variables[key]
		else:
			formatted_variables[key] = variables[key]
	
	# add invalid variables as '' in formatted_variables
	for key in _parse_variable_names(value):
		if not variables.has(key):
			printerr('Unknown variable ', key, ' in string.')
			formatted_variables[key] = ''
	
	return value.format(formatted_variables, '{{_}}')


# Returns a list of all the variables in a string denoted in {{}}.
func _parse_variable_names(value: String):
	var regex := RegEx.new()
	regex.compile("{{([^{}]+)}}")
	var results = regex.search_all(value)
	results = results.map(func(val): return val.get_string(1))
	return results


# FIXME : Length calculation is borked when the value has [, ] unrelated to any bbcodes.
# Updates all the [wait] bbcode tags in the given text to include additional info about the text
func _update_wait_tags(node : RichTextLabel, value : String):
	# add a wait if none present at beginning
	if not value.begins_with('[wait'):
		value = '[wait]' + value + '[/wait]'
	
	# find the actual position of the last character sans bbcode
	value = value.replace('\n', ' ').replace('[br]', '\n')
	node.text = value
	
	var text_length := node.get_parsed_text().length() - value.count('\n')
	
	# update [wait] with last attribute for showing options
	var idx := 0
	var char_idx := -1
	var char_count := 0
	var waits := []
	while idx < value.length():
		match value[idx]:
			'[':
				var open_tag_start := value.findn('[wait', idx)
				var open_tag_end := value.findn(']', idx)
				var end_tag := value.findn('[/wait]', idx)
				
				var img_tag := value.findn('[img', idx)
				var img_tag_end := value.findn('[/img]', idx)
				
				if open_tag_start == idx:
					var start_idx := char_idx + 1
					waits.push_back({ 'at': open_tag_end, 'start': start_idx })
					idx = open_tag_end + 1
				elif end_tag == idx:
					var start_data : Dictionary = waits.pop_back()
					var insert_text := ' start='+str(start_data.start)+' last='+str(start_data.last)+' length='+str(text_length)
					value = value.insert(start_data.at, insert_text)
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
		var start_data : Dictionary = waits.pop_back()
		var insert_text := ' start='+str(start_data.start)+' last='+str(char_count - 1)+' length='+str(text_length)
		value = value.insert(start_data.at, insert_text)
	
	return value
