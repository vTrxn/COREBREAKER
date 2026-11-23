class_name MorteroFision
extends Node3D
@export var radio: float = 3.0
@export var dmg: float = 32.0
@export var tiempo_aviso: float = 1.2
@export var tiempo_caida: float = 0.8
@export var escena_particulas: PackedScene = preload("res://ParticulasImpacto.tscn")
@onready var esfera: MeshInstance3D = $Esfera
@onready var anillo_ext: MeshInstance3D = $AnilloExt
@onready var disco_int: MeshInstance3D = $DiscoInt
@onready var luz: OmniLight3D = $LuzAviso
@onready var audio: AudioStreamPlayer3D = get_node_or_null("AudioImpacto") as AudioStreamPlayer3D
var _t: float = 0.0; var _detonado: bool = false; var _alt_ini: float = 14.0
func _ready() -> void:
	if esfera: esfera.position.y = _alt_ini; esfera.visible = false
	_actualizar_visuales(0.0)
func _physics_process(delta: float) -> void:
	if _detonado: return
	_t += delta
	var total := tiempo_aviso + tiempo_caida
	_actualizar_visuales(clampf(_t / maxf(total, 0.01), 0.0, 1.0))
	if _t >= tiempo_aviso and esfera:
		esfera.visible = true
		var p_caida := clampf((_t - tiempo_aviso) / maxf(tiempo_caida, 0.01), 0.0, 1.0)
		esfera.position.y = lerpf(_alt_ini, 0.45, p_caida * p_caida)
	if _t >= total: _detonar()
func _actualizar_visuales(prog: float) -> void:
	if disco_int:
		var s := maxf(0.08, prog) * radio
		disco_int.scale = Vector3(s, 1.0, s)
	if anillo_ext:
		anillo_ext.scale = Vector3(radio, 1.0, radio)
		anillo_ext.rotate_y(0.04)
	if luz:
		var pulso := sin(_t * TAU * 8.0) * 0.5 + 0.5
		luz.light_energy = lerpf(1.2, 5.5, pulso)
func _detonar() -> void:
	_detonado = true
	var p := get_tree().get_first_node_in_group("jugador") as Node3D
	if p and is_instance_valid(p):
		var d_xz := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
		if d_xz <= radio and absf(p.global_position.y - global_position.y) <= 2.6 and p.has_method("recibir_dano"):
			p.recibir_dano(dmg)
	if escena_particulas and is_inside_tree():
		var part := escena_particulas.instantiate() as ParticulasImpacto
		var cont := get_tree().current_scene if get_tree().current_scene else get_parent()
		cont.add_child(part); part.global_position = global_position + Vector3.UP * 0.35
		part.activar(global_position + Vector3.UP * 0.35, Vector3.UP, Color(0.62, 0.31, 0.87, 1.0))
	if esfera: esfera.visible = false
	if anillo_ext: anillo_ext.visible = false
	if disco_int: disco_int.visible = false
	if luz: luz.light_energy = 8.0
	if audio and is_inside_tree():
		audio.play()
		await audio.finished
	if is_inside_tree(): queue_free()
