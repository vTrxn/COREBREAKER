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
@onready var col: CollisionShape3D = $CollisionShape3D
@onready var arma: ArmaJugador = $Camera3D/Arma
@onready var audio_p: AudioJugador = $AudioJugador
@onready var sis_eventos: SistemaEventos = get_tree().get_first_node_in_group("sistema_eventos") as SistemaEventos
@onready var parry_b: BrazoParry = $Camera3D/BrazoParry
var hp: float = 100.0
var t_quieto: float = 0.0
var cd_dash: float = 0.0
var t_invul_parry: float = 0.0
var nivel: int = 1
var xp: float = 0.0
var xp_max: float = 100.0
var muerto: bool = false

# Variables para mecánicas de deslizamiento (slide) y salto extendido
var deslizando: bool = false
var altura_normal: float = 1.8
var altura_slide: float = 0.8
var cam_y_normal: float = 1.6
var cam_y_slide: float = 0.75
var vel_slide_impulso: float = 11.5
var timer_slide: float = 0.0
func _ready() -> void:
	hp = hp_max; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cambio_xp.emit(xp, xp_max, nivel)
	if col and col.shape:
		col.shape = col.shape.duplicate()
	if has_node("ModeloJugador"):
		if parry_b: parry_b.vincular_puno($ModeloJugador, global_transform)
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
	t_invul_parry = maxf(0.0, t_invul_parry - delta)
	var in_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := (transform.basis * Vector3(in_dir.x, 0.0, in_dir.y)).normalized()
	
	# Dash con cooldown
	if Input.is_action_just_pressed("dash") and cd_dash <= 0.0:
		cd_dash = 0.8
		var d := dir if dir.length_squared() > 0.01 else -transform.basis.z
		velocity = Vector3(d.x * 11.0, velocity.y, d.z * 11.0)
		if audio_p: audio_p.dash()
	
	# Mecánica de Deslizamiento y Gateo bajo estructuras
	var quiere_deslizar := Input.is_action_pressed("deslizar")
	var bloqueado_arriba := false
	if col and col.shape is CapsuleShape3D:
		# Comprobamos si hay obstáculo a la altura normal de estar de pie
		bloqueado_arriba = test_move(global_transform, Vector3(0.0, 0.95, 0.0))
	
	if (quiere_deslizar or bloqueado_arriba) and is_on_floor():
		if not deslizando:
			deslizando = true
			var d_slide := dir if dir.length_squared() > 0.01 else -transform.basis.z
			# Solo dar impulso inicial si veníamos moviéndonos y no estábamos ya debajo
			if not bloqueado_arriba and in_dir.length_squared() > 0.01:
				velocity = Vector3(d_slide.x * vel_slide_impulso, velocity.y, d_slide.z * vel_slide_impulso)
				if audio_p: audio_p.dash()
	elif not bloqueado_arriba:
		deslizando = false
	
	# Ajuste de altura instantáneo en la colisión física para no atorarse, y cámara suavizada
	if col and col.shape is CapsuleShape3D:
		var cap := col.shape as CapsuleShape3D
		var target_h := altura_slide if deslizando else altura_normal
		cap.height = target_h
		col.position.y = target_h * 0.5
	var target_cam := cam_y_slide if deslizando else cam_y_normal
	cam.position.y = lerpf(cam.position.y, target_cam, delta * 15.0)

	_mover_horizontal(delta, dir)

	# Salto estándar y Salto Extendido (si no hay techo bloqueando la cabeza)
	if Input.is_action_just_pressed("saltar") and is_on_floor() and not bloqueado_arriba:
		if deslizando:
			velocity.y = fuerza_salto * 1.15
			var vh_jump := Vector2(velocity.x, velocity.z)
			if vh_jump.length() > 0.1:
				vh_jump = vh_jump.normalized() * 11.5
				velocity.x = vh_jump.x
				velocity.z = vh_jump.y
			deslizando = false
		else:
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
		if deslizando:
			if vh.length() > vel_caminar:
				# Si aún tiene el impulso rápido del slide, frenado suave
				vh = vh.move_toward(d2 * (vel_caminar * 0.8), delta * 5.0)
			else:
				# Si se frena o queda en medio de una estructura baja, ¡gatear libremente con WASD!
				var vel_gateo := vel_caminar * 0.8
				vh = vh.move_toward(d2 * vel_gateo, delta * 24.0)
		else:
			vh = vh.move_toward(d2 * spd, delta * (34.0 if vh.length() <= spd + 0.5 else 16.0))
	else:
		# En el aire (saltos o impulsos de pads):
		if d2.length_squared() > 0.01:
			if vh.length() <= spd:
				vh = vh.move_toward(d2 * spd, delta * 18.0)
			else:
				# Preservar inercia del lanzamiento permitiendo dirigir el vuelo
				vh = vh.normalized().lerp(d2, clampf(delta * 2.0, 0.0, 1.0)).normalized() * vh.length()
		# Si no hay input de movimiento en el aire, se conserva el 100% de la velocidad horizontal
	vh = vh.limit_length(16.0)
	velocity.x = vh.x; velocity.z = vh.y
func notificar_impacto(_pos_hit: Vector3, dmg: float) -> void:
	t_quieto = 0.0
	dano_infligido.emit(dmg)
func aplicar_parry_jugador(cura: float, dmg: float, pos_hit: Vector3, invul: bool = false) -> void:
	if invul or cura > 0.0: t_invul_parry = 0.25
	if cura > 0.0: curar(cura)
	notificar_impacto(pos_hit, dmg)
func curar(cantidad: float) -> void:
	hp = clampf(hp + cantidad, 0.0, hp_max)
	cambio_salud.emit(hp, hp_max)
	if sis_eventos: sis_eventos.disparar_destello(global_position)
func recibir_dano(cantidad: float) -> void:
	if muerto or t_invul_parry > 0.0: return
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
		xp -= xp_max; nivel += 1; xp_max *= 1.25
	cambio_xp.emit(xp, xp_max, nivel)