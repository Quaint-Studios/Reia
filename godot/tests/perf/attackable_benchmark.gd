extends Node3D
##
## AABB logic-only benchmark (20 Hz default) for very large counts (1k .. 100k).
## Pure data (Structure of Arrays) + optional MultiMesh visualization + simple slope.

@export var count: int = 1000 # Try 1_000 / 10_000 / 100_000
@export var rng_seed: int = 1337
@export var cube_size: Vector3 = Vector3.ONE
@export var logic_hz: int = 20
@export var area_extents: Vector3 = Vector3(100, 0, 100) # Spawn rectangle XZ
@export var change_dir_min: float = 0.6
@export var change_dir_max: float = 2.0
@export var speed_min: float = 2.0
@export var speed_max: float = 6.0
@export var enable_overlap_query: bool = false
@export var query_aabb_size: Vector3 = Vector3(20, 2, 20)

# Visual toggles
@export var show_visuals: bool = true
@export var update_visuals_every_ticks: int = 1 # Increase (e.g. 2–4) to reduce visual update cost.

# Slope parameters (linear ramp along Z from z_start->z_end rising to slope_height)
@export var slope_z_start: float = -20.0
@export var slope_z_end: float = 20.0
@export var slope_height: float = 5.0
@export var slope_width: float = 200.0 # Total width in X across the slope

@onready var _fps_label: Label = null

# Fixed-step accumulator
var _logic_dt: float = 1.0 / 20.0
var _logic_accum: float = 0.0
var _tick_index: int = 0

# Data arrays (SoA)
var _pos: PackedVector3Array
var _vel: PackedVector3Array
var _change_t: PackedFloat32Array
var _rng := RandomNumberGenerator.new()

# Precomputed
var _half: Vector3
var _inv_slope_len: float = 0.0

# Stats
var _last_overlap_count: int = 0

# Visual MultiMesh
var _mm_instance: MultiMeshInstance3D
var _mm: MultiMesh

@export var query_ignore_y: bool = true
@export var query_auto_every_ticks: int = 4

func _ready() -> void:
	_logic_dt = 1.0 / maxf(1, logic_hz)
	_rng.seed = rng_seed
	_half = cube_size * 0.5
	var slope_len := slope_z_end - slope_z_start
	_inv_slope_len = 1.0 / slope_len if slope_len != 0.0 else 0.0
	_init_arrays()
	_add_fps_label()
	if show_visuals:
		_create_floor()
		_create_slope()
		_create_multimesh()
		_create_camera()
		_create_light()
	if enable_overlap_query:
		_last_overlap_count = _overlap_query()

func _init_arrays() -> void:
	var __ := _pos.resize(count)
	__ = _vel.resize(count)
	__ = _change_t.resize(count)
	for i in count:
		var px := _rng.randf_range(-area_extents.x, area_extents.x)
		var pz := _rng.randf_range(-area_extents.z, area_extents.z)
		var base_pos := Vector3(px, 0.0, pz)
		var y := _sample_ground_height(pz)
		_pos[i] = Vector3(base_pos.x, y + _half.y, base_pos.z)
		_reset_direction(i)

func _reset_direction(i: int) -> void:
	var ang := _rng.randf_range(0.0, TAU)
	var spd := _rng.randf_range(speed_min, speed_max)
	var dir := Vector3(cos(ang), 0.0, sin(ang))
	_vel[i] = dir * spd
	_change_t[i] = _rng.randf_range(change_dir_min, change_dir_max)

func _physics_process(delta: float) -> void:
	_logic_accum += delta
	# Clamp catch-up
	if _logic_accum > _logic_dt * 4.0:
		_logic_accum = _logic_dt * 4.0
	var did_visual_update: bool = false
	while _logic_accum >= _logic_dt:
		_logic_accum -= _logic_dt
		_tick_index += 1
		_step_logic(_logic_dt)
		if enable_overlap_query:
			if query_auto_every_ticks == 0 or (_tick_index % query_auto_every_ticks) == 0:
				_last_overlap_count = _overlap_query()
		if show_visuals and (_tick_index % max(1, update_visuals_every_ticks) == 0):
			_update_multimesh()
			did_visual_update = true
	# TODO: if no logic step happened this physics frame but visuals never updated yet and interpolation were desired, handle here (not needed now).
	if show_visuals and not did_visual_update and update_visuals_every_ticks > 1:
		# Skipped to save cost; uncomment to force update:
		# _update_multimesh()
		pass

