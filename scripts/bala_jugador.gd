class_name BalaJugador
extends Area3D
@export var vel: float = 55.0
@export var dmg: float = 15.0
@export var rango_max: float = 15.0
var dir: Vector3 = Vector3.FORWARD
var dist_viajada: float = 0.0
var p: CharacterBody3D = null
func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 16
	body_entered.connect(_on_hit)
func _physics_process(delta: float) -> void:
	var paso := vel * delta
	global_position += dir * paso
	dist_viajada += paso
	if dist_viajada >= rango_max:
		queue_free()
func _on_hit(cuerpo: Node) -> void:
	if cuerpo.is_in_group("enemigos"):
		if cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dmg)
		if p and p.has_method("notificar_impacto"):
			p.notificar_impacto(global_position, dmg)
		queue_free()
	elif cuerpo is StaticBody3D:
		queue_free()