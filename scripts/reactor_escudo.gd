class_name ReactorEscudo
extends StaticBody3D
signal reactor_destruido(indice: int)
@export var indice: int = 1
@export var hp_max: float = 240.0
@onready var modelo: Node3D = $Modelo
@onready var luz: OmniLight3D = $LuzEstado
@onready var haz: MeshInstance3D = get_node_or_null("HazGuia") as MeshInstance3D
@onready var audio_hit: AudioStreamPlayer3D = get_node_or_null("AudioHit") as AudioStreamPlayer3D
var hp: float = 240.0; var vulnerable: bool = false; var destruido: bool = false; var _t: float = 0.0
func _ready() -> void:
	hp = hp_max; collision_layer = 1; collision_mask = 0
	if haz: haz.visible = false
	if luz: luz.light_color = Color(0.15, 0.35, 0.55); luz.light_energy = 0.8
func activar_objetivo() -> void:
	if destruido: return
	vulnerable = true; hp = hp_max; collision_layer = 1 | 16; add_to_group("enemigos")
	if haz: haz.visible = true
	if luz: luz.light_color = Color(1.0, 0.45, 0.08); luz.light_energy = 4.5
func _process(delta: float) -> void:
	if not vulnerable or destruido: return
	_t += delta
	if luz: luz.light_energy = 3.5 + sin(_t * 10.0) * 1.4
	if haz: haz.rotate_y(delta * 2.2)
func recibir_dano(cantidad: float, _es_parry: bool = false) -> void:
	if destruido or not vulnerable: return
	if audio_hit: audio_hit.play()
	hp = maxf(0.0, hp - minf(cantidad, 140.0))
	if hp > 0.0:
		if modelo: ParticulasImpacto.flash_malla(modelo, Color(1.0, 0.72, 0.02, 1.0), 0.06)
		return
	destruido = true; vulnerable = false; remove_from_group("enemigos"); collision_layer = 1
	if haz: haz.visible = false
	if modelo: modelo.visible = false
	if luz: luz.light_energy = 0.0
	ParticulasImpacto.estallar(self, Color(0.22, 1.0, 0.35, 1.0), 2.4)
	reactor_destruido.emit(indice)
