class_name SceneBuilderToolbox

func get_all_node_names(_node):
	var _all_node_names = []
	for _child in _node.get_children():
		_all_node_names.append(_child.name)
		if _child.get_child_count() > 0:
			var _result = get_all_node_names(_child)
			for _item in _result:
				_all_node_names.append(_item)
	return _all_node_names

func increment_name_until_unique(new_name, all_names) -> String:
	if new_name in all_names:
		var backup_name = new_name
		var suffix_counter = 1
		
		var increment_until = true
		while(increment_until):
			var _backup_name = backup_name + "-n" + str(suffix_counter)
			
			if _backup_name in all_names:
				suffix_counter += 1
			else:
				increment_until = false
				backup_name = _backup_name
			
			if suffix_counter > 3000:
				print("suffix_counter is greater than 2000. error?")
				increment_until = false
		
		return backup_name
		
	else:
		return new_name
	
	
