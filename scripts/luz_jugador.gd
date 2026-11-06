class_name LuzJugador
extends SpotLight3D
func _ready() -> void:
	position = Vector3(0.0, 1.2, 0.0)
	spot_angle = 15.0
	spot_range = 12.0
	spot_attenuation = 2.0
	light_color = Color(0.95, 0.95, 1.0)