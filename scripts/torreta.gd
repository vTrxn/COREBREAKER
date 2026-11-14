class_name Torreta
extends StaticBody3D
@export var hp: float = 75.0
@export var bala_scene: PackedScene
@export var cd_disparo: float = 2.0
@onready var audio_hit: AudioStreamPlayer3D = $AudioHit
@onready var audio_disp: AudioStreamPlayer3D = get_node_or_null("AudioDisparo") as AudioStreamPlayer3D
@onready var luz_est: OmniLight3D = get_node_or_null("LuzEstado") as OmniLight3D
@onready var modelo: Node3D = $Modelo
var anim_player: AnimationPlayer = null
var p: CharacterBody3D = null
var timer_disparo: float = 1.0
var activo: bool = false
var muerto: bool = false
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
	var cb := func():
		activo = true
		if anim_player and anim_player.has_animation("Idle"): anim_player.play("Idle")
	ParticulasImpacto.iniciar_spawn(self, modelo, Color(0.62, 0.31, 0.87, 1.0), cb)
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
	if luz_est:
		luz_est.light_energy = clampf((0.35 - timer_disparo) / 0.35, 0.0, 1.0) * 4.2 if timer_disparo <= 0.35 else move_toward(luz_est.light_energy, 0.0, delta * 18.0)
	if timer_disparo <= 0.0:
		disparar()
		timer_disparo = cd_disparo
func disparar() -> void:
	if not bala_scene or not p:
		return
	if luz_est: luz_est.light_energy = 6.5
	if audio_disp: audio_disp.play()
	if anim_player and anim_player.has_animation("Disparo"):
		anim_player.stop()
		anim_player.play("Disparo", 0.05)
	var b := bala_scene.instantiate() as Proyectil
	var spawn_pt := global_position + Vector3.UP * 1.0
	get_parent().add_child(b)
	b.global_position = spawn_pt
	b.dir = (p.global_position + Vector3.UP * 1.0 - spawn_pt).normalized()
func recibir_dano(cantidad: float) -> void:
	if muerto: return
	if audio_hit: audio_hit.play()
	hp -= cantidad
	if hp > 0.0:
		if modelo: ParticulasImpacto.flash_malla(modelo)
		return
	muerto = true
	ParticulasImpacto.morir_enemigo(self, Color(0.72, 0.25, 1.0, 1.0), p, audio_hit)