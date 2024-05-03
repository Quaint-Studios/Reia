@icon("res://addons/dialogue_nodes/icons/Dialogue.svg")
extends Resource
## Data for DialogueBox node
class_name DialogueData

@export var starts : Dictionary = {}
@export var nodes : Dictionary = {}
@export var variables : Dictionary = {}
@export var strays : Array[String] = []
## Path to the [CharacterList] resource file.
@export var characters = ''
