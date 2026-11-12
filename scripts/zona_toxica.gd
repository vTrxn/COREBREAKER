class_name ZonaToxica
extends Area3D
@export var dano_tick: float = 7.0
@export var intervalo: float = 0.45
var dentro: Array[Node3D] = []
var timer: float = 0.0
func _ready() -> void:
	collision_layer = 4
	collision_mask = 8
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
func _physics_process(delta: float) -> void:
	if dentro.is_empty():
		return
	timer -= delta
	if timer > 0.0:
		return
	timer = intervalo
	for b in dentro:
		if is_instance_valid(b) and b.has_method("recibir_dano"):
			b.recibir_dano(dano_tick)
func _on_enter(body: Node3D) -> void:
	if body.is_in_group("jugador") and not dentro.has(body):
		dentro.append(body)
		timer = minf(timer, 0.12)
func _on_exit(body: Node3D) -> void:
	dentro.erase(body)