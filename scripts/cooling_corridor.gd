class_name CoolingCorridor
extends Node3D

## Controlador principal del nivel "Corredor de Enfriamiento y Reactores"
## Diseñado para COREBREAKER (Godot 4) con estructura modular y lógica de progresión.

@export_group("Spawners de Enemigos")
@export var spawner_scrapper: PackedScene
@export var spawner_torreta: PackedScene
@export var total_oleadas_reactor: int = 2

# Referencias a nodos del nivel
@onready var jugador: Jugador = get_node_or_null("Jugador")
@onready var musica: AudioStreamPlayer = get_node_or_null("MusicaNivel")
@onready var hud: HUD = get_node_or_null("HUD")

# Referencias a elementos interactivos del sector del reactor
@onready var barrera_evacuacion: StaticBody3D = get_node_or_null("SectorReactor/BarreraEvacuacion")
@onready var luz_reactor: OmniLight3D = get_node_or_null("SectorReactor/LuzNucleo")
@onready var baliza_extraccion: Node3D = get_node_or_null("SectorReactor/BalizaExtraccion")

# Puntos de spawn para el combate final en el núcleo
var puntos_spawn: Array[Node] = []
var cola_enemigos: Array[Dictionary] = []
var oleada_actual: int = 0
var combate_reactor_iniciado: bool = false
var esperando_siguiente_oleada: bool = false
var reactor_estabilizado: bool = false
var nivel_completado: bool = false
var timer_logica: float = 0.0

func _ready() -> void:
	# Configurar y reproducir música en bucle
	if musica:
		musica.finished.connect(musica.play)
		musica.play()
	
	# Recolectar puntos de aparición de enemigos
	var nodo_puntos := get_node_or_null("SectorReactor/PuntosSpawn")
	if nodo_puntos:
		puntos_spawn = nodo_puntos.get_children()
	
	# Conectar disparadores de zona (Triggers de volumen Area3D)
	_conectar_trigger("Triggers/TriggerEntrada", _on_entrar_ductos)
	_conectar_trigger("Triggers/TriggerVapor", _on_entrar_zona_vapor)
	_conectar_trigger("Triggers/TriggerPasarelas", _on_entrar_pasarelas)
	_conectar_trigger("Triggers/TriggerReactor", _on_entrar_camara_reactor)
	_conectar_trigger("Triggers/TriggerFinal", _on_alcanzar_extraccion)
	
	# Mensaje de bienvenida inicial en el HUD
	_mostrar_texto_hud("CORREDOR DE ENFRIAMIENTO", "OBJETIVO: ATRAVIESA LOS DUCTOS HACIA EL NUCLEO")

func _process(delta: float) -> void:
	if not combate_reactor_iniciado or reactor_estabilizado:
		return
	
	# Manejar tiempo entre oleadas
	if esperando_siguiente_oleada:
		timer_logica -= delta
		if timer_logica <= 0.0:
			_iniciar_oleada_reactor()
		return
	
	# Manejar aparición pausada de cada enemigo en la oleada
	if not cola_enemigos.is_empty():
		timer_logica -= delta
		if timer_logica <= 0.0:
			_spawnear_siguiente_enemigo()
			timer_logica = 1.1
	
	# Monitorear cantidad de enemigos activos
	var enemigos_vivos := get_tree().get_nodes_in_group("enemigos").size()
	var restantes := enemigos_vivos + cola_enemigos.size()
	_actualizar_contador_hud(oleada_actual, total_oleadas_reactor, restantes)
	
	# Si se eliminaron todos los enemigos de la oleada
	if cola_enemigos.is_empty() and enemigos_vivos == 0:
		if oleada_actual < total_oleadas_reactor:
			esperando_siguiente_oleada = true
			timer_logica = 3.0
			_mostrar_texto_hud("ALERTA: NUCLEO INESTABLE", "REFUERZOS ENEMIGOS EN CAMINO...")
		else:
			_despejar_sector_reactor()

## Inicia una oleada de combate en la plataforma del reactor
func _iniciar_oleada_reactor() -> void:
	oleada_actual += 1
	esperando_siguiente_oleada = false
	cola_enemigos.clear()
	
	# Composición de enemigos para la oleada (más enemigos en oleadas posteriores)
	var cant_scrappers := 2 + oleada_actual
	var cant_torretas := 1 + (oleada_actual - 1)
	
	for i in range(cant_scrappers):
		cola_enemigos.append({"tipo": "scrapper"})
	for i in range(cant_torretas):
		cola_enemigos.append({"tipo": "torreta"})
	
	cola_enemigos.shuffle()
	timer_logica = 0.5
	_mostrar_texto_hud("DEFENSA DEL NUCLEO: OLEADA %d/%d" % [oleada_actual, total_oleadas_reactor], "ELIMINA A LOS GUARDIAS DEL SISTEMA")

