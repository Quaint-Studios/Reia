@tool
class_name GameManager__Core extends Control

signal reload_plugin

var undo_redo: EditorUndoRedoManager

@onready var toolbar: GameManager__Toolbar = $"Main/Toolbar" as GameManager__Toolbar
@onready var workspace: GameManager__Workspace = $"Main/Workspace" as GameManager__Workspace

@export_group("Scenes")
@export var character_scene: PackedScene
@export var dialogue_scene: PackedScene
@export var quest_scene: PackedScene
@export var settings_scene: PackedScene

enum State {CHARACTER, DIALOGUE, QUEST, SETTINGS}
var state: State = State.CHARACTER

func _ready() -> void:
	var __ := toolbar.reload_button.connect("pressed", _on_reload_pressed)
	__ = toolbar.character.connect("pressed", _on_character_pressed)
	__ = toolbar.dialogue.connect("pressed", _on_dialogue_pressed)
	__ = toolbar.quest.connect("pressed", _on_quest_pressed)
	__ = toolbar.settings.connect("pressed", _on_settings_pressed)

	update_workspace_layout()

func _on_reload_pressed() -> void:
	reload_plugin.emit()

func _on_character_pressed() -> void:
	if state == State.CHARACTER: return # already selected
	state = State.CHARACTER
	update_workspace_layout()

func _on_dialogue_pressed() -> void:
	if state == State.DIALOGUE: return # already selected
	state = State.DIALOGUE
	update_workspace_layout()

func _on_quest_pressed() -> void:
	if state == State.QUEST: return # already selected
	state = State.QUEST
	update_workspace_layout()

func _on_settings_pressed() -> void:
	if state == State.SETTINGS: return # already selected
	state = State.SETTINGS
	update_workspace_layout()

func update_workspace_layout() -> void:
	clear_workspace_layout()

	match state:
		State.CHARACTER:
			workspace.layout.add_child(character_scene.instantiate())
		State.DIALOGUE:
			workspace.layout.add_child(dialogue_scene.instantiate())
		State.QUEST:
			workspace.layout.add_child(quest_scene.instantiate())
		State.SETTINGS:
			workspace.layout.add_child(settings_scene.instantiate())

func clear_workspace_layout() -> void:
	for child in workspace.layout.get_children():
		child.queue_free()
