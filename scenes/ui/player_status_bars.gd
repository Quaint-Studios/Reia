class_name PlayerStatusBars extends Control

@onready var health_bar: TextureRect = $HealthBar/SVC/SV/Bar
@onready var health_value: RichTextLabel = $HealthBar/Value
const health_start_x = -48
const health_size = Vector2(1246, 177)
@onready var ether_bar: TextureRect = $EtherBar/SVC/SV/Bar
@onready var ether_value: RichTextLabel = $EtherBar/Value
const ether_start_x = -39
const ether_size = Vector2(1231, 164)

const TWEEN_DURATION = 0.12345

func set_health(current_health, max_health):
	var pos_x = health_start_x - (health_size.x - health_size.x * (float(current_health) / float(max_health)))
	var tween = get_tree().create_tween()
	tween.tween_property(health_bar, "position", Vector2(pos_x, health_bar.position.y), TWEEN_DURATION)
	health_value.text = "[center]{c}/{m}".format({ "c": current_health, "m": max_health })

func set_ether(current_ether, max_ether):
	var pos_x = ether_start_x - (ether_size.x - ether_size.x * (float(current_ether) / float(max_ether)))
	var tween = get_tree().create_tween()
	tween.tween_property(ether_bar, "position", Vector2(pos_x, ether_bar.position.y), TWEEN_DURATION)
	ether_value.text = "[center]{c}/{m}".format({ "c": current_ether, "m": max_ether })
