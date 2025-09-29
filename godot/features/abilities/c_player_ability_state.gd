class_name C_PlayerAbilityState
extends Component

const ABILITY_COUNT: int = 2

var cooldowns: PackedFloat32Array = PackedFloat32Array([0.0, 0.0])
var queued_ability: int = -1
var last_cast_times: PackedFloat32Array = PackedFloat32Array([0.0, 0.0])
