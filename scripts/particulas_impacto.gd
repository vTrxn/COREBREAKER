class_name ParticulasImpacto
extends CPUParticles3D
@onready var luz: OmniLight3D = $LuzImpacto
func _ready() -> void:
	emitting = false
func activar(pos: Vector3, dir_n: Vector3, col: Color = Color(0.15, 1.0, 0.3, 1.0)) -> void:
	global_position = pos
	direction = dir_n
	if mesh and mesh is BoxMesh:
		var m := mesh.duplicate() as BoxMesh
		if m.material is StandardMaterial3D:
			var mat := (m.material as StandardMaterial3D).duplicate() as StandardMaterial3D
			mat.albedo_color = col
			m.material = mat
		mesh = m
	restart()
	emitting = true
	if luz:
		luz.light_color = col
		var tw := create_tween()
		tw.tween_property(luz, "light_energy", 0.0, 0.25)
	var t := get_tree().create_timer(lifetime + 0.1)
	t.timeout.connect(queue_free)