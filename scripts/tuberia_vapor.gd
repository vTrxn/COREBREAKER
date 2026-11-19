class_name TuberiaVapor
extends Node3D
@export_group("Tiempos de Ciclo")
@export var tiempo_activo: float = 2.0
@export var tiempo_inactivo: float = 2.5
@export var retraso_inicio: float = 0.0
@export var tiempo_alerta_previa: float = 0.6
@export var vapor_continuo: bool = false
@export_group("Parametros de Dano")
@export var dano_tick: float = 12.0
@export var intervalo_dano: float = 0.35
@onready var particulas: CPUParticles3D = get_node_or_null("ParticulasVapor")
@onready var area_dano: Area3D = get_node_or_null("AreaDano")
@onready var luz_aviso: OmniLight3D = get_node_or_null("LuzAviso")
@onready var sonido_vapor: AudioStreamPlayer3D = get_node_or_null("AudioVapor")
var activo: bool = false; var timer_ciclo: float = 0.0
func _ready() -> void:
	if area_dano:
		if "dano_tick" in area_dano: area_dano.dano_tick = dano_tick
		if "intervalo" in area_dano: area_dano.intervalo = intervalo_dano
	if vapor_continuo: _activar_vapor()
	else: timer_ciclo = tiempo_inactivo + retraso_inicio; _desactivar_vapor()
func _physics_process(delta: float) -> void:
	if vapor_continuo: return
	timer_ciclo -= delta
	if not activo and timer_ciclo <= tiempo_alerta_previa and luz_aviso:
		var pulso := sin(timer_ciclo * 25.0) * 0.5 + 0.5
		luz_aviso.light_color = Color(1.0, 0.45, 0.08)
		luz_aviso.light_energy = lerpf(0.6, 3.6, pulso)
	if timer_ciclo <= 0.0:
		if activo: _desactivar_vapor(); timer_ciclo = tiempo_inactivo
		else: _activar_vapor(); timer_ciclo = tiempo_activo
func _activar_vapor() -> void:
	activo = true
	if particulas: particulas.emitting = true
	if area_dano: area_dano.monitoring = true; area_dano.set_physics_process(true)
	if luz_aviso: luz_aviso.light_color = Color(0.2, 0.85, 1.0); luz_aviso.light_energy = 2.8
	if sonido_vapor: sonido_vapor.play()
func _desactivar_vapor() -> void:
	activo = false
	if particulas: particulas.emitting = false
	if area_dano: area_dano.monitoring = false; area_dano.set_physics_process(false)
	if luz_aviso: luz_aviso.light_color = Color(0.12, 0.42, 0.72); luz_aviso.light_energy = 0.9
	if sonido_vapor and sonido_vapor.playing: sonido_vapor.stop()
