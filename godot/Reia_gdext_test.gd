
extends Node3D

# var client := SustenetClient.new()
# var cluster := SustenetCluster.new()

func _ready() -> void:
	# client.on_connected.connect(_on_connected)
	# client.on_disconnected.connect(_on_disconnected)
	# client.on_timeout.connect(_on_timeout)

	# # Maybe a SustenetMaster call for single-PC servers?
	# client.connect("")
	pass

func _on_connected(conn: String) -> void:
	print("Connected to %s", [conn])

func _on_disconnected(conn: String) -> void:
	print("Disconnected %s", [conn])

func _on_timeout(conn: String) -> void:
	print("Timed out while connecting to %s", [conn])