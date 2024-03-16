class_name NodeEXT

static func clear_children(node: Node):
	for child in node.get_children():
		child.queue_free()
