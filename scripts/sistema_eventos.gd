class_name SistemaEventos
extends Node
@export var luz_evento: OmniLight3D
@export var pico_destello: float = 5.0
@export var k_destello: float = 6.0
@export var luz_variable: Light3D
@export var color_bajo: Color = Color(0.5, 0.8, 1.0)
@export var color_alto: Color = Color(1.0, 0.2, 0.2)
@export var k_variable: float = 4.0
var variable: float = 0.0
func _ready() -> void:
	for d in get_tree().get_nodes_in_group("disparadores"):
		if d.has_signal("evento"):
			d.evento.connect(_on_evento)
	if luz_evento:
		luz_evento.light_energy = 0.0
func _process(delta: float) -> void:
	if luz_evento:
		luz_evento.light_energy = decaer(luz_evento.light_energy, 0.0, k_destello, delta)
	if luz_variable:
		var vc := clampf(variable, 0.0, 1.0)
		luz_variable.light_color = color_bajo.lerp(color_alto, vc)
		var etarget := 1.0 + 3.0 * vc
		luz_variable.light_energy = decaer(luz_variable.light_energy, etarget, k_variable, delta)
func disparar_destello(pos: Vector3) -> void:
	_on_evento(pos)
func _on_evento(posicion: Vector3) -> void:
	if luz_evento:
		luz_evento.global_position = posicion + Vector3.UP * 1.5
		luz_evento.light_energy = pico_destello
static func decaer(actual: float, base: float, k: float, dt: float) -> float:
	var alpha: float = 1.0 - exp(-k * dt)
	return actual + (base - actual) * alpha
