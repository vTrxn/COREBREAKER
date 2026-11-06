class_name Proyectil
extends Area3D
@export var vel: float = 17.5
@export var dmg: float = 18.0
@onready var mesh: MeshInstance3D = $MeshInstance3D
var dir: Vector3 = Vector3.FORWARD
var t_vida: float = 5.0
var parreado: bool = false
func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 8
	body_entered.connect(_on_hit)
func _physics_process(delta: float) -> void:
	global_position += dir * vel * delta
	t_vida -= delta
	if t_vida <= 0.0:
		queue_free()
func parrear(nueva_dir: Vector3) -> void:
	parreado = true
	dir = nueva_dir
	vel = 35.0
	dmg = 50.0
	t_vida = 5.0
	collision_mask = 1 | 16
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.1, 0.9, 1.0, 1.0)
		mesh.material_override = mat
func _on_hit(cuerpo: Node) -> void:
	if parreado:
		if cuerpo.is_in_group("enemigos") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dmg)
			queue_free()
		elif cuerpo is StaticBody3D:
			queue_free()
		return
	if cuerpo.is_in_group("jugador"):
		var p_parry := cuerpo.find_child("BrazoParry") as BrazoParry
		if p_parry and p_parry.is_parrying:
			p_parry.desviar(self)
			return
		if cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dmg)
		queue_free()
	elif cuerpo is StaticBody3D:
		queue_free()