@tool
class_name OverlayMountManager
extends RefCounted

## Manages finding the Godot 3D editor viewport control, mounting MapViewportOverlay,
## and clean teardown without lingering editor nodes.

var _viewport_overlay: MapViewportOverlay = null
var _addon_path: String = ""


func _init(addon_path: String) -> void:
	_addon_path = addon_path


## Mounts the overlay to the 3D viewport control.
func mount(context: MapEditorContext, state_bus: MapEditorStateBus) -> void:
	var vp_control: Control = find_3d_viewport_control()
	if vp_control == null:
		# Viewport control may not be ready during initial editor load; retry deferred
		mount.call_deferred(context, state_bus)
		return

	cleanup_lingering_nodes()

	_viewport_overlay = MapViewportOverlay.new()
	_viewport_overlay.setup(context, state_bus, _addon_path)
	vp_control.add_child(_viewport_overlay)


## Locates the 3D SubViewport's parent Control inside Godot's EditorInterface.
static func find_3d_viewport_control() -> Control:
	var vp: SubViewport = EditorInterface.get_editor_viewport_3d(0)
	if vp == null:
		return null
	var parent: Node = vp.get_parent()
	if parent == null:
		return null
	if parent.get_parent() is Control:
		return parent.get_parent() as Control
	if parent is Control:
		return parent as Control
	return null


## Cleans up any previously orphaned or lingering overlay controls.
static func cleanup_lingering_nodes() -> void:
	var vp_control: Control = find_3d_viewport_control()
	if vp_control != null:
		var lingering: Node = vp_control.get_node_or_null("MapEditorViewportOverlay")
		if lingering != null:
			vp_control.remove_child(lingering)
			lingering.queue_free()


## Returns the active viewport overlay instance.
func get_overlay() -> MapViewportOverlay:
	return _viewport_overlay


## Tears down and frees the overlay.
func teardown() -> void:
	if _viewport_overlay != null:
		if _viewport_overlay.get_parent() != null:
			_viewport_overlay.get_parent().remove_child(_viewport_overlay)
		_viewport_overlay.queue_free()
		_viewport_overlay = null
	cleanup_lingering_nodes()
