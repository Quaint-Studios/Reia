extends Node3D

var cluster := SustenetCluster.new()

func _ready() -> void:
	# Maybe a SustenetMaster call for single-PC servers?
	cluster.start_server()
	await get_tree().create_timer(5.0).timeout
	print("Ended")
