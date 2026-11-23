class_name EspadaJugador
extends Node3D
signal cambio_cargas_espada(actual: int, maxima: int)
const RANGO_CORTE := 5.2; const RANGO_CERCANO := 2.6; const DOT_CONO := 0.15
const DANO_JEFE := 220.0; const DANO_ENEMIGO := 9999.0; const CURA_ABSORCION := 15.0
const POS_INI := Vector3(0.56, 0.28, -0.58); const ROT_INI := Vector3(-38.0, -32.0, -28.0)
const POS_MED := Vector3(0.02, -0.10, -0.80); const ROT_MED := Vector3(-78.0, 22.0, 52.0)
const POS_FIN := Vector3(-0.62, -0.44, -0.54); const ROT_FIN := Vector3(-52.0, 62.0, 118.0)
@export var cargas_max: int = 2
@onready var modelo: Node3D = get_node_or_null("ModeloEspada") as Node3D
@onready var luz: OmniLight3D = get_node_or_null("LuzEspada") as OmniLight3D
@onready var audio: AudioStreamPlayer = get_node_or_null("AudioEspada") as AudioStreamPlayer
@onready var cam: Camera3D = get_parent() as Camera3D
var cargas: int = 2; var cortando: bool = false; var hitstop_id: int = 0; var tw_corte: Tween = null
func _ready() -> void:
	cargas = cargas_max
	if modelo: modelo.visible = false
	if luz: luz.light_color = Color(1.0, 0.08, 0.14); luz.light_energy = 0.0
	cambio_cargas_espada.emit(cargas, cargas_max)
func _exit_tree() -> void:
	Engine.time_scale = 1.0
func _process(delta: float) -> void:
	if luz and luz.light_energy > 0.0: luz.light_energy = move_toward(luz.light_energy, 0.0, delta * 24.0)
func ejecutar_corte(p: Jugador) -> void:
	if cortando or cargas <= 0: return
	cargas -= 1; cortando = true; cambio_cargas_espada.emit(cargas, cargas_max)
	if audio: audio.stop(); audio.pitch_scale = 0.72; audio.play()
	if luz: luz.light_color = Color(1.0, 0.08, 0.14); luz.light_energy = 7.5
	_animar_tajo()
	_aplicar_dano_corte(p)
func _animar_tajo() -> void:
	if tw_corte and tw_corte.is_valid(): tw_corte.kill()
	tw_corte = create_tween()
	if modelo:
		modelo.visible = true; modelo.position = POS_INI; modelo.rotation_degrees = ROT_INI
		tw_corte.set_parallel(true)
		tw_corte.tween_property(modelo, "position", POS_MED, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw_corte.tween_property(modelo, "rotation_degrees", ROT_MED, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw_corte.chain().set_parallel(true)
		tw_corte.tween_property(modelo, "position", POS_FIN, 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw_corte.tween_property(modelo, "rotation_degrees", ROT_FIN, 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw_corte.chain().tween_property(modelo, "position", POS_FIN + Vector3(-0.14, -0.22, 0.12), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tw_corte.tween_interval(0.34)
	tw_corte.chain().tween_callback(_fin_corte)
func _fin_corte() -> void:
	if modelo: modelo.visible = false
	cortando = false
func _aplicar_dano_corte(p: Jugador) -> void:
	if not is_inside_tree(): return
	var origen := cam.global_position if cam else global_position
	var fwd := (-cam.global_transform.basis.z if cam else -global_transform.basis.z).normalized()
	var impactos := 0; var dmg_total := 0.0; var pos_hit := origen + fwd * 2.0
	for e in get_tree().get_nodes_in_group("enemigos"):
		if not (e is Node3D) or not is_instance_valid(e) or e.get("muerto") == true: continue
		var e3 := e as Node3D; var centro := e3.global_position + Vector3.UP * 0.9
		var vec := centro - origen; var dist := vec.length()
		if dist > RANGO_CORTE: continue
		if dist > RANGO_CERCANO and (dist <= 0.001 or fwd.dot(vec / dist) <= DOT_CONO): continue
		var es_jefe := e.name == "Custodio" or e.has_signal("boss_derrotado")
		if es_jefe:
			ParticulasImpacto.estallar(e3, Color(1.0, 0.12, 0.16), 1.5)
			if e.has_method("recibir_dano"): e.recibir_dano(DANO_JEFE)
			dmg_total += DANO_JEFE
		else:
			ParticulasImpacto.estallar(e3, Color(1.0, 0.12, 0.16), 1.8)
			if e.has_method("recibir_dano"): e.recibir_dano(DANO_ENEMIGO)
			if p: p.curar(CURA_ABSORCION)
			dmg_total += DANO_ENEMIGO
		impactos += 1; pos_hit = centro
	if impactos > 0:
		if p: p.notificar_impacto(pos_hit, dmg_total)
		_aplicar_hitstop()
func _aplicar_hitstop() -> void:
	hitstop_id += 1; var mio := hitstop_id; Engine.time_scale = 0.08
	if not is_inside_tree(): Engine.time_scale = 1.0; return
	await get_tree().create_timer(0.06, true, false, true).timeout
	if is_inside_tree() and hitstop_id == mio: Engine.time_scale = 1.0
func recargar_por_nivel() -> void:
	if cargas < cargas_max:
		cargas = mini(cargas + 1, cargas_max)
		cambio_cargas_espada.emit(cargas, cargas_max)
