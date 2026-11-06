class_name Proyectil
extends Area3D
@export var vel: float = 14.0
@export var dmg: float = 18.0
var dir: Vector3 = Vector3.FORWARD
var t_vida: float = 5.0
func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 8
	body_entered.connect(_on_hit)
func _physics_process(delta: float) -> void:
	global_position += dir * vel * delta
	t_vida -= delta
	if t_vida <= 0.0:
		queue_free()
func _on_hit(cuerpo: Node) -> void:
	if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_dano"):
		cuerpo.recibir_dano(dmg)
		queue_free()
	elif cuerpo is StaticBody3D:
		queue_free()