@tool
extends GraphNode


signal modified
signal run_requested

@onready var ID = $HBoxContainer/ID
@onready var start_id : String = ID.text
@onready var timer = $Timer

var undo_redo : EditorUndoRedoManager


func _to_dict(graph : GraphEdit):
	var dict = {}
	var connections = graph.get_connections(name)
	
	dict['start_id'] = start_id
	dict['link'] = connections[0]['to_node'] if connections.size() > 0 else 'END'
	
	return dict


func _from_dict(dict : Dictionary):
	start_id = dict['start_id']
	ID.text = start_id
	return [dict['link']]


## convert graph/tree from this node to data
func tree_to_data(graph : GraphEdit, data := DialogueData.new(), node : GraphNode = self):
	var next_nodes = graph.get_connections(node.name)
	
	# setup
	if node == self:
		if start_id == '':
			return data
		elif next_nodes.size() == 0:
			printerr(title, ' is not connected!')
			return data
		data.starts[start_id] = name
	
	# add data for current node
	data.nodes[node.name] = node._to_dict(graph)
	data.nodes[node.name]['offset'] = node.position_offset
	
	# add data for next nodes
	for next_node in next_nodes:
		# if node already defined in data
		if data.nodes.has(next_node['to_node']):
			continue
		# get data from node
		data = tree_to_data(graph, data, graph.get_node(NodePath(next_node['to_node'])))
	
	return data


## create tree on this node from the given data
func data_to_tree(graph : GraphEdit, data : DialogueData, node_name := name):
	var next_nodes = []
	
	# setup and end
	if node_name == name:
		next_nodes = _from_dict(data.nodes[node_name])
		graph.request_node = node_name
		graph.request_port = 0
	elif node_name == 'END':
		graph.request_node = ''
		graph.request_port = -1
		return
	elif not graph.has_node(NodePath(node_name)):
		var type = int(node_name.split('_')[0])
		var offset = data.nodes[node_name]['offset']
		var node = graph.add_node(type, node_name, offset)
		next_nodes = node._from_dict(data.nodes[node_name])
	elif graph.has_node(NodePath(node_name)) and graph.request_port > -1:
		graph.connect_node(graph.request_node, graph.request_port, node_name, 0)
	
	for i in range(next_nodes.size()):
		graph.request_node = node_name
		graph.request_port = i
		data_to_tree(graph, data, next_nodes[i])


func set_ID(new_id : String):
	start_id = new_id
	if ID.text != start_id:
		ID.text = start_id


func _on_ID_changed(_id):
	timer.stop()
	timer.start()


func _on_timer_timeout():
	if not undo_redo:
		start_id = ID.text
		return
	
	undo_redo.create_action('Set start ID')
	undo_redo.add_do_method(self, 'set_ID', ID.text)
	undo_redo.add_do_method(self, '_on_modified')
	undo_redo.add_undo_method(self, '_on_modified')
	undo_redo.add_undo_method(self, 'set_ID', start_id)
	undo_redo.commit_action()


func _on_run_pressed():
	if start_id != '':
		run_requested.emit()
	else:
		printerr(title, ' has no start_id!')


func _on_modified():
	modified.emit()
