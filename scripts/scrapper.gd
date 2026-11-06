class_name Scrapper
extends CharacterBody3D
@export var hp: float = 45.0
@export var vel: float = 4.5
@export var dmg_golpe: float = 12.0
@export var cd_ataque: float = 1.2
@export var rango_ataque: float = 1.5
@onready var audio_hit: AudioStreamPlayer3D = $AudioHit
@onready var mesh: MeshInstance3D = $MeshInstance3D
var player: CharacterBody3D = null
var timer_ataque: float = 0.0
var grav: float = 14.0
var activo: bool = false
func _ready() -> void:
	add_to_group("enemigos")
	collision_layer = 16
	collision_mask = 1 | 8
	player = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	_iniciar_spawn()
func _iniciar_spawn() -> void:
	activo = false
	if mesh:
		var mat := mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat = (mat as StandardMaterial3D).duplicate()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.0
			mesh.set_surface_override_material(0, mat)
		mesh.scale = Vector3(0.05, 0.05, 0.05)
		var luz := OmniLight3D.new()
		luz.position = Vector3(0.0, 0.8, 0.0)
		luz.light_color = Color(1.0, 0.35, 0.15, 1.0)
		luz.light_energy = 2.5
		luz.omni_range = 3.5
		add_child(luz)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(mesh, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if mat is StandardMaterial3D:
			tw.tween_property(mat, "albedo_color:a", 1.0, 1.0)
		tw.tween_property(luz, "light_energy", 0.0, 1.0)
		tw.chain().tween_callback(func():
			activo = true
			if mat is StandardMaterial3D:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			luz.queue_free()
		)
	else:
		activo = true
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= grav * delta
	if not activo:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if not player:
		player = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if player:
		var pos_player := Vector3(player.global_position.x, global_position.y, player.global_position.z)
		var dist := global_position.distance_to(pos_player)
		if dist > rango_ataque:
			var d := (pos_player - global_position).normalized()
			velocity.x = d.x * vel
			velocity.z = d.z * vel
			look_at(pos_player, Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0.0, vel * delta * 5.0)
			velocity.z = move_toward(velocity.z, 0.0, vel * delta * 5.0)
			if timer_ataque <= 0.0:
				if player.has_method("recibir_dano"):
					player.recibir_dano(dmg_golpe)
				timer_ataque = cd_ataque
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	if timer_ataque > 0.0:
		timer_ataque -= delta
	move_and_slide()
func recibir_dano(cantidad: float) -> void:
	if audio_hit:
		audio_hit.play()
	hp -= cantidad
	if hp <= 0.0:
		if player and player.has_method("ganar_xp"):
			player.ganar_xp()
		if audio_hit:
			remove_child(audio_hit)
			get_parent().add_child(audio_hit)
			audio_hit.global_position = global_position
			audio_hit.finished.connect(audio_hit.queue_free)
		queue_free()
