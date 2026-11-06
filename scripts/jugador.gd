class_name Jugador
extends CharacterBody3D
signal cambio_salud(actual: float, maxima: float)
signal alerta_sangrado(activo: bool)
signal cambio_xp(actual: float, maxima: float, lvl: int)
@export var hp_max: float = 100.0
@export var vel_caminar: float = 5.0
@export var vel_sprint: float = 6.6
@export var fuerza_salto: float = 6.5
@export var grav: float = 14.0
@export var mouse_sens: float = 0.002
@onready var cam: Camera3D = $Camera3D
@onready var col_shape: CollisionShape3D = $CollisionShape3D
@onready var arma: ArmaJugador = $Camera3D/Arma
@onready var audio_p: AudioJugador = $AudioJugador
@onready var sis_eventos: SistemaEventos = get_tree().get_first_node_in_group("sistema_eventos") as SistemaEventos
var hp: float = 100.0
var t_quieto: float = 0.0
var en_slide: bool = false
var t_slide: float = 0.0
var dir_slide: Vector3 = Vector3.ZERO
var cd_dash: float = 0.0
var nivel: int = 1
var xp: float = 0.0
var xp_max: float = 100.0
func _ready() -> void:
	hp = hp_max
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cambio_xp.emit(xp, xp_max, nivel)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		cam.rotation.x = clampf(cam.rotation.x - event.relative.y * mouse_sens, -1.55, 1.55)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= grav * delta
	t_quieto += delta
	var sangrando := t_quieto > 15.0
	alerta_sangrado.emit(sangrando)
	if sangrando:
		recibir_dano(2.0 * delta)
	cd_dash = maxf(0.0, cd_dash - delta)
	var in_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := (transform.basis * Vector3(in_dir.x, 0.0, in_dir.y)).normalized()
	if Input.is_action_just_pressed("dash") and cd_dash <= 0.0:
		cd_dash = 0.8
		var d := dir if dir.length_squared() > 0.01 else -transform.basis.z
		velocity = Vector3(d.x * 16.8, velocity.y, d.z * 16.8)
		if audio_p: audio_p.dash()
	var presiona_slide := Input.is_action_pressed("deslizar")
	if presiona_slide and is_on_floor() and not en_slide:
		en_slide = true
		t_slide = 0.0
		dir_slide = dir if dir.length_squared() > 0.01 else -transform.basis.z
	if en_slide:
		t_slide += delta
		velocity = Vector3(dir_slide.x * 10.0, velocity.y, dir_slide.z * 10.0)
		en_slide = presiona_slide and t_slide < 3.0
	else:
		var spd := vel_sprint if Input.is_action_pressed("sprint") else vel_caminar
		velocity.x = move_toward(velocity.x, dir.x * spd, delta * 25.0)
		velocity.z = move_toward(velocity.z, dir.z * spd, delta * 25.0)
	cam.position.y = move_toward(cam.position.y, 0.8 if en_slide else 1.6, delta * 8.0)
	if col_shape.shape is CapsuleShape3D:
		(col_shape.shape as CapsuleShape3D).height = 0.9 if en_slide else 1.8
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto
		if audio_p: audio_p.salto()
	var moviendo := is_on_floor() and dir.length_squared() > 0.01 and Vector2(velocity.x, velocity.z).length() > 0.5 and not en_slide
	if audio_p: audio_p.actualizar(moviendo, hp, hp_max)
	if Input.is_action_pressed("disparo_primario") and arma:
		arma.intentar_disparar(self)
	move_and_slide()
func notificar_impacto(pos_hit: Vector3, dmg: float) -> void:
	t_quieto = 0.0
	if global_position.distance_to(pos_hit) <= 2.0:
		recibir_dano(-dmg * 0.30)
		if sis_eventos: sis_eventos.disparar_destello(pos_hit)
func recibir_dano(cantidad: float) -> void:
	hp = clampf(hp - cantidad, 0.0, hp_max)
	cambio_salud.emit(hp, hp_max)
func ganar_xp() -> void:
	xp += xp_max * maxf(0.05, 0.15 - (nivel - 1) * 0.01)
	if xp >= xp_max:
		xp -= xp_max
		nivel += 1
		xp_max *= 1.25
	cambio_xp.emit(xp, xp_max, nivel)