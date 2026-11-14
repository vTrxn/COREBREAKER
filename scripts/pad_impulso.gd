class_name PadImpulso
extends Area3D
@export var impulso_y: float = 12.6
@export var empuje: Vector3 = Vector3.ZERO
@export var cooldown: float = 0.25
@onready var luz: OmniLight3D = get_node_or_null("Luz")
@onready var audio: AudioStreamPlayer3D = get_node_or_null("Audio")
var cds: Dictionary = {}
var t: float = 0.0
func _ready() -> void:
	add_to_group("pads_impulso")
	collision_layer = 4
	collision_mask = 8 | 16
	body_entered.connect(_on_body_entered)
func _process(delta: float) -> void:
	t += delta
	for k in cds.keys():
		cds[k] -= delta
		if cds[k] <= 0.0: cds.erase(k)
	if luz:
		var base := 1.4 + 0.35 * sin(t * 3.5)
		luz.light_energy = lerpf(luz.light_energy, base, minf(1.0, delta * 8.0))
func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D): return
	var id := body.get_instance_id()
	if cds.has(id): return
	var cb := body as CharacterBody3D
	cb.velocity.y = maxf(cb.velocity.y, impulso_y)
	if empuje != Vector3.ZERO:
		cb.velocity.x += empuje.x; cb.velocity.z += empuje.z
	cds[id] = cooldown
	if audio:
		audio.play()
	if luz:
		luz.light_energy = 4.5