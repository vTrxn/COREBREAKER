class_name Scrapper
extends CharacterBody3D
@export var hp: float = 45.0
@export var vel: float = 4.5
@export var dmg_golpe: float = 12.0
@export var cd_ataque: float = 1.45
@export var rango_ataque: float = 1.5
@export var rango_golpe: float = 2.1
@export var delay_golpe: float = 0.73
@onready var audio_hit: AudioStreamPlayer3D = $AudioHit
@onready var modelo: Node3D = $Modelo
var anim_player: AnimationPlayer = null
var player: CharacterBody3D = null
var timer_ataque: float = 0.0
var timer_golpe: float = 0.0
var atacando: bool = false
var grav: float = 14.0
var activo: bool = false
func _ready() -> void:
	player = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	anim_player = modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer if modelo else null
	_iniciar_spawn()
func _iniciar_spawn() -> void:
	if not modelo:
		activo = true
		return
	modelo.scale = Vector3(0.05, 0.05, 0.05)
	var luz := OmniLight3D.new()
	luz.position = Vector3(0.0, 0.8, 0.0)
	luz.light_color = Color(0.25, 1.0, 0.2, 1.0)
	luz.light_energy = 2.5
	luz.omni_range = 3.5
	add_child(luz)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(modelo, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(luz, "light_energy", 0.0, 1.0)
	tw.chain().tween_callback(func(): activo = true; luz.queue_free())
func _physics_process(delta: float) -> void:
	velocity.y -= grav * delta if not is_on_floor() else 0.0
	if not player:
		player = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if not activo or not player:
		velocity = Vector3(0.0, velocity.y, 0.0)
		move_and_slide()
		return
	var pos_p := Vector3(player.global_position.x, global_position.y, player.global_position.z)
	var dist := global_position.distance_to(pos_p)
	var dy := absf(player.global_position.y - global_position.y)
	if atacando:
		_frenar(delta, 6.0)
		if timer_golpe > 0.25 and dist > 0.25:
			look_at(pos_p, Vector3.UP)
		timer_golpe -= delta
		if timer_golpe <= 0.0:
			atacando = false
			if dist <= rango_golpe and dy <= 1.8 and player.has_method("recibir_dano"):
				player.recibir_dano(dmg_golpe)
	elif dist > rango_ataque or dy > 1.6:
		if (anim_player and anim_player.current_animation == "Ataque" and anim_player.is_playing()) or dist <= 0.25:
			_frenar(delta, 6.0)
		else:
			var d := (pos_p - global_position).normalized()
			velocity = Vector3(d.x * vel, velocity.y, d.z * vel)
			look_at(pos_p, Vector3.UP)
			_anim("Caminar", 0.15, false)
	else:
		_frenar(delta, 5.0)
		if dist > 0.25:
			look_at(pos_p, Vector3.UP)
		if timer_ataque <= 0.0:
			atacando = true
			timer_golpe = delay_golpe
			timer_ataque = cd_ataque
			_anim("Ataque", 0.08, true)
	timer_ataque = maxf(0.0, timer_ataque - delta)
	move_and_slide()
func _anim(n: String, b: float, r: bool) -> void:
	if anim_player and anim_player.has_animation(n) and (r or not anim_player.is_playing() or anim_player.current_animation != n):
		if r:
			anim_player.stop()
		anim_player.play(n, b)
func _frenar(delta: float, mult: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, vel * delta * mult)
	velocity.z = move_toward(velocity.z, 0.0, vel * delta * mult)
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
