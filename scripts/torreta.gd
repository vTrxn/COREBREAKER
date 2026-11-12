class_name Torreta
extends StaticBody3D
@export var hp: float = 75.0
@export var bala_scene: PackedScene
@export var cd_disparo: float = 2.0
@onready var audio_hit: AudioStreamPlayer3D = $AudioHit
@onready var modelo: Node3D = $Modelo
var anim_player: AnimationPlayer = null
var p: CharacterBody3D = null
var timer_disparo: float = 1.0
var activo: bool = false
func _ready() -> void:
	add_to_group("enemigos")
	collision_layer = 16
	collision_mask = 1 | 8
	p = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if modelo:
		anim_player = modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_iniciar_spawn()
func _iniciar_spawn() -> void:
	activo = false
	if modelo:
		modelo.scale = Vector3(0.05, 0.05, 0.05)
		var luz := OmniLight3D.new()
		luz.position = Vector3(0.0, 0.8, 0.0)
		luz.light_color = Color(0.62, 0.31, 0.87, 1.0)
		luz.light_energy = 2.5
		luz.omni_range = 3.5
		add_child(luz)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(modelo, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(luz, "light_energy", 0.0, 1.0)
		tw.chain().tween_callback(func():
			activo = true
			if anim_player and anim_player.has_animation("Idle"):
				anim_player.play("Idle")
			luz.queue_free()
		)
	else:
		activo = true
func _physics_process(delta: float) -> void:
	if not activo:
		return
	if not p:
		p = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		return
	var look_target := Vector3(p.global_position.x, global_position.y, p.global_position.z)
	look_at(look_target, Vector3.UP)
	if anim_player and anim_player.has_animation("Idle") and not anim_player.is_playing():
		anim_player.play("Idle", 0.15)
	timer_disparo -= delta
	if timer_disparo <= 0.0:
		disparar()
		timer_disparo = cd_disparo
func disparar() -> void:
	if not bala_scene or not p:
		return
	if anim_player and anim_player.has_animation("Disparo"):
		anim_player.stop()
		anim_player.play("Disparo", 0.05)
	var b := bala_scene.instantiate() as Proyectil
	var spawn_pt := global_position + Vector3.UP * 1.0
	get_parent().add_child(b)
	b.global_position = spawn_pt
	b.dir = (p.global_position + Vector3.UP * 1.0 - spawn_pt).normalized()
func recibir_dano(cantidad: float) -> void:
	if audio_hit:
		audio_hit.play()
	hp -= cantidad
	if hp <= 0.0:
		if p and p.has_method("ganar_xp"):
			p.ganar_xp()
		if audio_hit:
			remove_child(audio_hit)
			get_parent().add_child(audio_hit)
			audio_hit.global_position = global_position
			audio_hit.finished.connect(audio_hit.queue_free)
		queue_free()