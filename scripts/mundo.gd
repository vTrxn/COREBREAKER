class_name Mundo
extends Node3D
@export var spawner_scrapper: PackedScene
@export var spawner_torreta: PackedScene
@export var total_hordas: int = 3
@onready var p: Jugador = $Jugador
@onready var mus: AudioStreamPlayer = $MusicaNivel
@onready var l_h: Label = $HUD/MarginContainer/VBoxHorda/LabelHorda
@onready var l_r: Label = $HUD/MarginContainer/VBoxHorda/LabelRestantes
@onready var barrera: StaticBody3D = $Nave/SalidaEspacio/BarreraSalida
@onready var luz_salida: OmniLight3D = $Nave/SalidaEspacio/LuzSalida
var puntos_p1: Array[Node] = []
var puntos_p2: Array[Node] = []
var cola: Array[Dictionary] = []
var horda_num: int = 0
var combate_iniciado: bool = false
var esperando_horda: bool = false
var zona_despejada: bool = false
var nivel_completado: bool = false
var timer: float = 0.0
func _ready() -> void:
	mus.finished.connect(mus.play)
	mus.play()
	puntos_p1 = $PuntosSpawnPiso1.get_children()
	puntos_p2 = $PuntosSpawnPiso2.get_children()
	$Triggers/TriggerArena.body_entered.connect(_on_entrar_arena)
	$Triggers/TriggerSalida.body_entered.connect(_on_entrar_salida)
	_hud_txt("CUARTO DE ESPERA", "CRUZA EL PASILLO AL HANGAR")
func _on_entrar_arena(body: Node3D) -> void:
	if not combate_iniciado and body.is_in_group("jugador"):
		combate_iniciado = true
		_iniciar_horda()
func _iniciar_horda() -> void:
	horda_num += 1
	esperando_horda = false
	cola.clear()
	for i in range(2 + horda_num):
		cola.append({"piso": 1, "torreta": randf() >= 0.8})
	for i in range(1 + horda_num):
		cola.append({"piso": 2, "torreta": randf() < 0.8})
	cola.shuffle()
	timer = 0.4
	_hud_txt("HORDA %d / %d" % [horda_num, total_hordas], "ENEMIGOS: %d" % cola.size())
func _spawnear_uno() -> void:
	var item: Dictionary = cola.pop_back()
	var pt := _elegir_punto(puntos_p2 if int(item["piso"]) == 2 else puntos_p1)
	var esc := spawner_torreta if bool(item["torreta"]) else spawner_scrapper
	if pt and esc:
		var en := esc.instantiate()
		add_child(en)
		en.global_position = pt.global_position
func _elegir_punto(lista: Array[Node]) -> Node3D:
	if lista.is_empty():
		return null
	var idx := range(lista.size())
	idx.shuffle()
	var activos := get_tree().get_nodes_in_group("enemigos")
	for i in idx:
		var cand := lista[i] as Node3D
		if activos.all(func(e): return not is_instance_valid(e) or e.global_position.distance_to(cand.global_position) >= 1.8):
			return cand
	return lista[idx[0]] as Node3D
func _process(delta: float) -> void:
	if not combate_iniciado or zona_despejada:
		return
	if esperando_horda:
		timer -= delta
		if timer <= 0.0:
			_iniciar_horda()
		return
	if not cola.is_empty():
		timer -= delta
		if timer <= 0.0:
			_spawnear_uno()
			timer = 1.05
	var vivos := get_tree().get_nodes_in_group("enemigos").size()
	_hud_txt("HORDA %d / %d" % [horda_num, total_hordas], "ENEMIGOS: %d" % (vivos + cola.size()))
	if cola.is_empty() and vivos == 0:
		if horda_num < total_hordas:
			esperando_horda = true
			timer = 2.8
			_hud_txt("HORDA %d SUPERADA" % horda_num, "SIGUIENTE EN BREVE...")
		else:
			zona_despejada = true
			barrera.collision_layer = 0
			barrera.visible = false
			luz_salida.light_color = Color(0.15, 0.95, 0.65, 1.0)
			_hud_txt("ZONA 1 DESPEJADA", "SALIDA AL ESPACIO ABIERTA")
func _on_entrar_salida(body: Node3D) -> void:
	if zona_despejada and not nivel_completado and body.is_in_group("jugador"):
		nivel_completado = true
		_hud_txt("ZONA 1 COMPLETADA", "PARKOUR ESPACIAL DESBLOQUEADO")
func _hud_txt(titulo: String, detalle: String) -> void:
	l_h.text = titulo
	l_r.text = detalle