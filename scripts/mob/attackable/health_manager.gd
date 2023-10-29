class_name HealthManager extends Node3D

@onready var health_bar: TextureRect = $SubViewport/HealthBar/SVC/SV/Bar
@onready var health_value: RichTextLabel = $SubViewport/HealthBar/Value
const health_start_x = -48
const health_size = Vector2(1246, 177)

const TWEEN_DURATION = 0.12345

func set_health(current_health, max_health):
	var pos_x = health_start_x - (health_size.x - health_size.x * (float(current_health) / float(max_health)))
	var tween = get_tree().create_tween()
	tween.tween_property(health_bar, "position", Vector2(pos_x, health_bar.position.y), TWEEN_DURATION)
	health_value.text = "[center]{c}/{m}".format({ "c": current_health, "m": max_health })
