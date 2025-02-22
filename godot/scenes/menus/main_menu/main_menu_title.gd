extends Control

@onready var play: MarginContainer = $Play
@onready var settings: MarginContainer = $Settings
@onready var credits: MarginContainer = $Credits
@onready var quit: MarginContainer = $Quit

@onready var playButton: TextureButton = $Play/TextureButton
@onready var settingsButton: TextureButton = $Settings/TextureButton
@onready var creditsButton: TextureButton = $Credits/TextureButton
@onready var quitButton: TextureButton = $Quit/TextureButton

func _ready() -> void:
		var __ := playButton.pressed.connect(_on_play_pressed)
		__ = settingsButton.pressed.connect(_on_settings_pressed)
		__ = creditsButton.pressed.connect(_on_credits_pressed)
		__ = quitButton.pressed.connect(_on_quit_pressed)

		__ = playButton.mouse_entered.connect(_on_mouse_entered.bind("Play", playButton))
		__ = settingsButton.mouse_entered.connect(_on_mouse_entered.bind("Settings", settingsButton))
		__ = creditsButton.mouse_entered.connect(_on_mouse_entered.bind("Credits", creditsButton))
		__ = quitButton.mouse_entered.connect(_on_mouse_entered.bind("Quit", quitButton))

		__ = playButton.mouse_exited.connect(_on_mouse_exited.bind("Play", playButton))
		__ = settingsButton.mouse_exited.connect(_on_mouse_exited.bind("Settings", settingsButton))
		__ = creditsButton.mouse_exited.connect(_on_mouse_exited.bind("Credits", creditsButton))
		__ = quitButton.mouse_exited.connect(_on_mouse_exited.bind("Quit", quitButton))

# On mouse entered for, change the size of the adjacent Label
func _on_mouse_entered(labelName: String, btn: TextureButton) -> void:
	var label := btn.get_node("../HBoxContainer/%sLabel" % labelName) as Label

	var decorations: Array[Control] = [
		btn.get_node("../HBoxContainer/EllipseL") as Control,
		btn.get_node("../HBoxContainer/StarL") as Control,
		btn.get_node("../HBoxContainer/EllipseR") as Control,
		btn.get_node("../HBoxContainer/StarR") as Control
	]

	if decorations.has(null):
		print("One decoration not found.")
		return

	if label == null:
		print("Label not found.")
		return

	for decoration in decorations:
		decoration.show()

	label.theme_type_variation = "MainMenuLabelHovered";

func _on_mouse_exited(labelName: String, btn: TextureButton) -> void:
	var label := btn.get_node("../HBoxContainer/%sLabel" % labelName) as Label

	var decorations: Array[Control] = [
		btn.get_node("../HBoxContainer/EllipseL") as Control,
		btn.get_node("../HBoxContainer/StarL") as Control,
		btn.get_node("../HBoxContainer/EllipseR") as Control,
		btn.get_node("../HBoxContainer/StarR") as Control
	]

	if decorations.has(null):
		print("One decoration not found.")
		return

	if label == null:
		print("Label not found.")
		return

	for decoration in decorations:
		decoration.hide()

	label.theme_type_variation = "MainMenuLabel";

func _on_play_pressed() -> void:
	print("play")
	pass

func _on_settings_pressed() -> void:
	pass

func _on_credits_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	# TODO: Verify the quit
	get_tree().quit()
