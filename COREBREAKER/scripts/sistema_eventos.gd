## sistema_eventos.gd
## ============================================================
## Propósito: Escuchar eventos del juego y reaccionar con efectos.
##
## Conceptos que cubre este script:
##   ✅ Señal   → escucha 'cambio_noche' de SistemaSol
##   ✅ Grupo   → itera los nodos del grupo "disparadores" para notificarlos
##   ✅ Estado con delta → _energia_destello decae cada frame con delta
##   ✅ Función pura → decaer(energia, tasa, dt) solo recibe y devuelve floats
##
## Proyecto : COREBREAKER – Arena 1 (Tarea A)
## Godot    : 4.3+
## ============================================================

class_name SistemaEventos
extends Node


# ──────────────────────────────────────────────
# VARIABLES @export
# ──────────────────────────────────────────────

## Qué tan rápido se apaga el destello (unidades de energía por segundo).
## 2.0 = tarda ~1.5 s en apagarse desde energía 3.
@export var tasa_decaimiento: float  = 2.0

## Energía inicial del destello cuando ocurre el cambio de día/noche.
@export var energia_inicial: float = 3.0


# ──────────────────────────────────────────────
# ESTADO INTERNO (cambia con el tiempo → con delta)
# ──────────────────────────────────────────────

## Energía actual del destello.
## Empieza en 0 (luz apagada) y sube a 'energia_inicial' al detectar un evento.
## Luego decae cada frame en _process usando decaer().
var _energia_destello: float = 0.0

## Referencia a la OmniLight3D que hace el efecto visual.
## Se busca automáticamente en _ready().
var _luz_destello: OmniLight3D


# ──────────────────────────────────────────────
# _ready()
# ──────────────────────────────────────────────
func _ready() -> void:
	# Buscar la luz de destello en la escena.
	# get_node_or_null() devuelve null si no existe (no lanza error).
	_luz_destello = get_node_or_null("../LuzDestello") as OmniLight3D
	if _luz_destello:
		_luz_destello.light_energy = 0.0  # Aseguramos que empieza apagada.

	# ── CONEXIÓN DE SEÑAL ────────────────────────────────────────
	# Aquí conectamos la señal 'cambio_noche' del nodo SistemaSol
	# a nuestra función _on_cambio_noche().
	#
	# ¿Por qué así y no en la escena?
	#   En Godot puedes conectar señales desde el editor O desde código.
	#   Hacerlo en código lo hace explícito y fácil de leer.
	#
	# get_node("../SistemaSol") sube un nivel (..) y busca el hermano SistemaSol.
	var sistema_sol := get_node("../SistemaSol") as SistemaSol
	# .connect(función_que_escucha) → cada vez que SistemaSol emita la señal,
	# Godot llamará automáticamente a _on_cambio_noche().
	sistema_sol.cambio_noche.connect(_on_cambio_noche)
	print("[SistemaEventos] Conectado a SistemaSol.cambio_noche ✓")


# ──────────────────────────────────────────────
# _process(delta) – Estado que cambia con el tiempo
# ──────────────────────────────────────────────
func _process(delta: float) -> void:
	# Solo procesamos si el destello tiene energía positiva.
	if _energia_destello <= 0.0:
		return

	# Llamamos a la función pura decaer() para reducir la energía.
	# Pasamos el delta del frame para que sea independiente de los FPS.
	#   A 30 FPS: delta ≈ 0.033 → decaimiento proporcional
	#   A 60 FPS: delta ≈ 0.016 → mismo decaimiento total por segundo
	_energia_destello = SistemaEventos.decaer(_energia_destello, tasa_decaimiento, delta)

	# Aplicamos la energía calculada a la luz visual.
	if _luz_destello:
		_luz_destello.light_energy = _energia_destello


# ──────────────────────────────────────────────
# RECEPTOR DE SEÑAL
# Godot llama a esta función automáticamente cuando
# SistemaSol emite la señal 'cambio_noche'.
# ──────────────────────────────────────────────

## Reacciona al cambio de día ↔ noche.
## Parámetro:
##   es_noche → true si acaba de empezar la noche; false si es de día.
func _on_cambio_noche(es_noche: bool) -> void:
	# 1. Disparamos el destello: ponemos la energía al máximo.
	_energia_destello = energia_inicial
	print("[SistemaEventos] ¡Destello! Cambio detectado → es_noche=", es_noche)

	# 2. Notificamos a TODOS los nodos del grupo "disparadores".
	#
	# get_tree().get_nodes_in_group("disparadores") devuelve un Array con
	# todos los nodos de la escena que tengan la etiqueta "disparadores".
	# No importa qué clase sean, solo necesitan estar en el grupo.
	#
	# Esto es el patrón GRUPO: SistemaEventos no sabe qué nodos son,
	# solo les dice "activar()" si tienen ese método.
	for disparador in get_tree().get_nodes_in_group("disparadores"):
		if disparador.has_method("activar"):
			# Llamamos activar() en cada nodo del grupo.
			disparador.activar(es_noche)


# ──────────────────────────────────────────────
# FUNCIÓN PURA
# 'static func' → no toca la escena ni variables de instancia.
# Solo recibe números y devuelve un número. Testeable con print().
#
# Prueba en cualquier script:
#   print(SistemaEventos.decaer(3.0, 2.0, 0.5))  # → 2.0
#   print(SistemaEventos.decaer(1.0, 2.0, 1.0))  # → 0.0 (no negativo)
# ──────────────────────────────────────────────

## Decaimiento lineal de energía, independiente de los FPS.
##
## Fórmula: energia - tasa * dt
##   maxf(0.0, ...) garantiza que nunca baje de cero.
##
## Parámetros:
##   energia → valor actual a reducir
##   tasa    → cuánto baja por segundo
##   dt      → tiempo del frame (delta)
## Retorna:
##   nueva energía después del decaimiento
static func decaer(energia: float, tasa: float, dt: float) -> float:
	return maxf(0.0, energia - tasa * dt)
