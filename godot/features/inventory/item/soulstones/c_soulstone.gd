class_name C_Soulstone
extends Component

@export var size: int = 2 # 2..4 (determines stat slots)

## Store stat lines in a data-driven way.
## Example entry: { "id": "atk_pct", "value": 0.12 }
@export var stats: Array[Dictionary] = []

## Optional set bonus "stat" (not counted as normal stat)
@export var set_bonus_id: int = -1 # empty = none
