class_name ArmaJugador
extends Node3D
signal cambio_municion(actual: int, maxima: int, recargando: bool)
const POS_BASE := Vector3(0.22, -0.22, -0.45)
const MAX_ARR: Array[int] = [8, 4]; const CD_ARR: Array[float] = [0.25, 0.95]
const LUZ_PISTOLA := Color(1.0, 0.72, 0.02); const LUZ_ESCOPETA := Color(0.2, 1.0, 0.25)
@export var escena_bala: PackedScene = preload("res://BalaJugador.tscn")
@export var cd_disparo: float = 0.25; @export var balas_max: int = 8
@onready var cam: Camera3D = get_parent() as Camera3D
@onready var raycast: RayCast3D = get_parent().get_node("RayCast3D") as RayCast3D
@onready var luz: OmniLight3D = get_parent().get_node("LuzDisparo") as OmniLight3D
@onready var audio_disp: AudioStreamPlayer = get_node_or_null("../../AudioDisparo") as AudioStreamPlayer
@onready var audio_esc: AudioStreamPlayer = get_node_or_null("../../AudioEscopeta") as AudioStreamPlayer
@onready var audio_rec: AudioStreamPlayer = get_node_or_null("../../AudioRecarga") as AudioStreamPlayer
@onready var p_body: CharacterBody3D = get_node_or_null("../../") as CharacterBody3D
@onready var modelo_pistola: Node3D = get_node_or_null("Pistola") as Node3D
@onready var modelo_escopeta: Node3D = get_node_or_null("Escopeta") as Node3D
var anim_player: AnimationPlayer = null; var arma_actual: int = 0
var balas_arr: Array[int] = [8, 4]; var balas: int = 8
var recargando: bool = false; var id_recarga: int = 0
var timer_disp: float = 0.0; var t_wobble: float = 0.0; var recoil_z: float = 0.0
func _ready() -> void:
	balas_arr = [MAX_ARR[0], MAX_ARR[1]]
	_aplicar_arma(0)
func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: cambiar_arma(0)
		elif event.keycode == KEY_2: cambiar_arma(1)
		elif event.keycode == KEY_Q: cambiar_arma(1 - arma_actual)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cambiar_arma(1 - arma_actual)
func cambiar_arma(tipo: int) -> void:
	if tipo == arma_actual or tipo < 0 or tipo > 1: return
	if recargando and audio_rec: audio_rec.stop()
	id_recarga += 1; recargando = false; timer_disp = 0.12; recoil_z = 0.04
	if anim_player: anim_player.stop()
	_aplicar_arma(tipo)
func _aplicar_arma(tipo: int) -> void:
	arma_actual = tipo; balas_max = MAX_ARR[tipo]; cd_disparo = CD_ARR[tipo]; balas = balas_arr[tipo]
	if modelo_pistola: modelo_pistola.visible = (tipo == 0)
	if modelo_escopeta: modelo_escopeta.visible = (tipo == 1)
	var activo := modelo_escopeta if tipo == 1 else modelo_pistola
	anim_player = activo.find_child("AnimationPlayer", true, false) as AnimationPlayer if activo else null
	cambio_municion.emit(balas, balas_max, false)
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("recargar") and not recargando and balas < balas_max: recargar()
	var vel_h := Vector2(p_body.velocity.x, p_body.velocity.z).length() if p_body else 0.0
	var en_piso := p_body and p_body.is_on_floor()
	var sprintando := en_piso and vel_h > 5.5; var moviendo := en_piso and vel_h > 0.5
	var freq := 11.0 if sprintando else (8.5 if moviendo else 2.6)
	var amp := 0.015 if sprintando else (0.010 if moviendo else 0.0035)
	t_wobble += delta * freq
	var wx := sin(t_wobble) * amp; var wy := cos(t_wobble * 2.0) * amp * 0.65
	recoil_z = move_toward(recoil_z, 0.0, delta * (0.7 if arma_actual == 1 else 1.5))
	position = Vector3(POS_BASE.x + wx, POS_BASE.y + wy, POS_BASE.z + recoil_z)
	rotation = Vector3(wy * 1.5, -wx * 0.8, -wx * 1.8)
	if luz: luz.light_energy = move_toward(luz.light_energy, 0.0, delta * 30.0)
	if timer_disp > 0.0: timer_disp = maxf(0.0, timer_disp - delta)
func intentar_disparar(p: CharacterBody3D) -> void:
	if recargando or timer_disp > 0.0 or not cam or not escena_bala: return
	if balas <= 0: recargar(); return
	balas -= 1; balas_arr[arma_actual] = balas
	cambio_municion.emit(balas, balas_max, false)
	var es_esc := arma_actual == 1
	timer_disp = cd_disparo; recoil_z = 0.08 if es_esc else 0.03
	if anim_player and anim_player.has_animation("Disparo"): anim_player.stop(); anim_player.play("Disparo", 0.04, 0.72 if es_esc else 1.0)
	if luz: luz.light_color = LUZ_ESCOPETA if es_esc else LUZ_PISTOLA; luz.light_energy = 5.5 if es_esc else 4.0
	var snd := audio_esc if (es_esc and audio_esc) else audio_disp
	if snd: snd.pitch_scale = 1.0; snd.play(0.048 if es_esc else 0.056)
	var pt_mira := cam.global_position - cam.global_transform.basis.z * 25.0
	if raycast:
		raycast.target_position = Vector3(0.0, 0.0, -25.0); raycast.force_raycast_update()
		if raycast.is_colliding(): pt_mira = raycast.get_collision_point()
	var pt_orig := cam.global_position - cam.global_transform.basis.z * 0.4 + cam.global_transform.basis.x * 0.22 - cam.global_transform.basis.y * 0.18
	var dir_base := (pt_mira - pt_orig).normalized()
	var cont := get_tree().current_scene if get_tree().current_scene else get_tree().root
	for i in range(6 if es_esc else 1):
		var d_v := dir_base
		if es_esc:
			var ang := (TAU / 5.0) * float(i) + randf_range(-0.25, 0.25)
			var rad := deg_to_rad(randf_range(0.0, 1.4) if i == 0 else randf_range(2.6, 5.5))
			d_v = (dir_base + cam.global_transform.basis.x * (cos(ang) * tan(rad)) + cam.global_transform.basis.y * (sin(ang) * tan(rad))).normalized()
		var b := escena_bala.instantiate() as BalaJugador
		if es_esc: b.dmg = 16.5
		cont.add_child(b); b.global_position = pt_orig; b.dir = d_v
		b.look_at(pt_orig + d_v, Vector3.RIGHT if absf(d_v.y) > 0.99 else Vector3.UP); b.p = p
	if balas <= 0: recargar()
func recargar() -> void:
	if recargando or balas >= balas_max: return
	recargando = true; id_recarga += 1; var mi_id := id_recarga; var w := arma_actual
	cambio_municion.emit(balas, balas_max, true)
	if anim_player and anim_player.has_animation("Recarga"): anim_player.stop(); anim_player.play("Recarga", 0.06)
	if audio_rec: audio_rec.play()
	await get_tree().create_timer(1.25).timeout
	if not is_inside_tree() or mi_id != id_recarga or arma_actual != w: return
	balas_arr[w] = MAX_ARR[w]; balas = balas_arr[w]; recargando = false
	cambio_municion.emit(balas, balas_max, false)
