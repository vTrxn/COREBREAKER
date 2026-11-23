class_name CustodioArena
extends Node3D
@export var scrapper_scene: PackedScene = preload("res://Scrapper.tscn")
@export var torreta_scene: PackedScene = preload("res://Torreta.tscn")
const PTS_APOYO := [Vector3(-10.5, 0.3, -8.5), Vector3(10.5, 0.3, -8.5), Vector3(-10.5, 0.3, -23.5), Vector3(10.5, 0.3, -23.5)]
@onready var musica: AudioStreamPlayer = get_node_or_null("MusicaNivel") as AudioStreamPlayer
@onready var hud: HUD = get_node_or_null("HUD") as HUD
@onready var boss: Custodio = get_node_or_null("Custodio") as Custodio
@onready var reactor1: ReactorEscudo = get_node_or_null("ReactorEscudo1") as ReactorEscudo
@onready var reactor2: ReactorEscudo = get_node_or_null("ReactorEscudo2") as ReactorEscudo
@onready var luz_alarma: LuzParpadeante = get_node_or_null("LuzAlarma") as LuzParpadeante
@onready var barrera_entrada: StaticBody3D = get_node_or_null("CompuertaEntrada") as StaticBody3D
@onready var barrera_salida: StaticBody3D = get_node_or_null("BarreraEvacuacion") as StaticBody3D
@onready var portal: PortalNivel = get_node_or_null("PortalTP") as PortalNivel
@onready var boss_hud: CanvasLayer = get_node_or_null("BossHUD") as CanvasLayer
@onready var boss_barra: ProgressBar = get_node_or_null("BossHUD/Panel/VBox/BarraVida") as ProgressBar
@onready var boss_fase_lbl: Label = get_node_or_null("BossHUD/Panel/VBox/LabelFase") as Label
var _iniciado: bool = false; var _escudo_activo: bool = false; var _derrotado: bool = false
var _t_spawn: float = 0.0; var _sb_f1: StyleBoxFlat; var _sb_f2: StyleBoxFlat; var _sb_esc: StyleBoxFlat
func _ready() -> void:
	if musica: musica.finished.connect(musica.play); musica.play()
	if portal: portal.activar(false)
	if boss_hud: boss_hud.visible = false
	if barrera_entrada: barrera_entrada.collision_layer = 0; barrera_entrada.visible = false
	_sb_f1 = StyleBoxFlat.new(); _sb_f1.bg_color = Color(1.0, 0.72, 0.02, 1.0)
	_sb_f2 = StyleBoxFlat.new(); _sb_f2.bg_color = Color(0.62, 0.31, 0.87, 1.0)
	_sb_esc = StyleBoxFlat.new(); _sb_esc.bg_color = Color(0.18, 0.88, 1.0, 1.0)
	var trig := get_node_or_null("TriggerCombate") as Area3D
	if trig: trig.body_entered.connect(_on_entrar_arena)
	if boss:
		boss.cambio_vida_boss.connect(_on_boss_vida); boss.escudo_activado.connect(_on_escudo_activado)
		boss.mortero_activo.connect(_on_mortero_alerta); boss.boss_derrotado.connect(_on_boss_derrotado)
	if reactor1: reactor1.reactor_destruido.connect(_on_reactor_destruido)
	if reactor2: reactor2.reactor_destruido.connect(_on_reactor_destruido)
	if hud: hud.mostrar_estado("SECTOR 03: REFINERIA TARTARUS", "AVANZA HACIA LA CAMARA DEL CUSTODIO")
func _process(delta: float) -> void:
	if not _escudo_activo or _derrotado: return
	_t_spawn -= delta
	if _t_spawn <= 0.0: _t_spawn = 3.4; _spawnear_refuerzo()
func _spawnear_refuerzo() -> void:
	var pequenos := 0
	for e in get_tree().get_nodes_in_group("enemigos"):
		if is_instance_valid(e) and not (e is Custodio) and not (e is ReactorEscudo): pequenos += 1
	if pequenos >= 4: return
	var esc := torreta_scene if (randf() < 0.28 and torreta_scene) else scrapper_scene
	if not esc: return
	var en := esc.instantiate() as Node3D
	add_child(en); en.global_position = PTS_APOYO[randi() % PTS_APOYO.size()]
func _on_entrar_arena(body: Node3D) -> void:
	if _iniciado or not body.is_in_group("jugador"): return
	_iniciado = true
	if barrera_entrada: barrera_entrada.collision_layer = 1; barrera_entrada.visible = true
	if boss_hud: boss_hud.visible = true
	if boss: boss.despertar()
	if hud: hud.mostrar_estado("JEFE CUSTODIO ALPHA", "FASE I: ESQUIVA O PARREA LAS RAFAGAS [F]")
func _on_escudo_activado(num_reactor: int) -> void:
	_escudo_activo = true; _t_spawn = 1.6
	var r := reactor1 if num_reactor == 1 else reactor2
	if r: r.activar_objetivo()
	var lado := "IZQUIERDO" if num_reactor == 1 else "DERECHO"
	if hud: hud.mostrar_estado("ESCUDO DEL CUSTODIO ACTIVO", "DESTRUYE EL REACTOR DEL BALCON " + lado)
	_spawnear_refuerzo(); _spawnear_refuerzo()
func _on_reactor_destruido(_indice: int) -> void:
	_escudo_activo = false
	if boss: boss.desactivar_escudo()
	if hud: hud.mostrar_estado("ESCUDO DESTRUIDO", "EL CUSTODIO ES VULNERABLE — ATACA!")
func _on_boss_vida(actual: float, maxima: float, fase: int, escudo: bool) -> void:
	if boss_barra:
		boss_barra.max_value = maxima; boss_barra.value = actual
		boss_barra.add_theme_stylebox_override("fill", _sb_esc if escudo else (_sb_f2 if fase >= 2 else _sb_f1))
	if boss_fase_lbl:
		if escudo: boss_fase_lbl.text = "ESCUDO ACTIVO — DESTRUYE EL REACTOR DEL BALCON"
		elif fase == 1: boss_fase_lbl.text = "FASE I — METRALLETAS GEMELAS"
		elif fase == 2: boss_fase_lbl.text = "FASE II — FISION TERMICA (MORTEROS PURPURA)"
		else: boss_fase_lbl.text = "FASE III — SOBRECARGA CRITICA FINAL"
func _on_mortero_alerta(en_alerta: bool) -> void:
	if luz_alarma and not _derrotado:
		luz_alarma.velocidad = 8.0 if en_alerta else 3.5
		luz_alarma.energia_base = 6.0 if en_alerta else 3.0
func _on_boss_derrotado() -> void:
	_derrotado = true; _escudo_activo = false
	if boss_hud: boss_hud.visible = false
	if barrera_salida: barrera_salida.collision_layer = 0; barrera_salida.visible = false
	if luz_alarma: luz_alarma.light_color = Color(0.22, 1.0, 0.55); luz_alarma.energia_base = 2.8; luz_alarma.velocidad = 1.2
	if portal: portal.activar(true)
	if hud: hud.mostrar_estado("CUSTODIO DERROTADO", "SECTOR CERO DESBLOQUEADO — ENTRA AL PORTAL")
