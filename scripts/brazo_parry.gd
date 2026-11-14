class_name BrazoParry
extends Node3D
signal parry_activado()
signal parry_conectado(es_fuerte: bool)
const VENTANA_PARRY := 0.22
const CD_FALLO := 1.5; const CD_EXITO := 0.35; const CD_CURA := 2.0
const RANGO_ENEMIGO := 2.7
const RANGO_PROYECTIL := 1.65
const PUNO_IDLE := [Vector3(-0.34, -0.58, -0.14), Vector3(24.0, 10.0, -14.0)]
const PUNO_GOLPE := [Vector3(-0.18, -0.27, -0.35), Vector3(84.0, -30.0, 22.0)]
@onready var parry_area: Area3D = $ParryArea
@onready var puno: Node3D = get_node_or_null("PunoParry") as Node3D
@onready var luz: OmniLight3D = $LuzParry
@onready var a_golpe: AudioStreamPlayer = $AudioGolpe
@onready var cam: Camera3D = get_parent() as Camera3D
@onready var raycast: RayCast3D = get_parent().get_node_or_null("RayCast3D") as RayCast3D
@onready var p_jugador: Jugador = get_parent().get_parent() as Jugador
var is_parrying: bool = false; var can_parry: bool = true; var acerto_parry: bool = false
var t_ventana: float = 0.0; var t_cooldown: float = 0.0; var cd_max: float = CD_FALLO; var t_cura_cd: float = 0.0
var hitstop_id: int = 0; var objetivos_golpeados: Array[Node] = []
func _ready() -> void:
	if parry_area:
		parry_area.monitoring = false
		parry_area.area_entered.connect(func(a: Area3D): if is_parrying and a is Proyectil: desviar(a as Proyectil))
		parry_area.body_entered.connect(func(c: Node): if is_parrying and c.is_in_group("enemigos"): golpear_enemigo(c))
	if luz: luz.light_energy = 0.0
func _exit_tree() -> void: Engine.time_scale = 1.0
func vincular_puno(modelo: Node3D, base_xf: Transform3D) -> void:
	if not puno or not modelo: return
	puno.global_transform = Transform3D(base_xf.basis, base_xf.origin + base_xf.basis * Vector3(-0.265, 0.94, -0.04))
	for nombre in ["Guante_I", "Antebrazo_I", "Brazalete_I"]:
		var n := modelo.find_child(nombre, true, false) as VisualInstance3D
		if n: n.layers = 1; n.reparent(puno, true)
	puno.position = PUNO_IDLE[0]; puno.rotation_degrees = PUNO_IDLE[1]; puno.visible = false
func _physics_process(delta: float) -> void:
	if t_cura_cd > 0.0: t_cura_cd = maxf(0.0, t_cura_cd - delta)
	if luz and luz.light_energy > 0.0: luz.light_energy = move_toward(luz.light_energy, 0.0, delta * 20.0)
	if puno and puno.visible:
		var pose := PUNO_GOLPE if is_parrying else PUNO_IDLE
		var w := minf(1.0, delta * (32.0 if is_parrying else 12.0))
		puno.position = puno.position.lerp(pose[0], w); puno.rotation_degrees = puno.rotation_degrees.lerp(pose[1], w)
		if not is_parrying and puno.position.y <= -0.52: puno.visible = false
	if is_parrying:
		_barrer_objetivos(); t_ventana -= delta
		if t_ventana <= 0.0:
			is_parrying = false; cd_max = CD_EXITO if acerto_parry else CD_FALLO; t_cooldown = cd_max
			if parry_area: parry_area.monitoring = false
	elif not can_parry:
		t_cooldown = maxf(0.0, t_cooldown - delta); can_parry = t_cooldown <= 0.0
func ejecutar_parry() -> void:
	if not can_parry: return
	can_parry = false; is_parrying = true; acerto_parry = false; t_ventana = VENTANA_PARRY; objetivos_golpeados.clear()
	if parry_area: parry_area.monitoring = true
	if puno: puno.visible = true
	if luz: luz.light_energy = 1.4
	parry_activado.emit(); _barrer_objetivos()
