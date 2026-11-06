class_name BrazoParry
extends Node3D
const IDLE_POS := Vector3(-0.28, -0.26, -0.22)
const IDLE_ROT := Vector3(-60.0, 35.0, -20.0)
const PARRY_POS := Vector3(-0.26, -0.23, -0.24)
const PARRY_ROT := Vector3(18.0, -42.0, -48.0)
@onready var parry_area: Area3D = $ParryArea
@onready var luz: OmniLight3D = $LuzParry
@onready var a_golpe: AudioStreamPlayer = $AudioGolpe
@onready var cam: Camera3D = get_parent() as Camera3D
@onready var p_jugador: Jugador = get_parent().get_parent() as Jugador
var is_parrying: bool = false
var can_parry: bool = true
var enemigos_golpeados: Array[Node] = []
func _ready() -> void:
	position = IDLE_POS
	rotation_degrees = IDLE_ROT
	if parry_area:
		parry_area.monitoring = false
		parry_area.area_entered.connect(_on_area_entered)
		parry_area.body_entered.connect(_on_body_entered)
	if luz:
		luz.light_energy = 0.0
func ejecutar_parry() -> void:
	if not can_parry:
		return
	can_parry = false
	is_parrying = true
	enemigos_golpeados.clear()
	if parry_area:
		parry_area.monitoring = true
	if luz:
		luz.light_energy = 3.5
	_verificar_impacto_cercano()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position", PARRY_POS, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation_degrees", PARRY_ROT, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	await get_tree().create_timer(0.14).timeout
	is_parrying = false
	if parry_area:
		parry_area.monitoring = false
	var tw_ret := create_tween().set_parallel(true)
	tw_ret.tween_property(self, "position", IDLE_POS, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw_ret.tween_property(self, "rotation_degrees", IDLE_ROT, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if luz:
		tw_ret.tween_property(luz, "light_energy", 0.0, 0.18)
	await tw_ret.finished
	can_parry = true
func desviar(proy: Proyectil) -> void:
	if not proy or proy.parreado:
		return
	var dir_mira := -cam.global_transform.basis.z if cam else -global_transform.basis.z
	proy.parrear(dir_mira)
	if a_golpe:
		a_golpe.play()
	if p_jugador:
		p_jugador.curar(25.0)
	if luz:
		luz.light_energy = 5.0
	_aplicar_hitstop()
func golpear_enemigo(enemigo: Node) -> void:
	if not enemigo or enemigo in enemigos_golpeados:
		return
	enemigos_golpeados.append(enemigo)
	if enemigo.has_method("recibir_dano"):
		enemigo.recibir_dano(40.0)
	if a_golpe:
		a_golpe.play()
	if p_jugador:
		p_jugador.curar(20.0)
	if luz:
		luz.light_energy = 4.5
	_aplicar_hitstop()
func _verificar_impacto_cercano() -> void:
	if not p_jugador or not cam:
		return
	var dir_f := -cam.global_transform.basis.z
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e is Node3D and is_instance_valid(e):
			var e3d := e as Node3D
			var dist := p_jugador.global_position.distance_to(e3d.global_position)
			if dist <= 2.4:
				var d_norm := (e3d.global_position - p_jugador.global_position).normalized()
				if dir_f.dot(d_norm) > 0.3:
					golpear_enemigo(e)
func _aplicar_hitstop() -> void:
	Engine.time_scale = 0.05
	var t := get_tree().create_timer(0.06, true, false, true)
	await t.timeout
	Engine.time_scale = 1.0
func _on_area_entered(area: Area3D) -> void:
	if is_parrying and area is Proyectil:
		desviar(area as Proyectil)
func _on_body_entered(cuerpo: Node) -> void:
	if is_parrying and cuerpo.is_in_group("enemigos"):
		golpear_enemigo(cuerpo)