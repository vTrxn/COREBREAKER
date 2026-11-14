class_name Proyectil
extends Area3D
@export var vel: float = 17.5
@export var dmg: float = 18.0
@export var escena_particulas: PackedScene = preload("res://ParticulasImpacto.tscn")
@onready var mesh: MeshInstance3D = $MeshInstance3D
var dir: Vector3 = Vector3.FORWARD
var t_vida: float = 5.0
var parreado: bool = false
var impactado: bool = false
func _ready() -> void:
	add_to_group("proyectiles")
	collision_layer = 2
	collision_mask = 1 | 8
	body_entered.connect(_on_hit)
func _physics_process(delta: float) -> void:
	if impactado:
		return
	var pos_ant := global_position
	var pos_sig := pos_ant + dir * vel * delta
	var query := PhysicsRayQueryParameters3D.create(pos_ant, pos_sig, collision_mask)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		_procesar_impacto(hit.collider, hit.position, hit.normal)
		return
	global_position = pos_sig
	t_vida -= delta
	if t_vida <= 0.0:
		queue_free()
func parrear(nueva_dir: Vector3) -> void:
	parreado = true
	dir = nueva_dir.normalized()
	vel = 55.0
	dmg = maxf(50.0, dmg * 2.0)
	t_vida = 4.0
	collision_mask = 1 | 16
	scale = Vector3(1.35, 1.35, 1.35)
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.25, 0.95, 1.0, 1.0)
		mesh.material_override = mat
func _on_hit(cuerpo: Node) -> void:
	if not impactado:
		_procesar_impacto(cuerpo, global_position, -dir)
func _procesar_impacto(cuerpo: Node, pos_hit: Vector3, normal_hit: Vector3) -> void:
	if impactado or not cuerpo:
		return
	if parreado:
		if cuerpo.is_in_group("enemigos") and cuerpo.has_method("recibir_dano"):
			impactado = true
			cuerpo.recibir_dano(dmg)
			var jug := get_tree().get_first_node_in_group("jugador")
			if jug and jug.has_method("notificar_impacto"):
				jug.notificar_impacto(pos_hit, dmg)
			_crear_particulas(pos_hit, normal_hit, Color(0.2, 0.92, 1.0, 1.0))
			queue_free()
		elif cuerpo is StaticBody3D:
			impactado = true
			_crear_particulas(pos_hit, normal_hit, Color(0.2, 0.92, 1.0, 1.0))
			queue_free()
		return
	if cuerpo.is_in_group("jugador"):
		var jug := cuerpo as Jugador
		if jug and jug.parry_b and jug.parry_b.is_parrying:
			jug.parry_b.desviar(self)
			return
		impactado = true
		if cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dmg)
		queue_free()
	elif cuerpo is StaticBody3D:
		impactado = true
		queue_free()
func _crear_particulas(pos_hit: Vector3, normal_hit: Vector3, col: Color) -> void:
	if not escena_particulas or not is_inside_tree():
		return
	var part := escena_particulas.instantiate() as ParticulasImpacto
	var n := normal_hit if normal_hit.length_squared() > 0.01 else -dir
	part.position = pos_hit + n * 0.05
	var cont := get_tree().current_scene if get_tree().current_scene else get_parent()
	cont.add_child(part)
	part.activar(pos_hit + n * 0.05, n, col)