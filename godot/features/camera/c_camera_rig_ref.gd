class_name C_CameraRigRef
extends Component

@export var root_path: NodePath
@export var yaw_pivot_path: NodePath
@export var pitch_pivot_path: NodePath
@export var spring_arm_path: NodePath
@export var camera_path: NodePath

var root: Node3D
var yaw: Node3D
var pitch: Node3D
var spring: SpringArm3D
var camera: Camera3D
