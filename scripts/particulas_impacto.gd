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
static func estallar(origen: Node3D, col: Color, escala: float = 1.6) -> void:
	if not origen or not origen.is_inside_tree(): return
	var esc := load("res://ParticulasImpacto.tscn") as PackedScene
	if not esc: return
	var p := esc.instantiate() as ParticulasImpacto
	var cont := origen.get_tree().current_scene if origen.get_tree().current_scene else origen.get_parent()
	if not cont: p.queue_free(); return
	cont.add_child(p); p.scale = Vector3.ONE * escala; p.amount = 30
	p.activar(origen.global_position + Vector3.UP * 0.85, Vector3.UP, col)
	if p.luz: p.luz.light_energy = 5.5
static func flash_malla(modelo: Node3D, col: Color = Color(1.0, 1.0, 1.0, 1.0), dur: float = 0.065) -> void:
	if not modelo or not modelo.is_inside_tree(): return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_color = col
	var id := int(modelo.get_meta("_fid", 0)) + 1; modelo.set_meta("_fid", id)
	var mallas := modelo.find_children("*", "MeshInstance3D", true, false)
	for m in mallas: (m as MeshInstance3D).material_override = mat
	await modelo.get_tree().create_timer(dur).timeout
	if is_instance_valid(modelo) and int(modelo.get_meta("_fid", 0)) == id:
		for m in mallas:
			if is_instance_valid(m): (m as MeshInstance3D).material_override = null
static func morir_enemigo(enemigo: Node3D, col: Color, player: Node, audio: AudioStreamPlayer3D) -> void:
	estallar(enemigo, col, 1.6)
	if player and player.has_method("ganar_xp"): player.ganar_xp()
	if audio and enemigo.get_parent():
		enemigo.remove_child(audio); enemigo.get_parent().add_child(audio)
		audio.global_position = enemigo.global_position; audio.finished.connect(audio.queue_free)
	enemigo.queue_free()
static func iniciar_spawn(enemigo: Node3D, modelo: Node3D, col: Color, on_fin: Callable) -> void:
	if not modelo: on_fin.call(); return
	modelo.scale = Vector3(0.05, 0.05, 0.05)
	var luz := OmniLight3D.new()
	luz.position = Vector3(0.0, 0.8, 0.0); luz.light_color = col; luz.light_energy = 2.5; luz.omni_range = 3.5
	enemigo.add_child(luz)
	var tw := enemigo.create_tween().set_parallel(true)
	tw.tween_property(modelo, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(luz, "light_energy", 0.0, 1.0)
	var cb := func():
		on_fin.call()
		if is_instance_valid(luz): luz.queue_free()
	tw.chain().tween_callback(cb)