## Spawnea un enemigo de la cola en uno de los puntos libres
func _spawnear_siguiente_enemigo() -> void:
	if cola_enemigos.is_empty():
		return
	var item: Dictionary = cola_enemigos.pop_back()
	var escena_a_crear := spawner_torreta if item["tipo"] == "torreta" else spawner_scrapper
	
	if not escena_a_crear or puntos_spawn.is_empty():
		return
	
	var punto := _obtener_punto_spawn_valido()
	if punto:
		var instancia: Node3D = escena_a_crear.instantiate()
		add_child(instancia)
		instancia.global_position = punto.global_position

func _obtener_punto_spawn_valido() -> Node3D:
	var lista_puntos := puntos_spawn.duplicate()
	lista_puntos.shuffle()
	var enemigos_actuales := get_tree().get_nodes_in_group("enemigos")
	
	for pt in lista_puntos:
		var n3d := pt as Node3D
		if not n3d:
			continue
		# Intentamos que no aparezcan pegados a otro enemigo
		var libre := true
		for e in enemigos_actuales:
			if is_instance_valid(e) and e.global_position.distance_to(n3d.global_position) < 2.0:
				libre = false
				break
		if libre:
			return n3d
	
	return lista_puntos[0] as Node3D

## Desbloquea la salida una vez estabilizado el reactor
func _despejar_sector_reactor() -> void:
	reactor_estabilizado = true
	_mostrar_texto_hud("NUCLEO ESTABILIZADO", "PLATAFORMA DE EVACUACION ACTIVA")
	
	# Desactivar barrera de seguridad
	if barrera_evacuacion:
		barrera_evacuacion.collision_layer = 0
		barrera_evacuacion.visible = false
	
	# Cambiar iluminación del reactor a un verde/cian pacífico
	if luz_reactor:
		luz_reactor.light_color = Color(0.15, 0.95, 0.7)
		luz_reactor.light_energy = 3.5

# ==================== TRIGGERS Y EVENTOS DE ZONA ====================

func _conectar_trigger(ruta: String, metodo: Callable) -> void:
	var trig := get_node_or_null(ruta) as Area3D
	if trig:
		trig.collision_layer = 4 # Sensores
		trig.collision_mask = 8  # Jugador
		trig.body_entered.connect(func(body: Node3D):
			if body.is_in_group("jugador"):
				metodo.call()
		)

func _on_entrar_ductos() -> void:
	_mostrar_texto_hud("DUCTO DE MANTENIMIENTO", "TIPS: MANTEN [CTRL] PARA DESLIZARTE BAJO ESTRUCTURAS")

func _on_entrar_zona_vapor() -> void:
	_mostrar_texto_hud("ALERTA: VAPOR DE ENFRIAMIENTO", "CUIDADO CON LAS VALVULAS: SINCRONIZA TU AVANCE O DESLIZATE")

func _on_entrar_pasarelas() -> void:
	_mostrar_texto_hud("FOSO CRIOGENICO", "USA SALTO EXTENDIDO [CTRL + ESPACIO] O EL PAD DE IMPULSO PARA CRUZAR")

func _on_entrar_camara_reactor() -> void:
	if not combate_reactor_iniciado:
		combate_reactor_iniciado = true
		_iniciar_oleada_reactor()

func _on_alcanzar_extraccion() -> void:
	if reactor_estabilizado and not nivel_completado:
		nivel_completado = true
		_mostrar_texto_hud("SECTOR COMPLETADO", "SISTEMAS DE ENFRIAMIENTO RESTAURADOS CON EXITO")

# ==================== UTILIDADES DE HUD ====================

func _mostrar_texto_hud(titulo: String, detalle: String) -> void:
	if not hud:
		return
	var label_h := hud.find_child("LabelHorda") as Label
	var label_r := hud.find_child("LabelRestantes") as Label
	if label_h:
		label_h.text = titulo
	if label_r:
		label_r.text = detalle

func _actualizar_contador_hud(horda: int, max_h: int, restantes: int) -> void:
	if not hud:
		return
	var label_h := hud.find_child("LabelHorda") as Label
	var label_r := hud.find_child("LabelRestantes") as Label
	if label_h:
		label_h.text = "DEFENSA: %d / %d" % [horda, max_h]
	if label_r:
		label_r.text = "GUARDIAS RESTANTES: %d" % restantes
