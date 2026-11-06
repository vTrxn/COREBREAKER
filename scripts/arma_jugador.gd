class_name ArmaJugador
extends MeshInstance3D
@export var escena_bala: PackedScene = preload("res://BalaJugador.tscn")
@export var cd_disparo: float = 0.25
@onready var cam: Camera3D = get_parent() as Camera3D
@onready var raycast: RayCast3D = get_parent().get_node("RayCast3D") as RayCast3D
@onready var luz: OmniLight3D = get_parent().get_node("LuzDisparo") as OmniLight3D
@onready var audio_disp: AudioStreamPlayer = get_node("../../AudioDisparo") as AudioStreamPlayer
var timer_disp: float = 0.0
func _process(delta: float) -> void:
	position.z = move_toward(position.z, -0.45, delta * 1.5)
	if luz:
		luz.light_energy = move_toward(luz.light_energy, 0.0, delta * 30.0)
	if timer_disp > 0.0:
		timer_disp = maxf(0.0, timer_disp - delta)
func intentar_disparar(p: CharacterBody3D) -> void:
	if timer_disp > 0.0 or not cam or not escena_bala:
		return
	timer_disp = cd_disparo
	position.z = -0.36
	if luz:
		luz.light_energy = 4.0
	if audio_disp:
		audio_disp.play()
	var b := escena_bala.instantiate() as BalaJugador
	var pt_mira := cam.global_position - cam.global_transform.basis.z * 25.0
	if raycast:
		raycast.target_position = Vector3(0.0, 0.0, -25.0)
		raycast.force_raycast_update()
		if raycast.is_colliding():
			pt_mira = raycast.get_collision_point()
	var pt_origen := cam.global_position - cam.global_transform.basis.z * 0.4 + cam.global_transform.basis.x * 0.22 - cam.global_transform.basis.y * 0.18
	var dir_v := (pt_mira - pt_origen).normalized()
	b.global_position = pt_origen
	b.dir = dir_v
	b.look_at(pt_origen + dir_v, Vector3.UP)
	b.p = p
	get_tree().current_scene.add_child(b)