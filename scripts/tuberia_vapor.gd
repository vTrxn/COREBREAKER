class_name TuberiaVapor
extends Node3D

## Tubería de vapor industrial con temporizador de emisiones y daño por contacto.
## Creado para el nivel "Corredor de Enfriamiento y Reactores" en COREBREAKER.

@export_group("Tiempos de Ciclo")
@export var tiempo_activo: float = 2.0         # Tiempo que el vapor está saliendo e inflige daño
@export var tiempo_inactivo: float = 2.5       # Tiempo en reposo (seguro para cruzar)
@export var retraso_inicio: float = 0.0        # Desfase inicial para crear patrones alternados
@export var tiempo_alerta_previa: float = 0.6  # Parpadeo de luz antes del escape de vapor
@export var vapor_continuo: bool = false       # Si es true, siempre emite vapor peligroso

@export_group("Parámetros de Daño")
@export var dano_tick: float = 12.0            # Daño por cada tick al jugador
@export var intervalo_dano: float = 0.35       # Cadencia con la que se aplica el daño continuo

# Referencias a los nodos hijos
@onready var particulas: CPUParticles3D = get_node_or_null("ParticulasVapor")
@onready var area_dano: Area3D = get_node_or_null("AreaDano")
@onready var luz_aviso: OmniLight3D = get_node_or_null("LuzAviso")
@onready var sonido_vapor: AudioStreamPlayer3D = get_node_or_null("AudioVapor")

# Estado interno
var activo: bool = false
var en_alerta: bool = false
var timer_ciclo: float = 0.0
var timer_dano: float = 0.0
var cuerpos_dentro: Array[Node3D] = []

func _ready() -> void:
	# Ajustamos las capas de física de la zona peligrosa
	# Capa 3 (valor binario 4: Sensores) y Máscara 4 (valor binario 8: Jugador)
	if area_dano:
		area_dano.collision_layer = 4
		area_dano.collision_mask = 8
		area_dano.body_entered.connect(_on_cuerpo_entro)
		area_dano.body_exited.connect(_on_cuerpo_salio)
	
	if vapor_continuo:
		_activar_vapor()
	else:
		timer_ciclo = tiempo_inactivo + retraso_inicio
		_desactivar_vapor()

func _physics_process(delta: float) -> void:
	if not vapor_continuo:
		_procesar_ciclo(delta)
	
	# Si el vapor está activo y hay entidades adentro, aplicamos daño por tick
	if activo and not cuerpos_dentro.is_empty():
		timer_dano -= delta
		if timer_dano <= 0.0:
			timer_dano = intervalo_dano
			for cuerpo in cuerpos_dentro:
				if is_instance_valid(cuerpo) and cuerpo.has_method("recibir_dano"):
					cuerpo.recibir_dano(dano_tick)

func _procesar_ciclo(delta: float) -> void:
	timer_ciclo -= delta
	
	# Fase de advertencia: La luz parpadea antes de que salga el vapor
	if not activo and timer_ciclo <= tiempo_alerta_previa:
		if not en_alerta:
			en_alerta = true
		if luz_aviso:
			# Efecto de advertencia naranja/roja intermitente
			var pulso := sin(timer_ciclo * 25.0) * 0.5 + 0.5
			luz_aviso.light_color = Color(1.0, 0.45, 0.08)
			luz_aviso.light_energy = lerpf(0.5, 3.5, pulso)
	
	# Transición entre activo e inactivo
	if timer_ciclo <= 0.0:
		if activo:
			_desactivar_vapor()
			timer_ciclo = tiempo_inactivo
		else:
			_activar_vapor()
			timer_ciclo = tiempo_activo

func _activar_vapor() -> void:
	activo = true
	en_alerta = false
	timer_dano = 0.05 # Daño casi inmediato si te pilla desprevenido
	
	if particulas:
		particulas.emitting = true
	
	if area_dano:
		area_dano.monitoring = true
	
	if luz_aviso:
		luz_aviso.light_color = Color(0.2, 0.85, 1.0) # Vapor criogénico brillante
		luz_aviso.light_energy = 2.8
	
	if sonido_vapor and not sonido_vapor.playing:
		sonido_vapor.play()

func _desactivar_vapor() -> void:
	activo = false
	en_alerta = false
	
	if particulas:
		particulas.emitting = false
	
	if area_dano:
		area_dano.monitoring = false
	
	if luz_aviso:
		luz_aviso.light_color = Color(0.12, 0.35, 0.6) # Azul tenue de reposo
		luz_aviso.light_energy = 0.8
	
	if sonido_vapor and sonido_vapor.playing:
		sonido_vapor.stop()

func _on_cuerpo_entro(body: Node3D) -> void:
	if body.is_in_group("jugador") and not cuerpos_dentro.has(body):
		cuerpos_dentro.append(body)
		if activo and body.has_method("recibir_dano"):
			body.recibir_dano(dano_tick)

func _on_cuerpo_salio(body: Node3D) -> void:
	cuerpos_dentro.erase(body)
