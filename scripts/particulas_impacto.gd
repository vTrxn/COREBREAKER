class_name ParticulasImpacto
extends CPUParticles3D
@onready var luz: OmniLight3D = $LuzImpacto
func _ready() -> void:
	emitting = false
func activar(pos: Vector3, dir_n: Vector3) -> void:
	global_position = pos
	direction = dir_n
	restart()
	emitting = true
	if luz:
		var tw := create_tween()
		tw.tween_property(luz, "light_energy", 0.0, 0.25)
	var t := get_tree().create_timer(lifetime + 0.1)
	t.timeout.connect(queue_free)