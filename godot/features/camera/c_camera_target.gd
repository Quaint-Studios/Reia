class_name C_CameraTarget
extends Component

enum Mode {
	FOLLOW,
	FREE,
	CINEMATIC
}

var target_entity: Entity = null
var mode: Mode = Mode.FOLLOW
var params: Dictionary = {}
