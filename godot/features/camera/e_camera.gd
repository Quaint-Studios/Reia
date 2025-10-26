class_name Camera
extends Entity

func define_components() -> Array:
	return [
		C_Camera.new(),
		# C_CameraRigRef, # The scene instance will have this component
		C_CameraOrbit.new(),
		C_CameraKinematics.new(),
		C_CameraMode.new(),
		C_CameraCollision.new()
	]
