class_name Mundo
extends Node3D
@export var spawner_scrapper: PackedScene
@export var spawner_torreta: PackedScene
@export var total_hordas: int = 3
@onready var mus: AudioStreamPlayer = $MusicaNivel
@onready var hud: HUD = get_node_or_null("HUD") as HUD
@onready var barrera: StaticBody3D = $Nave/SalidaEspacio/BarreraSalida
@onready var luz_salida: OmniLight3D = $Nave/SalidaEspacio/LuzSalida
@onready var portal: PortalNivel = get_node_or_null("ParkourEspacial/plataforma4/PortalTP") as PortalNivel
var _oleadas: ControladorOleadas; var _zona_despejada: bool = false; var _nivel_completado: bool = false
func _ready() -> void:
	mus.finished.connect(mus.play); mus.play()
	if portal: portal.activar(false)
	_oleadas = ControladorOleadas.new(); add_child(_oleadas)
	_oleadas.configurar(spawner_scrapper, spawner_torreta, $PuntosSpawnPiso1.get_children(), $PuntosSpawnPiso2.get_children(), total_hordas, 1.05, 2.8, 1.8, "HORDA", "ENEMIGOS", _generar_horda)
	_oleadas.estado_cambiado.connect(_hud_txt)
	_oleadas.oleada_superada.connect(func(n: int): _hud_txt("HORDA %d SUPERADA" % n, "SIGUIENTE EN BREVE..."))
	_oleadas.sector_despejado.connect(_on_sector_despejado)
	$Triggers/TriggerArena.body_entered.connect(func(b: Node3D): if b.is_in_group("jugador"): _oleadas.iniciar())
	$Triggers/TriggerSalida.body_entered.connect(_on_entrar_salida)
	_hud_txt("SECTOR 01: REACTOR", "CRUZA EL PASILLO AL NUCLEO")
func _generar_horda(num: int, scrap: PackedScene, torr: PackedScene) -> Array[Dictionary]:
	var q: Array[Dictionary] = []
	for i in range(2 + num): q.append({"escena": torr if randf() >= 0.8 else scrap, "piso": 1})
	for i in range(1 + num): q.append({"escena": torr if randf() < 0.8 else scrap, "piso": 2})
	return q
func _on_sector_despejado() -> void:
	_zona_despejada = true
	if barrera: barrera.collision_layer = 0; barrera.visible = false
	if luz_salida: luz_salida.light_color = Color(0.15, 0.95, 0.65, 1.0)
	if portal: portal.activar(true)
	_hud_txt("ZONA 1 DESPEJADA", "SALIDA AL ESPACIO ABIERTA")
func _on_entrar_salida(body: Node3D) -> void:
	if _zona_despejada and not _nivel_completado and body.is_in_group("jugador"):
		_nivel_completado = true; _hud_txt("ZONA 1 COMPLETADA", "ATRAVIESA EL PARKOUR AL PORTAL")
func _hud_txt(titulo: String, detalle: String) -> void:
	if hud: hud.mostrar_estado(titulo, detalle)
