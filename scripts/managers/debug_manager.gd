class_name DebugManager extends Node

var debugging = true # debug option

const FPS_TIMER_LIMIT = 2.0
var fps_debug = true # debug option
var fps_timer = 0.0
@onready var fps_counter = $"FPSCounter";

# Called when the node enters the scene tree for the first time.
func _ready():
	fps_counter.visible = debugging && fps_debug

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(!debugging): return

	if(fps_debug):
		fps_timer += delta
		if fps_timer > FPS_TIMER_LIMIT: # Prints every 2 seconds
			fps_timer = 0.0

		fps_counter.set_text("FPS: " + str(Engine.get_frames_per_second()).pad_decimals(2))

###
### Toggles
###
func debug_fps():
	fps_debug = !fps_debug
	fps_counter.visible = fps_debug
