class_name HUD
extends CanvasLayer
@onready var barra_salud: ProgressBar = $MarginContainer/VBoxContainer/BarraSalud
@onready var sangrado_aviso: Label = $MarginContainer/VBoxContainer/LabelSangrado
@onready var label_nivel: Label = $MarginContainer/VBoxContainer/LabelNivel
@onready var barra_xp: ProgressBar = $MarginContainer/VBoxContainer/BarraXP
@onready var label_horda: Label = find_child("LabelHorda") as Label
@onready var label_restantes: Label = find_child("LabelRestantes") as Label
func _ready() -> void:
	var p := get_tree().get_first_node_in_group("jugador") as Jugador
	if p:
		p.cambio_salud.connect(_on_salud)
		p.alerta_sangrado.connect(_on_sangrado)
		p.cambio_xp.connect(_on_xp)
	if sangrado_aviso:
		sangrado_aviso.visible = false
func _on_salud(act: float, max_v: float) -> void:
	if barra_salud:
		barra_salud.max_value = max_v
		barra_salud.value = act
func _on_sangrado(on: bool) -> void:
	if sangrado_aviso:
		sangrado_aviso.visible = on
func _on_xp(act: float, max_v: float, lvl: int) -> void:
	if label_nivel:
		label_nivel.text = "NIVEL %d" % lvl
	if barra_xp:
		barra_xp.max_value = max_v
		barra_xp.value = act
func actualizar_horda(num: int, restantes: int) -> void:
	if label_horda:
		label_horda.text = "HORDA %d" % num
	if label_restantes:
		label_restantes.text = "ENEMIGOS: %d" % restantes