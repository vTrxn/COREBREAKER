class_name LuzParpadeante
extends OmniLight3D
@export var energia_base: float = 3.0
@export var amplitud: float = 0.5
@export var velocidad: float = 3.5
@export var semilla: int = 7
var ruido: FastNoiseLite = FastNoiseLite.new()
var t: float = 0.0
func _ready() -> void:
	ruido.seed = semilla
	ruido.frequency = 1.0
func _process(delta: float) -> void:
	t += delta
	var val := ruido.get_noise_1d(t * velocidad)
	light_energy = energia(energia_base, amplitud, val)
static func energia(base: float, amp: float, valor_ruido: float) -> float:
	return maxf(0.0, base * (1.0 + amp * valor_ruido))