func _step_logic(dt: float) -> void:
	for i in count:
		var t := _change_t[i] - dt
		if t <= 0.0:
			_reset_direction(i)
			t = _change_t[i]
		else:
			_change_t[i] = t
		var p := _pos[i]
		p += _vel[i] * dt
		# Re-sample ground height (only Y changes due to slope)
		p.y = _sample_ground_height(p.z) + _half.y
		_pos[i] = p

func _sample_ground_height(z: float) -> float:
	# Linear ramp between z_start and z_end
	if z <= slope_z_start:
		return 0.0
	if z >= slope_z_end:
		return slope_height
	var frac := (z - slope_z_start) * _inv_slope_len
	return slope_height * frac

func _overlap_query() -> int:
	# Expand Y automatically to cover slope if we care about Y; otherwise keep a small band.
	var qx := query_aabb_size.x
	var qz := query_aabb_size.z
	var qy := (slope_height + cube_size.y * 2.0) if not query_ignore_y else query_aabb_size.y
	var query := AABB(
		Vector3(-qx * 0.5, -qy * 0.5, -qz * 0.5),
		Vector3(qx, qy, qz)
	)
	var hits := 0
	var minp := query.position
	var maxp := minp + query.size
	# Strict > / < was excluding boundary centers; change to >= / <= for intuitive inclusion.
	for i in count:
		var p := _pos[i]
		if p.x >= minp.x and p.x <= maxp.x and p.z >= minp.z and p.z <= maxp.z:
			if query_ignore_y or (p.y >= minp.y and p.y <= maxp.y):
				hits += 1
	return hits

func _create_floor() -> void:
	var my_floor := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(area_extents.x * 2.0, 1.0, area_extents.z * 2.0)
	my_floor.mesh = mesh
	my_floor.position = Vector3(0.0, -0.5, 0.0)
	add_child(my_floor)

func _create_slope() -> void:
	# Procedural 4-vertex ramp (quad) using ArrayMesh
	var slope := MeshInstance3D.new()
	var arr_mesh := ArrayMesh.new()
	var arrays: Array = []
	var __ := arrays.resize(Mesh.ARRAY_MAX)
	var z0 := slope_z_start
	var z1 := slope_z_end
	var y0 := 0.0
	var y1 := slope_height
	var w := slope_width * 0.5
	var verts := PackedVector3Array()
	# Order: two triangles (counter-clockwise)
	__ = verts.append(Vector3(-w, y0, z0))
	__ = verts.append(Vector3(w, y0, z0))
	__ = verts.append(Vector3(w, y1, z1))
	__ = verts.append(Vector3(-w, y1, z1))
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	var normals := PackedVector3Array()
	# Compute face normals (same for both triangles since it's a plane)
	var edge1 := verts[1] - verts[0]
	var edge2 := verts[2] - verts[0]
	var n := edge1.cross(edge2).normalized()
	for _i in 4:
		__ = normals.append(n)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	slope.mesh = arr_mesh
	add_child(slope)

func _create_multimesh() -> void:
	_mm_instance = MultiMeshInstance3D.new()
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = cube_size
	_mm.mesh = box
	_mm.instance_count = count
	_mm_instance.multimesh = _mm
	add_child(_mm_instance)
	_update_multimesh()

func _create_camera() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 80, 120)
	add_child(cam)
	cam.look_at(Vector3(0, 0, 0), Vector3.UP)

func _create_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.light_energy = 2.0
	sun.rotation_degrees = Vector3(25, 65, 0)
	add_child(sun)

func _update_multimesh() -> void:
	if _mm == null:
		return
	for i in count:
		var p := _pos[i]
		var xf := Transform3D(Basis(), p)
		_mm.set_instance_transform(i, xf)

func _add_fps_label() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_fps_label = Label.new()
	_fps_label.text = "FPS: ..."
	_fps_label.position = Vector2(12, 12)
	_fps_label.add_theme_color_override("font_color", Color.YELLOW)
	_fps_label.add_theme_font_size_override("font_size", 22)
	layer.add_child(_fps_label)

func _process(_delta: float) -> void:
	if _fps_label:
		_fps_label.text = "FPS: %d  Entities: %d  Overlap: %d" % [
			Engine.get_frames_per_second(),
			count,
			_last_overlap_count
		]