func _barrer_objetivos() -> void:
	if parry_area:
		for a in parry_area.get_overlapping_areas(): if a is Proyectil: desviar(a as Proyectil)
		for b in parry_area.get_overlapping_bodies(): if b.is_in_group("enemigos"): golpear_enemigo(b)
	if not cam or not is_inside_tree(): return
	var origen := cam.global_position; var fwd := -cam.global_transform.basis.z; var cp := origen + fwd * 1.0
	for pn in get_tree().get_nodes_in_group("proyectiles"):
		if pn is Proyectil and is_instance_valid(pn) and not (pn as Proyectil).parreado and (pn as Proyectil).global_position.distance_to(cp) <= RANGO_PROYECTIL: desviar(pn as Proyectil)
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e is Node3D and is_instance_valid(e):
			var ce := (e as Node3D).global_position + Vector3.UP * 0.9
			if origen.distance_to(ce) <= RANGO_ENEMIGO and fwd.dot((ce - origen).normalized()) > 0.35: golpear_enemigo(e)
func desviar(proy: Proyectil) -> void:
	if not proy or proy.parreado or proy in objetivos_golpeados: return
	objetivos_golpeados.append(proy)
	var origen := cam.global_position if cam else global_position; var fwd := -cam.global_transform.basis.z if cam else -global_transform.basis.z
	var pt_mira := origen + fwd * 60.0
	if raycast:
		raycast.target_position = Vector3(0.0, 0.0, -60.0); raycast.force_raycast_update()
		if raycast.is_colliding() and origen.distance_to(raycast.get_collision_point()) > 0.6: pt_mira = raycast.get_collision_point()
	if (proy.global_position - origen).dot(fwd) < 0.55: proy.global_position = origen + fwd * 0.65
	var dir_dev := (pt_mira - proy.global_position).normalized()
	proy.parrear(fwd if (pt_mira - proy.global_position).dot(fwd) <= 0.1 else dir_dev)
	_feedback_parry(true, 20.0, 25.0, proy.global_position, 5.5, 0.085)
func golpear_enemigo(enemigo: Node) -> void:
	if not enemigo or enemigo in objetivos_golpeados: return
	objetivos_golpeados.append(enemigo)
	var fwd := -cam.global_transform.basis.z if cam else -global_transform.basis.z
	var es_fuerte := false; var dmg := 25.0
	if enemigo.has_method("recibir_parry"): es_fuerte = enemigo.recibir_parry(fwd); dmg = 50.0 if es_fuerte else 25.0
	elif enemigo.has_method("recibir_dano"): enemigo.recibir_dano(25.0)
	_feedback_parry(es_fuerte, 20.0 if es_fuerte else 0.0, dmg, (enemigo as Node3D).global_position if enemigo is Node3D else global_position, 5.5 if es_fuerte else 2.5, 0.08 if es_fuerte else 0.04)
func _feedback_parry(es_fuerte: bool, cura: float, dmg: float, pos: Vector3, energia: float, dur: float) -> void:
	if a_golpe: a_golpe.stop(); a_golpe.play()
	var cura_real := cura if (cura > 0.0 and t_cura_cd <= 0.0) else 0.0
	acerto_parry = acerto_parry or es_fuerte; t_cura_cd = CD_CURA if cura_real > 0.0 else t_cura_cd
	if p_jugador: p_jugador.aplicar_parry_jugador(cura_real, dmg, pos, es_fuerte)
	if luz: luz.light_energy = energia
	parry_conectado.emit(es_fuerte); hitstop_id += 1; var mio := hitstop_id; Engine.time_scale = 0.05
	if not is_inside_tree(): Engine.time_scale = 1.0; return
	await get_tree().create_timer(dur, true, false, true).timeout
	if is_inside_tree() and hitstop_id == mio: Engine.time_scale = 1.0