class_name DebugManager extends Node
## This script is used to toggle debugging and the FPS counter.

@export var debugging := true # debug option

const FPS_TIMER_LIMIT = 2.0 # delay for FPS update
@export var fps_debug := true # debug option
var fps_timer := 0.0
@onready var fps_counter: RichTextLabel = $CanvasLayer/FPSCounter
@onready var version_label: Label = $CanvasLayer/Version

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fps_counter.visible = debugging && fps_debug

	# Get the version from the Project Settings
	assert(ProjectSettings.has_setting("application/config/version"), "Version setting not found in Project Settings.")
	version_label.text = "v" + ProjectSettings.get_setting("application/config/version")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (!debugging): return

	if (fps_debug):
		fps_timer += delta
		if fps_timer > FPS_TIMER_LIMIT: # Prints every 2 seconds
			fps_timer = 0.0

		fps_counter.set_text("FPS: " + str(Engine.get_frames_per_second()).pad_decimals(2))

## Toggles debugging and the process mode.
func debug() -> void:
	debugging = !debugging
	process_mode = Node.PROCESS_MODE_DISABLED if !debugging else Node.PROCESS_MODE_INHERIT

### Toggles the FPS counter.
func debug_fps() -> void:
	fps_debug = !fps_debug
	fps_counter.visible = fps_debug
