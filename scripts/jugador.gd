class_name Jugador
extends CharacterBody3D
signal cambio_salud(actual: float, maxima: float)
signal alerta_sangrado(activo: bool)
signal cambio_xp(actual: float, maxima: float, lvl: int)
signal dano_infligido(cantidad: float)
@export var hp_max: float = 100.0
@export var vel_caminar: float = 5.0
@export var vel_sprint: float = 6.6
@export var fuerza_salto: float = 6.5
@export var grav: float = 14.0
@export var mouse_sens: float = 0.002
@onready var cam: Camera3D = $Camera3D
@onready var arma: ArmaJugador = $Camera3D/Arma
@onready var audio_p: AudioJugador = $AudioJugador
@onready var sis_eventos: SistemaEventos = get_tree().get_first_node_in_group("sistema_eventos") as SistemaEventos
@onready var parry_b: BrazoParry = $Camera3D/BrazoParry
var hp: float = 100.0
var t_quieto: float = 0.0
var cd_dash: float = 0.0
var nivel: int = 1
var xp: float = 0.0
var xp_max: float = 100.0
var muerto: bool = false
func _ready() -> void:
	hp = hp_max; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cambio_xp.emit(xp, xp_max, nivel)
	if has_node("ModeloJugador"):
		for m in $ModeloJugador.find_children("*", "VisualInstance3D", true, false):
			if m.name in ["Guante_D", "Antebrazo_D", "Brazalete_D"]: m.reparent(arma, true)
			else: m.layers = 2
func _unhandled_input(event: InputEvent) -> void:
	if not muerto and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		cam.rotation.x = clampf(cam.rotation.x - event.relative.y * mouse_sens, -1.55, 1.55)
func _physics_process(delta: float) -> void:
	if muerto: return
	if not is_on_floor(): velocity.y -= grav * delta
	t_quieto += delta
	var sangrando := t_quieto > 15.0
	alerta_sangrado.emit(sangrando)
	if sangrando: recibir_dano(2.0 * delta)
	cd_dash = maxf(0.0, cd_dash - delta)
	var in_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := (transform.basis * Vector3(in_dir.x, 0.0, in_dir.y)).normalized()
	if Input.is_action_just_pressed("dash") and cd_dash <= 0.0:
		cd_dash = 0.8
		var d := dir if dir.length_squared() > 0.01 else -transform.basis.z
		velocity = Vector3(d.x * 11.0, velocity.y, d.z * 11.0)
		if audio_p: audio_p.dash()
	_mover_horizontal(delta, dir)
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto
		if audio_p: audio_p.salto()
	var moviendo := is_on_floor() and dir.length_squared() > 0.01 and Vector2(velocity.x, velocity.z).length() > 0.5
	if audio_p: audio_p.actualizar(moviendo, hp, hp_max)
	if Input.is_action_pressed("disparo_primario") and arma: arma.intentar_disparar(self)
	if Input.is_action_just_pressed("parry") and parry_b: parry_b.ejecutar_parry()
	move_and_slide()
func _mover_horizontal(delta: float, dir: Vector3) -> void:
	var spd := vel_sprint if Input.is_action_pressed("sprint") else vel_caminar
	var vh := Vector2(velocity.x, velocity.z)
	var d2 := Vector2(dir.x, dir.z)
	if is_on_floor():
		var accel := 34.0 if vh.length() <= spd + 0.5 else 16.0
		vh = vh.move_toward(d2 * spd, delta * accel)
	elif d2.length_squared() > 0.01:
		if vh.length() <= spd:
			vh = vh.move_toward(d2 * spd, delta * 18.0)
		else:
			vh = vh.normalized().lerp(d2, clampf(delta * 4.5, 0.0, 1.0)).normalized() * vh.length()
	if vh.length() > 11.0:
		vh = vh.normalized() * 11.0
	velocity.x = vh.x
	velocity.z = vh.y
func notificar_impacto(_pos_hit: Vector3, dmg: float) -> void:
	t_quieto = 0.0
	dano_infligido.emit(dmg)
func curar(cantidad: float) -> void:
	hp = clampf(hp + cantidad, 0.0, hp_max)
	cambio_salud.emit(hp, hp_max)
	if sis_eventos: sis_eventos.disparar_destello(global_position)
func recibir_dano(cantidad: float) -> void:
	if muerto: return
	hp = clampf(hp - cantidad, 0.0, hp_max)
	if cantidad >= 1.0 and audio_p: audio_p.dano()
	cambio_salud.emit(hp, hp_max)
	if hp <= 0.0:
		muerto = true
		if audio_p: audio_p.actualizar(false, 0.0, hp_max)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func ganar_xp() -> void:
	xp += xp_max * maxf(0.05, 0.15 - (nivel - 1) * 0.01)
	if xp >= xp_max:
		xp -= xp_max
		nivel += 1
		xp_max *= 1.25
	cambio_xp.emit(xp, xp_max, nivel)
