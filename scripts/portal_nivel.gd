class_name PortalNivel
extends Area3D
@export var escena_destino: String = "res://CoolingCorridor.tscn"
@export var titulo_sector: String = "SECTOR 02 // CORREDOR CRIOGENICO"
@export var subtitulo: String = "ESTABILIZA EL NUCLEO DE ENFRIAMIENTO"
@export var radio_portal: float = 1.9
@export var activo: bool = true
var _disparado: bool = false; var _t: float = 0.0
var _aro: MeshInstance3D; var _haz: MeshInstance3D; var _pts: CPUParticles3D; var _luz: OmniLight3D
func _ready() -> void:
	collision_layer = 4; collision_mask = 8
	var col := CollisionShape3D.new()
	var sh := CylinderShape3D.new(); sh.radius = radio_portal; sh.height = 3.2
	col.shape = sh; col.position = Vector3(0, 1.5, 0); add_child(col)
	var mat_aro := StandardMaterial3D.new()
	mat_aro.albedo_color = Color(0.1, 0.92, 1.0); mat_aro.emission_enabled = true
	mat_aro.emission = Color(0.1, 0.92, 1.0); mat_aro.emission_energy_multiplier = 3.2
	var tm := TorusMesh.new(); tm.inner_radius = radio_portal - 0.14; tm.outer_radius = radio_portal
	_aro = MeshInstance3D.new(); _aro.mesh = tm; _aro.material_override = mat_aro
	_aro.position = Vector3(0, 0.25, 0); add_child(_aro)
	var mat_haz := StandardMaterial3D.new()
	mat_haz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat_haz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_haz.cull_mode = BaseMaterial3D.CULL_DISABLED; mat_haz.albedo_color = Color(0.12, 0.88, 1.0, 0.16)
	var cm := CylinderMesh.new(); cm.top_radius = radio_portal * 0.82; cm.bottom_radius = radio_portal * 0.92; cm.height = 3.4
	_haz = MeshInstance3D.new(); _haz.mesh = cm; _haz.material_override = mat_haz
	_haz.position = Vector3(0, 1.75, 0); add_child(_haz)
	_pts = CPUParticles3D.new(); _pts.amount = 28; _pts.lifetime = 1.15
	var pm := SphereMesh.new(); pm.radius = 0.06; pm.height = 0.12
	var pmat := StandardMaterial3D.new(); pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(0.35, 0.96, 1.0, 0.9); pm.material = pmat
	_pts.mesh = pm; _pts.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_pts.emission_ring_radius = radio_portal * 0.85; _pts.emission_ring_inner_radius = radio_portal * 0.55
	_pts.emission_ring_height = 0.2; _pts.direction = Vector3.UP; _pts.spread = 8.0
	_pts.gravity = Vector3.ZERO; _pts.initial_velocity_min = 1.8; _pts.initial_velocity_max = 3.2
	_pts.position = Vector3(0, 0.2, 0); add_child(_pts)
	_luz = OmniLight3D.new(); _luz.light_color = Color(0.12, 0.92, 1.0); _luz.light_energy = 2.6
	_luz.omni_range = 7.0; _luz.position = Vector3(0, 1.8, 0); add_child(_luz)
	body_entered.connect(_on_body_entered)
	activar(activo)
func activar(estado: bool = true) -> void:
	activo = estado; set_deferred("monitoring", estado)
	if _aro: _aro.visible = estado
	if _haz: _haz.visible = estado
	if _pts: _pts.emitting = estado
	if _luz: _luz.visible = estado
func _process(delta: float) -> void:
	if not activo: return
	_t += delta
	if _aro: _aro.position.y = 0.25 + sin(_t * 3.0) * 0.08; _aro.rotate_y(delta * 1.4)
	if _luz: _luz.light_energy = 2.4 + sin(_t * 4.5) * 0.55
func _on_body_entered(body: Node3D) -> void:
	if not activo or _disparado or not body.is_in_group("jugador"): return
	if "muerto" in body and body.muerto: return
	_disparado = true
	if _luz: _luz.light_energy = 6.5
	var tn := get_node_or_null("/root/TransicionNivel")
	if tn and tn.has_method("viajar_a"): tn.viajar_a(escena_destino, titulo_sector, subtitulo)
	else: get_tree().change_scene_to_file(escena_destino)
