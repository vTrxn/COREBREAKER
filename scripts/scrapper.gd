class_name Scrapper
extends CharacterBody3D
@export var hp: float = 100.0
@export var vel: float = 5.4
@export var dmg_golpe: float = 12.0
@export var cd_ataque: float = 1.45
@export var rango_ataque: float = 1.5
@export var rango_golpe: float = 2.1
@export var delay_golpe: float = 0.73
@onready var audio_hit: AudioStreamPlayer3D = $AudioHit; @onready var luz_est: OmniLight3D = get_node_or_null("LuzEstado") as OmniLight3D
@onready var modelo: Node3D = $Modelo
var anim_player: AnimationPlayer = null; var player: CharacterBody3D = null
var timer_ataque: float = 0.0; var timer_golpe: float = 0.0; var t_aturdido: float = 0.0
var cd_salto: float = 0.0; var cd_embestida: float = 1.6
var empuje_vel: Vector3 = Vector3.ZERO
var atacando: bool = false; var aviso_parry: bool = false; var muerto: bool = false
var grav: float = 14.0; var activo: bool = false
func _ready() -> void:
	player = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	anim_player = modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer if modelo else null
	ParticulasImpacto.iniciar_spawn(self, modelo, Color(0.25, 1.0, 0.2, 1.0), func(): activo = true)
func _physics_process(delta: float) -> void:
	velocity.y -= grav * delta if not is_on_floor() else 0.0
	cd_salto = maxf(0.0, cd_salto - delta); cd_embestida = maxf(0.0, cd_embestida - delta)
	if luz_est and not atacando: luz_est.light_energy = move_toward(luz_est.light_energy, 0.0, delta * 20.0)
	if not player: player = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if not activo or not player: velocity = Vector3(0.0, velocity.y, 0.0); move_and_slide(); return
	if t_aturdido > 0.0:
		t_aturdido = maxf(0.0, t_aturdido - delta); empuje_vel = empuje_vel.move_toward(Vector3.ZERO, delta * 22.0)
		velocity = Vector3(empuje_vel.x, velocity.y, empuje_vel.z); move_and_slide(); return
	var pos_p := Vector3(player.global_position.x, global_position.y, player.global_position.z)
	var dist := global_position.distance_to(pos_p); var dy := absf(player.global_position.y - global_position.y)
	var destino := _elegir_destino(pos_p); var dist_dest := global_position.distance_to(destino)
	var pos_pre := Vector2(global_position.x, global_position.z); var moviendo := false
	if atacando:
		_frenar(delta, 6.0)
		if dist > 0.25 and timer_golpe > 0.25: look_at(pos_p, Vector3.UP)
		_actualizar_telegrafo(); timer_golpe -= delta
		if timer_golpe <= 0.0:
			atacando = false
			if dist <= rango_golpe and dy <= 1.8 and player.has_method("recibir_dano"): player.recibir_dano(dmg_golpe)
	elif (dist > rango_ataque or dy > 1.6) and dist_dest > 0.3:
		if (anim_player and anim_player.current_animation == "Ataque" and anim_player.is_playing()) or dist_dest <= 0.25: _frenar(delta, 6.0)
		else:
			var vel_m := vel * 1.35 if not is_on_floor() else vel; var d := (destino - global_position).normalized(); moviendo = true
			velocity = Vector3(d.x * vel_m, velocity.y, d.z * vel_m); look_at(destino, Vector3.UP); _anim("Caminar", 0.15, false)
	else:
		_frenar(delta, 5.0)
		if dist > 0.25: look_at(pos_p, Vector3.UP)
		if dist <= rango_ataque and dy <= 1.6 and timer_ataque <= 0.0:
			atacando = true; aviso_parry = false; timer_golpe = delay_golpe; timer_ataque = cd_ataque; _anim("Ataque", 0.08, true)
	timer_ataque = maxf(0.0, timer_ataque - delta); move_and_slide()
	if moviendo and is_on_floor() and cd_salto <= 0.0: _evaluar_salto(delta, pos_pre, dist, dy, destino.distance_to(pos_p) < 0.5)
