@tool
extends Node
class_name Dialogs

## Shows a confirmation dialog for moving a texture.
## Calls the given callback with (src_path, dest_path, confirmed: bool)
func show_confirm_move(tex_name: String, src_path: String, dest_path: String, callback: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.name = "AutoAssetSorter_MoveConfirmDialog"
	dialog.dialog_text = "Move texture '%s' from:\n%s\nto:\n%s?" % [tex_name, src_path, dest_path]
	dialog.ok_button_text = "Move"
	dialog.cancel_button_text = "Cancel"
	
	var __ := dialog.confirmed.connect(func() -> void:
		callback.call(src_path, dest_path, true)
		dialog.queue_free()
	)
	__ = dialog.canceled.connect(func() -> void:
		callback.call(src_path, dest_path, false)
		dialog.queue_free()
	)
	
	_add_and_popup_dialog(dialog)

## Shows a collision dialog for existing textures.
## Calls the callback with (src_path, dest_dir, action: String) where action is "cancel", "overwrite", or "increment"
func show_collision_dialog(tex_name: String, src_path: String, dest_dir: String, callback: Callable) -> void:
	var dialog := AcceptDialog.new()
	dialog.name = "AutoAssetSorter_CollisionDialog"
	dialog.dialog_text = "Texture '%s' already exists in:\n%s\nWhat would you like to do?" % [tex_name, dest_dir]
	var __ := dialog.add_button("Cancel", true, "cancel")
	__ = dialog.add_button("Overwrite", false, "overwrite")
	__ = dialog.add_button("Increment", false, "increment")
	
	# Handle custom action signals for AcceptDialog
	var ___ := dialog.custom_action.connect(func(action: String) -> void:
		callback.call(src_path, dest_dir, action)
		dialog.queue_free()
	)
	
	_add_and_popup_dialog(dialog)

## Helper to add the dialog to the root viewport and popup centered.
func _add_and_popup_dialog(dialog: Window) -> void:
	var root: Node = get_tree().root
	root.add_child(dialog)
	dialog.popup_centered()