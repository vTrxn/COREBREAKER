class_name Torreta
extends StaticBody3D
@export var hp: float = 75.0
@export var bala_scene: PackedScene
@export var cd_disparo: float = 2.0
var p: CharacterBody3D = null
var timer_disparo: float = 1.0
func _ready() -> void:
	add_to_group("enemigos")
	collision_layer = 16
	collision_mask = 1 | 8
	p = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
func _physics_process(delta: float) -> void:
	if not p:
		p = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		return
	var look_target := Vector3(p.global_position.x, global_position.y, p.global_position.z)
	look_at(look_target, Vector3.UP)
	timer_disparo -= delta
	if timer_disparo <= 0.0:
		disparar()
		timer_disparo = cd_disparo
func disparar() -> void:
	if not bala_scene or not p:
		return
	var b := bala_scene.instantiate() as Proyectil
	var spawn_pt := global_position + Vector3.UP * 1.0
	b.global_position = spawn_pt
	b.dir = (p.global_position + Vector3.UP * 1.0 - spawn_pt).normalized()
	get_parent().add_child(b)
func recibir_dano(cantidad: float) -> void:
	hp -= cantidad
	if hp <= 0.0:
		if p and p.has_method("ganar_xp"):
			p.ganar_xp()
		queue_free()