func _elegir_destino(pos_p: Vector3) -> Vector3:
	if player.global_position.y - global_position.y > 1.6 and global_position.y < 1.8 and is_on_floor():
		var mejor: Node3D = null; var m_d := 22.0
		for pad in get_tree().get_nodes_in_group("pads_impulso"):
			if pad is Node3D and absf(pad.global_position.y - global_position.y) < 1.5:
				var dp := global_position.distance_to(pad.global_position)
				if dp < m_d: m_d = dp; mejor = pad as Node3D
		if mejor: return Vector3(mejor.global_position.x, global_position.y, mejor.global_position.z)
	return pos_p
func _evaluar_salto(delta: float, pos_pre: Vector2, dist: float, dy: float, directo: bool) -> void:
	var av := Vector2(global_position.x, global_position.z).distance_to(pos_pre)
	if is_on_wall() or av < vel * delta * 0.28: velocity.y = 7.6; cd_salto = 1.05
	elif directo and dy <= 1.6 and dist >= 3.8 and dist <= 6.8 and cd_embestida <= 0.0:
		velocity.y = 5.6; cd_salto = 1.2; cd_embestida = randf_range(2.8, 4.2)
func _actualizar_telegrafo() -> void:
	if luz_est: luz_est.light_color = Color(1.0, 0.85, 0.12, 1.0); luz_est.light_energy = 4.6 if timer_golpe <= 0.42 else 1.8
	if timer_golpe <= 0.42 and not aviso_parry:
		aviso_parry = true
		if modelo: ParticulasImpacto.flash_malla(modelo, Color(1.0, 0.88, 0.18, 1.0), 0.10)
func _anim(n: String, b: float, r: bool) -> void:
	if anim_player and anim_player.has_animation(n) and (r or not anim_player.is_playing() or anim_player.current_animation != n):
		if r: anim_player.stop()
		anim_player.play(n, b)
func _frenar(delta: float, mult: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, vel * delta * mult); velocity.z = move_toward(velocity.z, 0.0, vel * delta * mult)
func recibir_parry(dir_empuje: Vector3) -> bool:
	var en_ataque := atacando or (anim_player != null and anim_player.current_animation == "Ataque" and anim_player.is_playing())
	atacando = false; timer_golpe = 0.0; timer_ataque = cd_ataque
	t_aturdido = 0.75 if en_ataque else 0.4
	var h := Vector3(dir_empuje.x, 0.0, dir_empuje.z)
	if h.length_squared() <= 0.01 and player: h = Vector3(global_position.x - player.global_position.x, 0.0, global_position.z - player.global_position.z)
	empuje_vel = (h.normalized() if h.length_squared() > 0.01 else Vector3.ZERO) * (10.0 if en_ataque else 7.0)
	velocity.y = 3.2 if en_ataque else 2.0
	if en_ataque and luz_est: luz_est.light_color = Color(0.2, 0.95, 1.0, 1.0); luz_est.light_energy = 5.5
	recibir_dano(50.0 if en_ataque else 25.0, en_ataque)
	return en_ataque
func recibir_dano(cantidad: float, es_parry: bool = false) -> void:
	if muerto: return
	if audio_hit: audio_hit.play()
	hp -= cantidad
	if hp > 0.0:
		if modelo: ParticulasImpacto.flash_malla(modelo, Color(0.25, 0.95, 1.0, 1.0) if es_parry else Color.WHITE, 0.08 if es_parry else 0.06)
		return
	muerto = true
	ParticulasImpacto.morir_enemigo(self, Color(0.2, 0.95, 1.0, 1.0) if es_parry else Color(0.3, 1.0, 0.25, 1.0), player, audio_hit)