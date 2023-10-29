class_name GameUI extends Control

static var instance: GameUI

func _init():
	if instance == null:
		instance = self
	else:
		self.queue_free()

####
#### Externals
######## Description: Things that can one day be broken up into other scripts.
####

class StatusBars extends Node:
	var parent: Control

	var health_bar: TextureRect; var health_value: RichTextLabel;
	const health_start_x = -48
	const health_size = Vector2(1246, 177)
	var ether_bar: TextureRect; var ether_value: RichTextLabel;
	const ether_start_x = -39
	const ether_size = Vector2(1231, 164)

	const TWEEN_DURATION = 0.12345

	func _init(_parent: Control, _health_bar: TextureRect, _health_value: RichTextLabel, _ether_bar: TextureRect, _ether_value: RichTextLabel):
		parent = _parent
		health_bar = _health_bar
		health_value = _health_value
		ether_bar = _ether_bar
		ether_value = _ether_value

	func set_health(current_health, max_health):
		var pos_x = health_start_x - (health_size.x - health_size.x * (float(current_health) / float(max_health)))
		var tween = parent.get_tree().create_tween()
		tween.tween_property(health_bar, "position", Vector2(pos_x, health_bar.position.y), TWEEN_DURATION)
		health_value.text = "[center]{c}/{m}".format({ "c": current_health, "m": max_health })

	func set_ether(current_ether, max_ether):
		var pos_x = ether_start_x - (ether_size.x - ether_size.x * (float(current_ether) / float(max_ether)))
		var tween = parent.get_tree().create_tween()
		tween.tween_property(ether_bar, "position", Vector2(pos_x, ether_bar.position.y), TWEEN_DURATION)
		ether_value.text = "[center]{c}/{m}".format({ "c": current_ether, "m": max_ether })

@onready var status_bars: StatusBars = StatusBars.new(
	self,
	$HealthBar/SVC/SV/Bar,
	$HealthBar/Value,
	$EtherBar/SVC/SV/Bar,
	$EtherBar/Value,
)
