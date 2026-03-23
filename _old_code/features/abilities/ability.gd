@abstract class_name Ability extends Resource

@export var is_targetable := true

@export var name := ""
@export var description := ""

@export var cooldown := 0.0
@export var skill_power := 1.0
@export var multiplier := 1.0
@export var distance := 15.0
@export var aoe := 0.0

@export var cost := 1
@export var cost_type := Enums.Resource_Type.ETHER
@export var mastery := 0.0 # out of 100%, how much it drains you

@export var element: Enums.Element_Affinity

## Base calculation: ceili(power + skill_power)
@abstract func get_power(power: int) -> int
@abstract func execute(caster: Entity, target: Entity) -> void
