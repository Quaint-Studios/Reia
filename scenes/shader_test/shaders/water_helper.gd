extends Node3D

@export var testing := true

func _ready():
	var _cr = $Simulation/ColorRect
	var _crb = $SimulationBuffer/ColorRect
	var water = $Water
	var sim_tex = $Simulation.get_texture()
	var _col_tex = $Collision.get_texture()

	water.mesh.surface_get_material(0).set_shader_parameter('simulation', sim_tex) # fragment
	water.mesh.surface_get_material(0).set_shader_parameter('v_simulation', sim_tex) # vertex

	if testing:
		print("Testing the water shader. You can disable this variable later.")
		get_node("../Tests/Ball/AnimationPlayer").play("bounce")
