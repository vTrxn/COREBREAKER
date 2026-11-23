class_name Mundo
extends Node3D
@export var spawner_scrapper: PackedScene
@export var spawner_torreta: PackedScene
@export var total_hordas: int = 3
@onready var mus: AudioStreamPlayer = $MusicaNivel
@onready var hud: HUD = get_node_or_null("HUD") as HUD
@onready var barrera: StaticBody3D = $Nave/SalidaEspacio/BarreraSalida
@onready var luz_salida: OmniLight3D = $Nave/SalidaEspacio/LuzSalida
@onready var portal: PortalNivel = get_node_or_null("TunelParkour/PlataformaMeta/PortalTP") as PortalNivel
@onready var jugador: Jugador = get_node_or_null("Jugador") as Jugador
var _oleadas: ControladorOleadas; var _zona_despejada: bool = false; var _nivel_completado: bool = false
var _pos_respawn: Vector3 = Vector3(0.0, 0.4, 10.0); var _cp2_activo: bool = false; var _cd_respawn: float = 0.0
func _ready() -> void:
	mus.finished.connect(mus.play); mus.play()
	if portal: portal.activar(false)
	_oleadas = ControladorOleadas.new(); add_child(_oleadas)
	_oleadas.configurar(spawner_scrapper, spawner_torreta, $PuntosSpawnPiso1.get_children(), $PuntosSpawnPiso2.get_children(), total_hordas, 1.05, 2.8, 1.8, "HORDA", "ENEMIGOS", _generar_horda)
	_oleadas.estado_cambiado.connect(_hud_txt)
	_oleadas.oleada_superada.connect(func(n: int): _hud_txt("HORDA %d SUPERADA" % n, "SIGUIENTE EN BREVE..."))
	_oleadas.sector_despejado.connect(_on_sector_despejado)
	_conectar_area("Triggers/TriggerArena", func(_b: Node3D): _oleadas.iniciar())
	_conectar_area("Triggers/TriggerSalida", _on_entrar_salida)
	_conectar_area("Triggers/TriggerCheckpoint2", _on_checkpoint2)
	_conectar_area("Triggers/TriggerSlide", func(_b: Node3D): _hud_txt("COMPUERTA DE MANTENIMIENTO", "MANTEN [CTRL] PARA DESLIZARTE POR DEBAJO"))
	_conectar_area("Triggers/ZonaCaidaTunel", _respawnear_jugador)
	_hud_txt("SECTOR 01: REACTOR", "CRUZA EL PASILLO AL NUCLEO")
func _physics_process(delta: float) -> void:
	if _cd_respawn > 0.0: _cd_respawn = maxf(0.0, _cd_respawn - delta)
	if jugador and not jugador.muerto and jugador.global_position.y < -5.5:
		_respawnear_jugador(jugador)
func _conectar_area(ruta: String, cb: Callable) -> void:
	var a := get_node_or_null(ruta) as Area3D
	if a: a.body_entered.connect(func(b: Node3D): if b.is_in_group("jugador"): cb.call(b))
func _generar_horda(num: int, scrap: PackedScene, torr: PackedScene) -> Array[Dictionary]:
	var q: Array[Dictionary] = []
	for i in range(2 + num): q.append({"escena": torr if randf() >= 0.8 else scrap, "piso": 1})
	for i in range(1 + num): q.append({"escena": torr if randf() < 0.8 else scrap, "piso": 2})
	return q
func _on_sector_despejado() -> void:
	_zona_despejada = true; _pos_respawn = Vector3(0.0, 0.4, -18.8)
	if barrera: barrera.collision_layer = 0; barrera.visible = false
	if luz_salida: luz_salida.light_color = Color(0.15, 0.95, 0.65, 1.0)
	if portal: portal.activar(true)
	_hud_txt("ZONA 1 DESPEJADA", "TUNEL DE EXTRACCION DESBLOQUEADO")
func _on_entrar_salida(_body: Node3D) -> void:
	if _zona_despejada and not _nivel_completado:
		_nivel_completado = true; _pos_respawn = Vector3(0.0, 0.4, -18.8)
		_hud_txt("TUNEL DEL REACTOR", "ATRAVIESA EL PARKOUR HACIA EL PORTAL")
func _on_checkpoint2(_body: Node3D) -> void:
	if not _cp2_activo:
		_cp2_activo = true; _pos_respawn = Vector3(0.0, 2.0, -41.2)
		_hud_txt("CHECKPOINT ALCANZADO", "USA EL PAD DE IMPULSO PARA SALTAR EL FOSO")
func _respawnear_jugador(body: Node3D) -> void:
	if _cd_respawn > 0.0 or not (body is Jugador): return
	var j := body as Jugador
	if j.muerto: return
	_cd_respawn = 0.45
	j.cancelar_deslizamiento(); j.velocity = Vector3.ZERO
	j.global_position = _pos_respawn; j.rotation.y = 0.0
	if j.hp > 15.0: j.recibir_dano(10.0)
	_hud_txt("CAIDA EN EL FOSO", "REINICIADO EN EL ULTIMO CHECKPOINT")
func _hud_txt(titulo: String, detalle: String) -> void:
	if hud: hud.mostrar_estado(titulo, detalle)
