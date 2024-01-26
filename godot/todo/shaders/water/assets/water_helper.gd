extends Node3D

@export var testing := false
@export var size = Vector2(14, 14);
@export var watercam_size = 14;
@export var detail = Vector2(50, 50);


func _ready():
	var _cr = $Simulation/ColorRect
	var _crb = $SimulationBuffer/ColorRect
	var water: MeshInstance3D = $Water

	var sim_tex = $Simulation.get_texture()
	var _col_tex = $Collision.get_texture()

	water.mesh.surface_get_material(0).set_shader_parameter('simulation', sim_tex) # fragment

	water.mesh.size = size;
	water.mesh.subdivide_width = detail.x;
	water.mesh.subdivide_depth = detail.y;

	$Collision/WaterCam.size = watercam_size;

	if testing:
		print("Testing the water shader. You can disable this variable later.")
		get_node("../Tests/Ball/AnimationPlayer").play("bounce")
