## luz_jugador.gd
## ============================================================
## Propósito: Representa la linterna / luz del jugador.
## Se activa de noche y se apaga de día respondiendo a SistemaEventos.
##
## Conceptos que cubre este script:
##   ✅ Grupo          → este nodo está en el grupo "disparadores" (asignado en la escena)
##   ✅ Estado con delta → energia_actual sube/baja cada frame con delta
##   ✅ Función pura    → atenuacion(d) solo recibe y devuelve float
##
## Proyecto : COREBREAKER – Arena 1 (Tarea A)
## Godot    : 4.3+
## ============================================================

class_name LuzJugador
extends Node


# ──────────────────────────────────────────────
# VARIABLES @export
# ──────────────────────────────────────────────

## Energía máxima que alcanza la luz cuando está completamente encendida.
@export var energia_maxima: float = 1.5

## Velocidad de transición en unidades de energía por segundo.
## Con 3.0 tarda ~0.5 s en encenderse o apagarse completamente.
@export var velocidad_transicion: float = 3.0


# ──────────────────────────────────────────────
# ESTADO INTERNO (cambia con delta cada frame)
# ──────────────────────────────────────────────

## Energía actual de la luz del jugador [0.0 … energia_maxima].
## Esta variable CAMBIA CON EL TIEMPO usando delta en _process.
var energia_actual: float = 0.0

## Indica si la luz debe estar encendida (noche) o apagada (día).
var _activa: bool = false

## Referencia a la OmniLight3D hija que da la luz visual.
var _luz: OmniLight3D


# ──────────────────────────────────────────────
# _ready()
# ──────────────────────────────────────────────
func _ready() -> void:
	# Buscamos la luz OmniLight3D que debe ser hija de este nodo en la escena.
	# Si no existe, _luz queda como null y los if de abajo lo protegen.
	_luz = get_node_or_null("OmniLuzJugador") as OmniLight3D
	if _luz:
		_luz.light_energy = 0.0  # Apagada al inicio (es de día, hora=10).

	# Log de depuración: verificamos que el nodo está en el grupo correcto.
	# get_groups() devuelve todos los grupos a los que pertenece este nodo.
	print("[LuzJugador] Grupos: ", get_groups())
	print("[LuzJugador] Prueba atenuacion(0)=", atenuacion(0.0),
		  " | atenuacion(5)=", atenuacion(5.0),
		  " | atenuacion(10)=", atenuacion(10.0))


# ──────────────────────────────────────────────
# _process(delta) – Estado con delta
# ──────────────────────────────────────────────
func _process(delta: float) -> void:
	# Según si está activa o no, la energía sube o baja suavemente.
	# Usamos delta para que la velocidad sea igual a cualquier FPS.
	if _activa:
		# Encendido: energía sube hasta energia_maxima.
		# minf() garantiza que no pase del máximo.
		energia_actual = minf(energia_maxima, energia_actual + velocidad_transicion * delta)
	else:
		# Apagado: energía decae hasta 0.
		# maxf() garantiza que no baje de cero.
		energia_actual = maxf(0.0, energia_actual - velocidad_transicion * delta)

	# Aplicamos la energía calculada a la luz visual.
	if _luz:
		_luz.light_energy = energia_actual


# ──────────────────────────────────────────────
# activar()
# Llamado por SistemaEventos cuando detecta cambio de día/noche.
# Este nodo está en el grupo "disparadores", así que SistemaEventos
# lo encuentra con get_nodes_in_group() y llama a este método.
# ──────────────────────────────────────────────

## Enciende o apaga la luz según el estado del ciclo día/noche.
## Parámetro:
##   es_noche → true = encender; false = apagar
func activar(es_noche: bool) -> void:
	_activa = es_noche
	print("[LuzJugador] activar() → es_noche=", es_noche,
		  " | Luz se irá a: ", energia_maxima if es_noche else 0.0)


# ──────────────────────────────────────────────
# FUNCIÓN PURA
# Calcula cuánto se atenúa la luz con la distancia.
# Modelo: inverso del cuadrado de la distancia (física real simplificada).
#
# Prueba con print:
#   print(LuzJugador.atenuacion(0.0))   # → 1.0  (sin distancia, luz plena)
#   print(LuzJugador.atenuacion(1.0))   # → 0.5  (a 1 unidad)
#   print(LuzJugador.atenuacion(5.0))   # → 0.038 (a 5 unidades, muy tenue)
#   print(LuzJugador.atenuacion(10.0))  # → 0.0099 (a 10 unidades, casi nada)
# ──────────────────────────────────────────────

## Calcula la atenuación de luz por distancia usando el modelo de inverso cuadrado.
##
## Fórmula: 1 / (1 + d²)
##   d = 0  → 1.0  (luz completa junto a la fuente)
##   d → ∞  → 0.0  (nada de luz a distancia infinita)
##
## Parámetro:
##   d → distancia a la fuente de luz (en unidades de Godot)
## Retorna:
##   factor de atenuación entre 0.0 y 1.0
static func atenuacion(d: float) -> float:
	# Protección: si la distancia es negativa o cero, retornamos 1.0 (luz plena).
	if d <= 0.0:
		return 1.0
	# 1 + d*d evita la singularidad de dividir entre 0 cuando d=0.
	return 1.0 / (1.0 + d * d)
