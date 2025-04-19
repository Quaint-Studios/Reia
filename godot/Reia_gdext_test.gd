extends Node3D

var cluster := SustenetCluster.new()

func _ready() -> void:
	# Maybe a SustenetMaster call for single-PC servers?
	cluster.start()
