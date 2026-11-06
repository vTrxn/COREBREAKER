## ciclo_dia.gd
## ============================================================
## Propósito: Gestionar el tiempo del día en el mundo del juego.
## Este script es "puro": sólo hace cálculos matemáticos sobre
## la hora, sin tocar nodos ni la escena directamente.
##
## Proyecto : COREBREAKER – Arena 1 (Tarea A)
## Godot    : 4.3+
## ============================================================

class_name CicloDia  # Registra esta clase con el nombre "CicloDia"
extends Node         # Hereda de Node para poder usarlo en la escena


# ──────────────────────────────────────────────
# CONSTANTES
# ──────────────────────────────────────────────

## Color naranja/ámbar que tiene el sol cuando está bajo en el horizonte
## (amanecer / atardecer). Se define como constante porque nunca cambia.
## Color(R, G, B) → R=1.0 (rojo total), G=0.71 (naranja), B=0.0 (sin azul).
const NARANJA: Color = Color(1.0, 0.71, 0.0)


# ──────────────────────────────────────────────
# VARIABLES EXPORTADAS
# Las variables @export aparecen en el Inspector de Godot,
# lo que nos permite editarlas sin tocar el código.
# ──────────────────────────────────────────────

## Hora actual del día, expresada en un rango de 0.0 a 24.0.
## 0.0 = medianoche, 6.0 = amanecer, 10.0 = mañana, 18.0 = puesta de sol, etc.
## La fijamos en 10.0 (mañana) para la Arena 1.
@export var hora: float = 10.0

## Duración de un día completo expresado en SEGUNDOS de tiempo real.
## 48.0 s → un ciclo completo de 24 horas de juego dura 48 segundos reales.
@export var duracion_dia: float = 48.0

## Cuando es 'true' el tiempo queda congelado.
## En la Arena 1 la luz es fija, así que arrancamos pausados.
@export var pausado: bool = false   # ← false = ciclo activo; ponlo 'true' en el Inspector para congelarlo


# ──────────────────────────────────────────────
# MÉTODOS DE INSTANCIA
# ──────────────────────────────────────────────

## Avanza el reloj interno del juego.
## Llama a esta función cada frame desde SistemaSol (o desde _process).
##
## Parámetro:
##   dt  → delta time: tiempo real en segundos transcurrido desde el último frame.
##         Godot lo entrega automáticamente en _process(delta).
func avanzar(dt: float) -> void:
	# Si el ciclo está pausado, no hacemos nada y salimos de la función.
	if pausado:
		return

	# ¿Cómo funciona la fórmula?
	#
	#   24.0 * dt / duracion_dia
	#   └───────────────────────┘
	#       Convierte tiempo real (segundos) → horas de juego.
	#       Ejemplo: dt=0.016 s, duracion_dia=48 s
	#       → 24.0 * 0.016 / 48.0 = 0.008 horas de juego por frame.
	#
	#   hora + (horas_de_juego_por_frame)
	#       Suma el incremento a la hora actual.
	#
	#   fposmod(..., 24.0)
	#       Garantiza que la hora siempre esté en [0.0, 24.0).
	#       Cuando llega a 24 vuelve a 0 (como un reloj).
	#       fposmod es la versión para floats del operador módulo (%).
	hora = fposmod(hora + (24.0 * dt / duracion_dia), 24.0)


# ──────────────────────────────────────────────
# FUNCIONES ESTÁTICAS (PURAS)
# 'static func' significa que NO necesitas una instancia del nodo
# para llamarlas. Se usan como: CicloDia.elevacion(10.0)
# Son "puras" porque solo reciben un número y devuelven un número,
# sin efectos secundarios ni acceso a variables de instancia.
# ──────────────────────────────────────────────

## Calcula el ángulo de elevación del sol sobre el horizonte.
##
## Modelo simple: tratamos el día de 24 horas como una rueda de 360°.
##   - A las  6:00 → elevación =   0° (horizonte, amanecer)
##   - A las 12:00 → elevación =  90° (cénit, mediodía)
##   - A las 18:00 → elevación = 180° (horizonte, puesta de sol)
##
## Fórmula: (h - 6.0) * 15.0
##   Restamos 6 para que el "cero" sea el amanecer.
##   Multiplicamos por 15 porque 360° / 24 horas = 15 grados/hora.
##
## Parámetro:
##   h → hora del día [0.0, 24.0)
## Retorna:
##   ángulo en grados (puede ser negativo de noche)
static func elevacion(h: float) -> float:
	return (h - 6.0) * 15.0


## Calcula cuánta luz recibe una superficie horizontal (el suelo).
## Resultado entre 0.0 (noche, sin luz) y 1.0 (luz máxima al mediodía).
##
## Usamos sin() porque la trayectoria del sol es una curva sinusoidal:
##   - sin(0°)  = 0.0 → amanecer / anochecer (luz rasante)
##   - sin(90°) = 1.0 → mediodía (luz perpendicular, máxima intensidad)
##   - sin(<0°) = negativo → el sol está bajo el horizonte (noche)
##
## maxf(0.0, ...) descarta los valores negativos de la noche.
##
## Parámetro:
##   h → hora del día [0.0, 24.0)
## Retorna:
##   factor entre 0.0 y 1.0
static func factor_sol(h: float) -> float:
	return maxf(0.0, sin(deg_to_rad(elevacion(h))))
	# deg_to_rad() convierte grados → radianes, que es lo que espera sin().


## Calcula el color de la luz solar según la hora del día.
## Mezcla suavemente entre NARANJA (horizonte) y BLANCO (cénit).
##
## lerp = "Linear Interpolation" (interpolación lineal).
## NARANJA.lerp(Color.WHITE, t):
##   t = 0.0 → devuelve NARANJA puro  (amanecer / atardecer)
##   t = 0.5 → mezcla 50/50
##   t = 1.0 → devuelve WHITE puro    (mediodía)
##
## Usamos factor_sol(h) como t, así el color cambia junto con la altura del sol.
##
## Parámetro:
##   h → hora del día [0.0, 24.0)
## Retorna:
##   Color interpolado entre naranja y blanco
static func color_sol(h: float) -> Color:
	return NARANJA.lerp(Color.WHITE, factor_sol(h))
