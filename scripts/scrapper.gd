class_name Scrapper
extends CharacterBody3D
@export var hp: float = 45.0
@export var vel: float = 4.5
@export var dmg_golpe: float = 12.0
@export var cd_ataque: float = 1.2
@export var rango_ataque: float = 1.5
@onready var audio_hit: AudioStreamPlayer3D = $AudioHit
var player: CharacterBody3D = null
var timer_ataque: float = 0.0
var grav: float = 14.0
func _ready() -> void:
	add_to_group("enemigos")
	collision_layer = 16
	collision_mask = 1 | 8
	player = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= grav * delta
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