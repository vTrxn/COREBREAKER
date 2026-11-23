class_name Custodio
extends CharacterBody3D
signal cambio_vida_boss(actual: float, maxima: float, fase: int, escudo: bool)
signal escudo_activado(num_reactor: int)
signal mortero_activo(en_alerta: bool)
signal boss_derrotado()
@export var hp_max: float = 4500.0; @export var bala_scene: PackedScene = preload("res://Proyectil.tscn"); @export var mortero_scene: PackedScene = preload("res://MorteroFision.tscn")
@onready var modelo: Node3D = $Modelo; @onready var escudo_mesh: MeshInstance3D = get_node_or_null("Escudo") as MeshInstance3D
@onready var luz_est: OmniLight3D = $LuzEstado; @onready var audio_hit: AudioStreamPlayer3D = $AudioHit; @onready var audio_disp: AudioStreamPlayer3D = $AudioDisparo
var hp: float = 4500.0; var fase: int = 1; var activo: bool = false; var muerto: bool = false; var escudo_activo: bool = false; var _escudos_usados: int = 0
var p: CharacterBody3D = null; var grav: float = 16.0; var _mat_p2: StandardMaterial3D; var _pierna_i: Node3D = null; var _pierna_d: Node3D = null
var estado: int = 0; var t_melee: float = 0.0; var t_caminar: float = 3.0; var t_mortero: float = 2.6; var t_paso: float = 0.0
var _tiros_rest: int = 0; var _t_tiro: float = 0.0; var _lado_canon: int = -1
func _ready() -> void:
	collision_layer = 16; collision_mask = 1 | 8; hp = hp_max; p = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	_mat_p2 = StandardMaterial3D.new(); _mat_p2.albedo_color = Color(0.62, 0.31, 0.87); _mat_p2.emission_enabled = true; _mat_p2.emission = Color(0.62, 0.31, 0.87); _mat_p2.emission_energy_multiplier = 3.5
	if modelo: _pierna_i = modelo.find_child("Pierna_Izq", true, false) as Node3D; _pierna_d = modelo.find_child("Pierna_Der", true, false) as Node3D
func despertar() -> void:
	if activo or muerto: return
	t_caminar = 3.0; cambio_vida_boss.emit(hp, hp_max, fase, escudo_activo); ParticulasImpacto.iniciar_spawn(self, modelo, Color(1.0, 0.72, 0.02, 1.0), func(): activo = true; add_to_group("enemigos"))
func desactivar_escudo() -> void:
	escudo_activo = false; fase = _escudos_usados + 1; t_mortero = 1.2
	if escudo_mesh: escudo_mesh.visible = false
	for n_name in ["Nucleo_Emisivo", "Visor_Emisivo"]:
		var mesh := modelo.find_child(n_name, true, false) as MeshInstance3D if (fase >= 2 and modelo) else null
		if mesh and mesh.mesh and mesh.mesh.get_surface_count() > 0: mesh.set_surface_override_material(0, _mat_p2)
	ParticulasImpacto.estallar(self, Color(0.18, 0.92, 1.0, 1.0), 2.2); cambio_vida_boss.emit(hp, hp_max, fase, false)
func _physics_process(delta: float) -> void:
	if muerto: return
	if not is_on_floor(): velocity.y -= grav * delta
	if not activo: move_and_slide(); return
	if not p or not is_instance_valid(p): p = get_tree().get_first_node_in_group("jugador") as CharacterBody3D; return
	look_at(Vector3(p.global_position.x, global_position.y, p.global_position.z), Vector3.UP)
	var dist := global_position.distance_to(p.global_position); var dir_xz := Vector3(p.global_position.x - global_position.x, 0.0, p.global_position.z - global_position.z).normalized()
	if escudo_mesh and escudo_activo: escudo_mesh.rotate_y(delta * 1.6)
	if estado == 1:
		velocity.x = 0.0; velocity.z = 0.0; t_melee -= delta; _animar_piernas(delta, false)
		if luz_est: luz_est.light_color = Color(1.0, 0.72, 0.02); luz_est.light_energy = 5.5
		if t_melee <= 0.0:
			estado = 0; t_caminar = 3.0
			if dist <= 4.9 and p.has_method("recibir_dano"): p.recibir_dano(24.0); p.velocity += dir_xz * 9.0 + Vector3.UP * 3.5
		move_and_slide(); return
	if estado == 2:
		velocity.x = 0.0; velocity.z = 0.0; _animar_piernas(delta, false); _t_tiro -= delta
		if luz_est and _tiros_rest > 0 and _t_tiro > 0.0: luz_est.light_color = Color(1.0, 0.72, 0.02); luz_est.light_energy = 5.5
		if _t_tiro <= 0.0:
			_disparar_gatling(); _tiros_rest -= 1
			if _tiros_rest <= 0: estado = 0; t_caminar = 3.0
			else: _t_tiro = 0.11 if fase == 1 else (0.095 if fase == 2 else 0.08)
		move_and_slide(); _procesar_morteros(delta); return
	var spd := 0.85 if fase == 1 else (1.0 if fase == 2 else 1.15)
	if dist < 4.0 and not escudo_activo: estado = 1; t_melee = 0.45; velocity.x = 0.0; velocity.z = 0.0
	else:
		velocity.x = dir_xz.x * spd; velocity.z = dir_xz.z * spd; t_caminar -= delta
		if luz_est: luz_est.light_energy = move_toward(luz_est.light_energy, 0.0, delta * 16.0)
		if t_caminar <= 0.0: estado = 2; _tiros_rest = 6 if fase == 1 else (8 if fase == 2 else 10); _t_tiro = 0.45
	_animar_piernas(delta, estado == 0 and Vector2(velocity.x, velocity.z).length() > 0.2); move_and_slide(); _procesar_morteros(delta)
