class_name AudioJugador
extends Node
@onready var a_salto: AudioStreamPlayer = get_node("../AudioSalto") as AudioStreamPlayer
@onready var a_dash: AudioStreamPlayer = get_node("../AudioDash") as AudioStreamPlayer
@onready var a_pasos: AudioStreamPlayer = get_node("../AudioPasos") as AudioStreamPlayer
@onready var a_resp: AudioStreamPlayer = get_node("../AudioRespiracion") as AudioStreamPlayer
@onready var a_dano: AudioStreamPlayer = get_node("../AudioDano") as AudioStreamPlayer
var p: CharacterBody3D = null
func _ready() -> void:
	p = get_parent() as CharacterBody3D
	if a_pasos and a_pasos.stream is AudioStreamMP3:
		(a_pasos.stream as AudioStreamMP3).loop = true
	if a_resp and a_resp.stream is AudioStreamMP3:
		(a_resp.stream as AudioStreamMP3).loop = true
	if a_pasos:
		a_pasos.finished.connect(_on_pasos_fin)
	if a_resp:
		a_resp.finished.connect(_on_resp_fin)
func salto() -> void:
	if a_salto:
		a_salto.play()
func dash() -> void:
	if a_dash:
		a_dash.play()
func dano() -> void:
	if a_dano:
		a_dano.play()
func actualizar(moviendo: bool, hp: float, hp_max: float) -> void:
	if a_pasos:
		if moviendo and not a_pasos.playing:
			a_pasos.play()
		elif not moviendo and a_pasos.playing:
			a_pasos.stop()
	if a_resp:
		var bajo := hp < hp_max * 0.5 and hp > 0.0
		if bajo and not a_resp.playing:
			a_resp.play()
		elif not bajo and a_resp.playing:
			a_resp.stop()
func _on_pasos_fin() -> void:
	if p and p.is_on_floor() and a_pasos and p.velocity.length() > 0.5:
		a_pasos.play()
func _on_resp_fin() -> void:
	if p and p.get("hp") < p.get("hp_max") * 0.5 and p.get("hp") > 0.0 and a_resp:
		a_resp.play()
