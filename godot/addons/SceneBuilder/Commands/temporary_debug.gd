@tool
extends EditorPlugin

func execute():
	var editor : EditorInterface = get_editor_interface()
	var base = editor.get_base_control()
	
	
	var main_screen : VBoxContainer = base.get_child(0).get_child(1).get_child(1).get_child(1).get_child(0).get_child(0).get_child(0).get_child(0).get_child(1).get_child(0)
	if main_screen:
		var btn_use_local_space : Button = main_screen.get_child(1).get_child(0).get_child(0).get_child(0).get_child(12)
		if btn_use_local_space:
			print("use_local_space.button_pressed: ", btn_use_local_space.button_pressed)
		else:
			printerr("Unable to find use local space button")
	else:
		printerr("Unable to find main screen")
		
	

	
	