func _procesar_morteros(delta: float) -> void:
	if fase < 2: return
	t_mortero -= delta
	if t_mortero <= 0.0: _lanzar_morteros(); t_mortero = 4.8 if fase == 2 else 3.8
func _animar_piernas(delta: float, caminando: bool) -> void:
	t_paso += delta * (2.6 if caminando else 0.0); var ang := sin(t_paso) * 0.28
	if _pierna_i: _pierna_i.rotation.x = ang if caminando else lerp_angle(_pierna_i.rotation.x, 0.0, delta * 10.0)
	if _pierna_d: _pierna_d.rotation.x = -ang if caminando else lerp_angle(_pierna_d.rotation.x, 0.0, delta * 10.0)
func _disparar_gatling() -> void:
	if not bala_scene or not p: return
	_lado_canon = -_lado_canon; var origen := global_transform * Vector3(1.55 * float(_lado_canon), 2.25, -1.9); var dir_base := (p.global_position + Vector3.UP * 1.1 - origen).normalized(); var spread := deg_to_rad(1.8)
	if luz_est: luz_est.light_color = Color(1.0, 0.72, 0.02); luz_est.light_energy = 6.5
	if audio_disp: audio_disp.pitch_scale = 0.85 + randf_range(-0.08, 0.08); audio_disp.play()
	var b := bala_scene.instantiate() as Proyectil; b.configurar_perforante(true); get_parent().add_child(b); b.global_position = origen
	b.dir = dir_base.rotated(Vector3.UP, randf_range(-spread, spread)).rotated(global_transform.basis.x, randf_range(-spread * 0.5, spread * 0.5)).normalized(); b.vel = 30.0 if fase == 1 else (33.0 if fase == 2 else 36.0); b.dmg = 12.0
func _lanzar_morteros() -> void:
	if not mortero_scene or not p: return
	mortero_activo.emit(true)
	if audio_disp: audio_disp.pitch_scale = 0.48; audio_disp.play()
	var base := Vector3(p.global_position.x, 0.0, p.global_position.z); var lat := Vector3(-p.velocity.z, 0.0, p.velocity.x).normalized()
	if lat.length_squared() < 0.01: lat = Vector3.RIGHT
	for pts in [base, base + lat * 4.8, base - lat * 4.8]:
		var m := mortero_scene.instantiate() as Node3D; get_parent().add_child(m); m.global_position = Vector3(clampf(pts.x, -13.5, 13.5), 0.02, clampf(pts.z, -29.5, -2.5))
	get_tree().create_timer(2.0).timeout.connect(func(): if is_inside_tree(): mortero_activo.emit(false))
func recibir_parry(dir_empuje: Vector3) -> bool:
	if muerto or not activo or escudo_activo: return false
	var en_golpe := estado == 1; estado = 0; t_melee = 0.0; t_caminar = 2.0; velocity.x = dir_empuje.x * (10.0 if en_golpe else 4.0); velocity.z = dir_empuje.z * (10.0 if en_golpe else 4.0)
	recibir_dano(50.0 if en_golpe else 25.0, en_golpe); return en_golpe
func recibir_dano(cantidad: float, es_parry: bool = false) -> void:
	if muerto or not activo: return
	if audio_hit: audio_hit.pitch_scale = 1.45 if escudo_activo else 0.7; audio_hit.play()
	if escudo_activo: return
	var umbral := hp_max * (2.0 / 3.0) if _escudos_usados == 0 else (hp_max * (1.0 / 3.0) if _escudos_usados == 1 else -1.0); hp = maxf(0.0, hp - cantidad)
	if umbral > 0.0 and hp <= umbral:
		hp = umbral; _escudos_usados += 1; escudo_activo = true; escudo_activado.emit(_escudos_usados); cambio_vida_boss.emit(hp, hp_max, fase, true)
		if escudo_mesh: escudo_mesh.visible = true
		return
	cambio_vida_boss.emit(hp, hp_max, fase, false)
	if hp > 0.0:
		if modelo: ParticulasImpacto.flash_malla(modelo, Color(0.25, 0.95, 1.0, 1.0) if es_parry else Color.WHITE, 0.08 if es_parry else 0.05)
		return
	muerto = true; activo = false; remove_from_group("enemigos"); mortero_activo.emit(false); boss_derrotado.emit(); ParticulasImpacto.morir_enemigo(self, Color(0.62, 0.31, 0.87, 1.0), p, audio_hit)
