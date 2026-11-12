class_name ArmaJugador
extends Node3D
signal cambio_municion(actual: int, maxima: int, recargando: bool)
const POS_BASE := Vector3(0.22, -0.22, -0.45)
@export var escena_bala: PackedScene = preload("res://BalaJugador.tscn")
@export var cd_disparo: float = 0.25
@export var balas_max: int = 8
@onready var cam: Camera3D = get_parent() as Camera3D
@onready var raycast: RayCast3D = get_parent().get_node("RayCast3D") as RayCast3D
@onready var luz: OmniLight3D = get_parent().get_node("LuzDisparo") as OmniLight3D
@onready var audio_disp: AudioStreamPlayer = get_node_or_null("../../AudioDisparo") as AudioStreamPlayer
@onready var audio_rec: AudioStreamPlayer = get_node_or_null("../../AudioRecarga") as AudioStreamPlayer
@onready var p_body: CharacterBody3D = get_node_or_null("../../") as CharacterBody3D
@onready var modelo_pistola: Node3D = get_node_or_null("Pistola") as Node3D
var anim_player: AnimationPlayer = null
var balas: int = 8
var recargando: bool = false
var timer_disp: float = 0.0
var t_wobble: float = 0.0
var recoil_z: float = 0.0
func _ready() -> void:
	balas = balas_max
	if modelo_pistola:
		anim_player = modelo_pistola.find_child("AnimationPlayer", true, false) as AnimationPlayer
	cambio_municion.emit(balas, balas_max, false)
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("recargar") and not recargando and balas < balas_max:
		recargar()
	var vel_h := Vector2(p_body.velocity.x, p_body.velocity.z).length() if p_body else 0.0
	var en_piso := p_body and p_body.is_on_floor()
	var moviendo := en_piso and vel_h > 0.5
	var sprintando := en_piso and vel_h > 5.5
	var freq := 11.0 if sprintando else (8.5 if moviendo else 2.6)
	var amp := 0.015 if sprintando else (0.010 if moviendo else 0.0035)
	t_wobble += delta * freq
	var wx := sin(t_wobble) * amp
	var wy := cos(t_wobble * 2.0) * amp * 0.65
	recoil_z = move_toward(recoil_z, 0.0, delta * 1.5)
	position = Vector3(POS_BASE.x + wx, POS_BASE.y + wy, POS_BASE.z + recoil_z)
	rotation.z = -wx * 1.8
	rotation.x = wy * 1.5
	rotation.y = -wx * 0.8
	if luz:
		luz.light_energy = move_toward(luz.light_energy, 0.0, delta * 30.0)
	if timer_disp > 0.0:
		timer_disp = maxf(0.0, timer_disp - delta)
func intentar_disparar(p: CharacterBody3D) -> void:
	if recargando or timer_disp > 0.0 or not cam or not escena_bala:
		return
	if balas <= 0:
		recargar()
		return
	balas -= 1
	cambio_municion.emit(balas, balas_max, false)
	timer_disp = cd_disparo
	recoil_z = 0.03
	if anim_player and anim_player.has_animation("Disparo"):
		anim_player.stop()
		anim_player.play("Disparo", 0.04)
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
	var cont := get_tree().current_scene if get_tree().current_scene else get_tree().root
	cont.add_child(b)
	b.global_position = pt_origen
	b.dir = dir_v
	b.look_at(pt_origen + dir_v, Vector3.UP)
	b.p = p
	if balas <= 0:
		recargar()
func recargar() -> void:
	if recargando or balas >= balas_max:
		return
	recargando = true
	cambio_municion.emit(balas, balas_max, true)
	if anim_player and anim_player.has_animation("Recarga"):
		anim_player.stop()
		anim_player.play("Recarga", 0.06)
	if audio_rec:
		audio_rec.play()
	var t := get_tree().create_timer(1.25)
	await t.timeout
	balas = balas_max
	recargando = false
	cambio_municion.emit(balas, balas_max, false)
