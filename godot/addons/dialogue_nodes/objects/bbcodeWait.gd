@tool
extends RichTextEffect
class_name RichTextWait

signal wait_finished()
signal char_displayed(char_index)

var bbcode = 'wait'
var finished = false
var skip = false
var displayed = {}

func _process_custom_fx(char_fx):
	var waitTime = float(char_fx.env.get('time', 0.0))
	var speed = float(char_fx.env.get('speed', 50.0))
	var start = int(char_fx.env.get('start', 0))
	var last = int(char_fx.env.get('last', 0))
	var length = int(char_fx.env.get('length', 0))
	var absolute_index = start + char_fx.relative_index
	
	if float(char_fx.elapsed_time) > float(absolute_index / speed) + waitTime or skip:
		char_fx.visible = true
		
		if not finished and absolute_index >= last and last == length - 1:
			finished = true
			wait_finished.emit()
		
		if not displayed.has(absolute_index):
			displayed[absolute_index] = 1
			char_displayed.emit(absolute_index)
	else:
		char_fx.visible = false
		finished = false
		
		if displayed.has(absolute_index):
			displayed.erase(absolute_index)
	
	return true
