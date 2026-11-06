class_name Mundo
extends Node3D
@export var spawner_scrapper: PackedScene
@export var spawner_torreta: PackedScene
@onready var p: Jugador = $Jugador
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_spawn(spawner_scrapper, 5.0, 0.5)
		elif event.keycode == KEY_2:
			_spawn(spawner_torreta, 7.0, 0.5)
func _spawn(escena: PackedScene, dist: float, y_pos: float) -> void:
	if not escena or not p:
		return
	var bot := escena.instantiate() as Node3D
	var fwd := -p.transform.basis.z.normalized()
	var pos := p.global_position + fwd * dist
	pos.y = y_pos
	bot.global_position = pos
	add_child(bot)