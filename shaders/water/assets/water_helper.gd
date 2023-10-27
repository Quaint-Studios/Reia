extends Node3D

@export var testing := false
@export var size = Vector2(14, 14);
@export var detail = Vector2(50, 50);

func _ready():
	var _cr = $Simulation/ColorRect
	var _crb = $SimulationBuffer/ColorRect
	var water: MeshInstance3D = $Water
	var water_mesh: PlaneMesh = water.mesh as PlaneMesh;
	water_mesh.size = size;
	water_mesh.subdivide_width = detail.x;
	water_mesh.subdivide_depth = detail.y;

	var sim_tex = $Simulation.get_texture()
	var _col_tex = $Collision.get_texture()

	water.mesh.surface_get_material(0).set_shader_parameter('simulation', sim_tex) # fragment

	if testing:
		print("Testing the water shader. You can disable this variable later.")
		get_node("../Tests/Ball/AnimationPlayer").play("bounce")
