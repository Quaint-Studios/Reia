class_name C_Fireball
extends Component


var start_position: Vector3
var caster: C_CharacterBodyRef
var target: C_Node3DRef
var direction: Vector3
var max_distance: float = 20.0
var traveled_distance: float = 0.0
var speed: float = 20.0
var elapsed: float = 0.0
var parabolic_height: float = 2.5
