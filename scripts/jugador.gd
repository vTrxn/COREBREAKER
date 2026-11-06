class_name Jugador
extends CharacterBody3D
signal cambio_salud(actual: float, maxima: float)
signal alerta_sangrado(activo: bool)
signal cambio_xp(actual: float, maxima: float, lvl: int)
@export var hp_max: float = 100.0
@export var vel_caminar: float = 4.5
@export var vel_sprint: float = 6.0
@export var fuerza_salto: float = 6.5
@export var grav: float = 14.0
@export var mouse_sens: float = 0.002
@export var cam: Camera3D
@export var col_shape: CollisionShape3D
@export var raycast: RayCast3D
@export var sis_eventos: SistemaEventos
@export var arma: MeshInstance3D
@export var luz_disparo: OmniLight3D
@export var escena_bala: PackedScene = preload("res://BalaJugador.tscn")
@export var audio_disparo: AudioStreamPlayer
@export var audio_salto: AudioStreamPlayer
@export var audio_dash: AudioStreamPlayer
@export var audio_pasos: AudioStreamPlayer
@export var audio_respiracion: AudioStreamPlayer
var hp: float = 100.0
var t_quieto: float = 0.0
var en_slide: bool = false
var t_slide: float = 0.0
var dir_slide: Vector3 = Vector3.ZERO
var cd_dash: float = 0.0
var timer_disparo: float = 0.0
var nivel: int = 1
var xp: float = 0.0
var xp_max: float = 100.0
func _ready() -> void:
	add_to_group("jugador")
	collision_layer = 8
	collision_mask = 1 | 2
	hp = hp_max
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not cam:
		cam = find_child("Camera3D") as Camera3D
	if not col_shape:
		col_shape = find_child("CollisionShape3D") as CollisionShape3D
	if not raycast:
		raycast = find_child("RayCast3D") as RayCast3D
	if not sis_eventos:
		sis_eventos = get_tree().get_first_node_in_group("sistema_eventos") as SistemaEventos
	if not arma and cam:
		arma = cam.find_child("Arma") as MeshInstance3D
	if not luz_disparo and cam:
		luz_disparo = cam.find_child("LuzDisparo") as OmniLight3D
	if not audio_disparo:
		audio_disparo = find_child("AudioDisparo") as AudioStreamPlayer
	if not audio_salto:
		audio_salto = find_child("AudioSalto") as AudioStreamPlayer
	if not audio_dash:
		audio_dash = find_child("AudioDash") as AudioStreamPlayer
	if not audio_pasos:
		audio_pasos = find_child("AudioPasos") as AudioStreamPlayer
	if not audio_respiracion:
		audio_respiracion = find_child("AudioRespiracion") as AudioStreamPlayer
	if audio_pasos:
		if audio_pasos.stream is AudioStreamMP3:
			(audio_pasos.stream as AudioStreamMP3).loop = true
		audio_pasos.finished.connect(_on_audio_pasos_finished)
	if audio_respiracion:
		if audio_respiracion.stream is AudioStreamMP3:
			(audio_respiracion.stream as AudioStreamMP3).loop = true
		audio_respiracion.finished.connect(_on_audio_respiracion_finished)
	cambio_xp.emit(xp, xp_max, nivel)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		if cam:
			cam.rotate_x(-event.relative.y * mouse_sens)
			cam.rotation.x = clampf(cam.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= grav * delta
	t_quieto += delta
	var sangrando := t_quieto > 15.0
	alerta_sangrado.emit(sangrando)
	if sangrando:
		hp = maxf(0.0, hp - 2.0 * delta)
		cambio_salud.emit(hp, hp_max)
	_procesar_audio_salud()
	if arma:
		arma.position.z = move_toward(arma.position.z, -0.45, delta * 1.5)
	if luz_disparo:
		luz_disparo.light_energy = move_toward(luz_disparo.light_energy, 0.0, delta * 30.0)
	if cd_dash > 0.0:
		cd_dash = maxf(0.0, cd_dash - delta)
	if timer_disparo > 0.0:
		timer_disparo = maxf(0.0, timer_disparo - delta)
	var in_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := (transform.basis * Vector3(in_dir.x, 0.0, in_dir.y)).normalized()
	if Input.is_action_just_pressed("dash") and cd_dash <= 0.0:
		cd_dash = 0.8
		var dir_d := dir if dir.length_squared() > 0.01 else -transform.basis.z
		velocity.x = dir_d.x * 14.0
		velocity.z = dir_d.z * 14.0
		if audio_dash:
			audio_dash.play()
	var presiona_slide := Input.is_action_pressed("deslizar")
	if presiona_slide and is_on_floor() and not en_slide:
		en_slide = true
		t_slide = 0.0
		dir_slide = dir if dir.length_squared() > 0.01 else -transform.basis.z
	if en_slide:
		t_slide += delta
		velocity.x = dir_slide.x * 9.0
		velocity.z = dir_slide.z * 9.0
		if cam:
			cam.position.y = move_toward(cam.position.y, 0.8, delta * 8.0)
		if col_shape and col_shape.shape is CapsuleShape3D:
			(col_shape.shape as CapsuleShape3D).height = 0.9
		if not presiona_slide or t_slide >= 3.0:
			en_slide = false
	else:
		if cam:
			cam.position.y = move_toward(cam.position.y, 1.6, delta * 8.0)
		if col_shape and col_shape.shape is CapsuleShape3D:
			(col_shape.shape as CapsuleShape3D).height = 1.8
		var v_target := vel_sprint if Input.is_action_pressed("sprint") else vel_caminar
		if dir:
			velocity.x = move_toward(velocity.x, dir.x * v_target, delta * 25.0)
			velocity.z = move_toward(velocity.z, dir.z * v_target, delta * 25.0)
		else:
			velocity.x = move_toward(velocity.x, 0.0, delta * 20.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 20.0)
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto
		if audio_salto:
			audio_salto.play()
	_procesar_audio_pasos(dir)
	if Input.is_action_pressed("disparo_primario") and timer_disparo <= 0.0:
		disparar()
		timer_disparo = 0.25
	move_and_slide()
func _procesar_audio_pasos(dir: Vector3) -> void:
	if not audio_pasos:
		return
	var moviendo := is_on_floor() and dir.length_squared() > 0.01 and Vector2(velocity.x, velocity.z).length() > 0.5 and not en_slide
	if moviendo:
		if not audio_pasos.playing:
			audio_pasos.play()
	else:
		if audio_pasos.playing:
			audio_pasos.stop()
func _on_audio_pasos_finished() -> void:
	if audio_pasos and is_on_floor() and not en_slide:
		audio_pasos.play()
func _procesar_audio_salud() -> void:
	if not audio_respiracion:
		return
	if hp < hp_max * 0.5 and hp > 0.0:
		if not audio_respiracion.playing:
			audio_respiracion.play()
	else:
		if audio_respiracion.playing:
			audio_respiracion.stop()
func _on_audio_respiracion_finished() -> void:
	if hp < hp_max * 0.5 and hp > 0.0 and audio_respiracion:
		audio_respiracion.play()
func disparar() -> void:
	if audio_disparo:
		audio_disparo.play()
	if arma:
		arma.position.z = -0.36
	if luz_disparo:
		luz_disparo.light_energy = 4.0
	if not escena_bala or not cam:
		return
	var b := escena_bala.instantiate() as BalaJugador
	var punto_mira := cam.global_position - cam.global_transform.basis.z * 25.0
	if raycast:
		raycast.target_position = Vector3(0.0, 0.0, -25.0)
		raycast.force_raycast_update()
		if raycast.is_colliding():
			punto_mira = raycast.get_collision_point()
	var punto_origen := cam.global_position - cam.global_transform.basis.z * 0.4 + cam.global_transform.basis.x * 0.22 - cam.global_transform.basis.y * 0.18
	var dir_vuelo := (punto_mira - punto_origen).normalized()
	b.global_position = punto_origen
	b.dir = dir_vuelo
	b.look_at(punto_origen + dir_vuelo, Vector3.UP)
	b.p = self
	get_tree().current_scene.add_child(b)
func notificar_impacto(pos_hit: Vector3, dmg: float) -> void:
	t_quieto = 0.0
	var dist := global_position.distance_to(pos_hit)
	if dist <= 2.0:
		hp = minf(hp_max, hp + dmg * 0.30)
		cambio_salud.emit(hp, hp_max)
		if sis_eventos:
			sis_eventos.disparar_destello(pos_hit)
func recibir_dano(cantidad: float) -> void:
	hp = maxf(0.0, hp - cantidad)
	cambio_salud.emit(hp, hp_max)
func ganar_xp() -> void:
	var pct := maxf(0.05, 0.15 - (nivel - 1) * 0.01)
	xp += xp_max * pct
	if xp >= xp_max:
		xp -= xp_max
		nivel += 1
		xp_max = xp_max * 1.25
	cambio_xp.emit(xp, xp_max, nivel)
