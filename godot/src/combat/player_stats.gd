class_name PlayerStats extends PlayerBaseStats

const HUMAN_SPIRIT = -1

@export_category("Player Stats")
@export var human : HumanStats = HumanStats.new()
@export var spirits : Array[SpiritStats] = [ SpiritStats.new() ]
@export var current_spirit := HUMAN_SPIRIT

func swap(prev: PlayerBaseStats, next: PlayerBaseStats) -> void:
	# TODO: Blend the health/max health, ether/max ether, and other values.
	var new_health := ceili(next.max_health * (float(prev.health) / prev.max_health))
	new_health = clampi(new_health, 0, next.max_health)
	next.health = new_health

	var new_ether := ceili(next.max_ether * (float(prev.ether) / prev.max_ether))
	new_ether = clampi(new_ether, 0, next.max_ether)
	next.ether = new_ether

	if next != HumanStats:
		human.combat_mode = (next as SpiritStats).weapon_stats.weapon_type # Swap the human form to match the spirit's type
	pass

func get_current_spirit() -> PlayerBaseStats:
	if current_spirit < 0:
		return human # Out of bounds so get the human form.

	if spirits.size() > current_spirit:
		return spirits[current_spirit]

	return human # Out of bounds so get the human form.

func get_power() -> int:
	var power := human.get_power()
	if current_spirit == HUMAN_SPIRIT:
		return power

	var spirit := get_current_spirit()

	if spirit is HumanStats:
		return power

	return power + spirit.get_power()

func get_defense(weapon_type: Enums.Weapon_Type) -> int:
	var defense := human.get_defense(weapon_type)
	if current_spirit == HUMAN_SPIRIT:
		return defense

	var spirit := get_current_spirit()

	if spirit is HumanStats:
		return defense

	return defense + spirit.get_defense(weapon_type)
