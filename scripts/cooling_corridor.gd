class_name CoolingCorridor
extends Node3D
@export_group("Spawners de Enemigos")
@export var spawner_scrapper: PackedScene
@export var spawner_torreta: PackedScene
@export var total_oleadas_reactor: int = 2
@onready var musica: AudioStreamPlayer = get_node_or_null("MusicaNivel")
@onready var hud: HUD = get_node_or_null("HUD") as HUD
@onready var barrera_evacuacion: StaticBody3D = get_node_or_null("SectorReactor/BarreraEvacuacion")
@onready var luz_reactor: OmniLight3D = get_node_or_null("SectorReactor/LuzNucleo")
@onready var portal: PortalNivel = get_node_or_null("SectorReactor/PortalTP") as PortalNivel
var _oleadas: ControladorOleadas
func _ready() -> void:
	if musica: musica.finished.connect(musica.play); musica.play()
	if portal: portal.activar(false)
	var nodo_pts := get_node_or_null("SectorReactor/PuntosSpawn")
	var pts: Array[Node] = nodo_pts.get_children() if nodo_pts else []
	_oleadas = ControladorOleadas.new(); add_child(_oleadas)
	_oleadas.configurar(spawner_scrapper, spawner_torreta, pts, [], total_oleadas_reactor, 1.1, 3.0, 2.0, "DEFENSA", "GUARDIAS RESTANTES", _generar_oleada)
	_oleadas.estado_cambiado.connect(_mostrar_texto_hud)
	_oleadas.oleada_superada.connect(func(_n: int): _mostrar_texto_hud("ALERTA: NUCLEO INESTABLE", "REFUERZOS ENEMIGOS EN CAMINO..."))
	_oleadas.sector_despejado.connect(_despejar_sector_reactor)
	_conectar_trigger("Triggers/TriggerEntrada", func(): _mostrar_texto_hud("DUCTO DE MANTENIMIENTO", "MANTEN [CTRL] PARA DESLIZARTE BAJO LA COMPUERTA"))
	_conectar_trigger("Triggers/TriggerVapor", func(): _mostrar_texto_hud("ALERTA: VALVULAS DE VAPOR", "SINCRONIZA TU AVANCE ENTRE LOS CHORROS CRIOGENICOS"))
	_conectar_trigger("Triggers/TriggerPasarelas", func(): _mostrar_texto_hud("FOSO CRIOGENICO", "USA EL PAD DE IMPULSO Y SALTO EXTENDIDO [CTRL + ESPACIO]"))
	_conectar_trigger("Triggers/TriggerReactor", func(): _oleadas.iniciar())
	_mostrar_texto_hud("SECTOR 02: ENFRIAMIENTO", "ATRAVIESA LOS DUCTOS HACIA EL NUCLEO")
func _generar_oleada(num: int, scrap: PackedScene, torr: PackedScene) -> Array[Dictionary]:
	var q: Array[Dictionary] = []
	for i in range(2 + num): q.append({"escena": scrap, "piso": 1})
	for i in range(num): q.append({"escena": torr, "piso": 1})
	return q
func _despejar_sector_reactor() -> void:
	_mostrar_texto_hud("NUCLEO ESTABILIZADO", "PORTAL DE EXTRACCION ACTIVO")
	if barrera_evacuacion: barrera_evacuacion.collision_layer = 0; barrera_evacuacion.visible = false
	if luz_reactor: luz_reactor.light_color = Color(0.15, 0.95, 0.7); luz_reactor.light_energy = 3.5
	if portal: portal.activar(true)
func _conectar_trigger(ruta: String, metodo: Callable) -> void:
	var trig := get_node_or_null(ruta) as Area3D
	if trig:
		trig.collision_layer = 4; trig.collision_mask = 8
		trig.body_entered.connect(func(body: Node3D): if body.is_in_group("jugador"): metodo.call())
func _mostrar_texto_hud(titulo: String, detalle: String) -> void:
	if hud: hud.mostrar_estado(titulo, detalle)
