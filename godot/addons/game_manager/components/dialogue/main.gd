@tool
extends Node

@onready var graph: GraphEdit = $"GraphEdit" as GraphEdit

func _ready() -> void:
	var node := GraphNode.new()
	graph.add_child(node)
	node.position_offset.x = get_viewport().get_mouse_position().x
