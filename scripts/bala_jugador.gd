class_name BalaJugador
extends Area3D
@export var vel: float = 135.0
@export var dmg: float = 25.0
@export var rango_max: float = 30.0
@export var escena_particulas: PackedScene = preload("res://ParticulasImpacto.tscn")
var dir: Vector3 = Vector3.FORWARD
var dist_viajada: float = 0.0
var p: CharacterBody3D = null
var impactado: bool = false
func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 16
	body_entered.connect(_on_hit)
func _physics_process(delta: float) -> void:
	if impactado:
		return
	var pos_ant := global_position
	var paso := vel * delta
	var pos_sig := pos_ant + dir * paso
	var query := PhysicsRayQueryParameters3D.create(pos_ant, pos_sig, collision_mask)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		_procesar_impacto(hit.collider, hit.position, hit.normal)
		return
	global_position = pos_sig
	dist_viajada += paso
	if dist_viajada >= rango_max:
		queue_free()
func _on_hit(cuerpo: Node) -> void:
	if not impactado:
		_procesar_impacto(cuerpo, global_position, -dir)
func _procesar_impacto(cuerpo: Node, pos_hit: Vector3, normal_hit: Vector3) -> void:
	if impactado:
		return
	impactado = true
	if cuerpo and cuerpo.is_in_group("enemigos"):
		if cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dmg)
		if p and p.has_method("notificar_impacto"):
			p.notificar_impacto(pos_hit, dmg)
		var col := Color(0.68, 0.28, 1.0, 1.0) if cuerpo is Torreta else Color(0.15, 1.0, 0.3, 1.0)
		_crear_particulas(pos_hit, normal_hit, col)
	queue_free()
func _crear_particulas(pos_hit: Vector3, normal_hit: Vector3, col: Color) -> void:
	if not escena_particulas:
		return
	var part := escena_particulas.instantiate() as ParticulasImpacto
	var n := normal_hit if normal_hit.length_squared() > 0.01 else -dir
	var spawn_pos := pos_hit + n * 0.05
	part.position = spawn_pos
	get_tree().current_scene.add_child(part)
	part.activar(spawn_pos, n, col)
