class_name Mundo
extends Node3D
@export var spawner_scrapper: PackedScene
@export var spawner_torreta: PackedScene
@onready var p: Jugador = $Jugador
@onready var mus: AudioStreamPlayer = $MusicaNivel
@onready var hud: HUD = $HUD
var puntos_spawn: Array[Vector3] = [
	Vector3(-10.5, 0.5, -10.5),
	Vector3(0.0, 0.5, -12.0),
	Vector3(10.5, 0.5, -10.5),
	Vector3(10.5, 0.5, 10.5),
	Vector3(0.0, 0.5, 12.0),
	Vector3(-10.5, 0.5, 10.5)
]
var horda_num: int = 0
var enemigos_por_spawnear: int = 0
var timer_spawn: float = 1.0
var timer_entre_hordas: float = 2.5
var en_pausa: bool = true
var idx_spawn: int = 0
func _ready() -> void:
	if mus:
		if mus.stream is AudioStreamMP3:
			(mus.stream as AudioStreamMP3).loop = true
		mus.volume_db = -30.0
		var tw := create_tween()
		tw.tween_property(mus, "volume_db", 0.0, 2.5)
	if has_node("PuntosSpawn"):
		var n := get_node("PuntosSpawn")
		if n.get_child_count() > 0:
			puntos_spawn.clear()
			for c in n.get_children():
				if c is Node3D:
					puntos_spawn.append(c.global_position)
func _process(delta: float) -> void:
	var vivos := _contar_enemigos_vivos()
	if en_pausa:
		timer_entre_hordas -= delta
		if timer_entre_hordas <= 0.0:
			_iniciar_horda()
	else:
		if enemigos_por_spawnear > 0:
			timer_spawn -= delta
			if timer_spawn <= 0.0:
				timer_spawn = randf_range(2.0, 3.0)
				_spawnear_tanda()
		elif vivos == 0:
			en_pausa = true
			timer_entre_hordas = 3.5
	if hud and hud.has_method("actualizar_horda"):
		hud.actualizar_horda(horda_num, vivos + enemigos_por_spawnear)
func _iniciar_horda() -> void:
	horda_num += 1
	en_pausa = false
	enemigos_por_spawnear = 2 + horda_num * 2
	timer_spawn = 0.5
func _spawnear_tanda() -> void:
	var cantidad := mini(randi_range(1, 2), enemigos_por_spawnear)
	for i in range(cantidad):
		var escena := spawner_scrapper
		if horda_num >= 2 and randf() > 0.6:
			escena = spawner_torreta
		var pt := _obtener_punto_spawn()
		_instanciar_enemigo(escena, pt)
		enemigos_por_spawnear -= 1
func _obtener_punto_spawn() -> Vector3:
	if puntos_spawn.is_empty():
		return Vector3(0.0, 0.5, -6.0)
	var pt := puntos_spawn[idx_spawn % puntos_spawn.size()]
	idx_spawn += 1
	return pt
func _instanciar_enemigo(escena: PackedScene, pos: Vector3) -> void:
	if not escena:
		return
	var bot := escena.instantiate() as Node3D
	add_child(bot)
	bot.global_position = pos
func _contar_enemigos_vivos() -> int:
	var c := 0
	for e in get_tree().get_nodes_in_group("enemigos"):
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			c += 1
	return c
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_instanciar_enemigo(spawner_scrapper, _obtener_punto_spawn())
		elif event.keycode == KEY_2:
			_instanciar_enemigo(spawner_torreta, _obtener_punto_spawn())