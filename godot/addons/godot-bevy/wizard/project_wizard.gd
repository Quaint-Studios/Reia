@tool
extends ConfirmationDialog

signal project_created(project_info: Dictionary)

@onready var project_name_input: LineEdit = $VBox/ProjectName/LineEdit
@onready var version_input: LineEdit = $VBox/Version/LineEdit
@onready var release_build_check: CheckBox = $VBox/ReleaseBuild

const DEFAULT_VERSION = "0.9.0"

func _ready():
	title = "Setup godot-bevy Project"
	get_ok_button().text = "Create Project"
	get_cancel_button().text = "Cancel"

	# Set defaults
	project_name_input.text = "my_game"
	version_input.text = DEFAULT_VERSION

	# Connect signals
	get_ok_button().pressed.connect(_on_create_pressed)


func _on_create_pressed():
	var info = {
		"project_name": project_name_input.text,
		"godot_bevy_version": version_input.text,
		"release_build": release_build_check.button_pressed
	}

	project_created.emit(info)
	hide()
