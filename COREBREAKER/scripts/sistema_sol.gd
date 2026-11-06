## sistema_sol.gd
## ============================================================
## Propósito: Conectar el reloj (CicloDia) con los nodos 3D de la escena.
## Este script toma los valores matemáticos calculados en CicloDia
## y los aplica visualmente: rota el sol, cambia su color y energía,
## y ajusta la luz ambiental del entorno.
##
## Proyecto : COREBREAKER – Arena 1 (Tarea A)
## Godot    : 4.3+
##
## Dependencias:
##   - Nodo hijo de tipo CicloDia en la escena.
##   - Un nodo DirectionalLight3D asignado en el Inspector.
##   - Un nodo WorldEnvironment asignado en el Inspector.
## ============================================================

class_name SistemaSol  # Registra el nombre global de esta clase
extends Node           # Hereda de Node


# ──────────────────────────────────────────────
# SEÑALES
# Una señal es un "evento" que este nodo puede emitir.
# Otros nodos se "conectan" a ella para reaccionar.
# ──────────────────────────────────────────────

## Se emite UNA SOLA VEZ cuando cambia el estado día ↔ noche.
## Parámetro:
##   es_noche → true si acaba de empezar la noche, false si es de día.
signal cambio_noche(es_noche: bool)


# ──────────────────────────────────────────────
# VARIABLES EXPORTADAS
# Aparecen en el Inspector para asignarlas arrastrando nodos.
# ──────────────────────────────────────────────

## Referencia al nodo DirectionalLight3D de la escena (el sol).
## Debes arrastrarlo desde el árbol de la escena al Inspector.
@export var sol: DirectionalLight3D

## Referencia al nodo WorldEnvironment de la escena (cielo y ambiente).
@export var entorno: WorldEnvironment

## Multiplicador de energía máxima del sol al mediodía.
## 1.0 = energía estándar, puedes subir a 2.0 para un efecto más dramático.
@export var energia_sol: float = 1.0

## Ángulo horizontal del sol (giro izquierda/derecha en Y).
## -30° da una dirección lateral para sombras más interesantes.
@export var azimut: float = -30.0

## Energía de la luz ambiental durante el día (valor alto → escena bien iluminada).
@export var ambiente_dia: float = 1.0

## Energía de la luz ambiental durante la noche (valor bajo → escena oscura).
@export var ambiente_noche: float = 0.2


# ──────────────────────────────────────────────
# VARIABLES PRIVADAS (sin @export → no aparecen en el Inspector)
# ──────────────────────────────────────────────

## Referencia al nodo CicloDia hermano/hijo.
## Lo buscamos en _ready() en lugar de exportarlo, por comodidad.
var _ciclo: CicloDia

## Recuerda si la última vez era de noche, para detectar el cambio.
## Se inicializa en _ready() con el estado real de la hora inicial.
var era_noche: bool = false


# ──────────────────────────────────────────────
# _ready()
# Godot llama a esta función UNA sola vez, cuando el nodo
# entra en la escena por primera vez. Úsala para inicializar.
# ──────────────────────────────────────────────
# Acumulador para el print de debug (imprime la hora cada 2 s reales)
var _t_debug: float = 0.0

func _ready() -> void:
	# 1. Obtenemos el CicloDia hijo.
	_ciclo = get_node("CicloDia") as CicloDia

	# 2. ── AUTO-RESOLUCIÓN DE REFERENCIAS ────────────────────────
	#    sol y entorno son @export: si el usuario los arrastró en el
	#    Inspector ya están asignados. Si NO lo hizo, los buscamos
	#    automáticamente por ruta en la escena.
	#    Así el ciclo funciona sin tocar el Inspector.
	if not sol:
		sol = get_node_or_null("../SunLight") as DirectionalLight3D
		if sol:
			print("[SistemaSol] SunLight encontrado automáticamente ✓")
		else:
			push_error("[SistemaSol] ¡No se encontró SunLight! Asígnalo en el Inspector o nómbralo 'SunLight'.")

	if not entorno:
		entorno = get_node_or_null("../WorldEnvironment") as WorldEnvironment
		if entorno:
			print("[SistemaSol] WorldEnvironment encontrado automáticamente ✓")
		else:
			push_warning("[SistemaSol] WorldEnvironment no encontrado; la luz ambiental no cambiará.")

	# 3. Aplicamos la hora inicial.
	aplicar_hora()

	# 4. Estado inicial de día/noche.
	era_noche = CicloDia.factor_sol(_ciclo.hora) <= 0.0
	print("[SistemaSol] Listo. hora=", _ciclo.hora, " | pausado=", _ciclo.pausado)


# ──────────────────────────────────────────────
# _process(delta)
# Godot llama a esta función CADA FRAME mientras el nodo esté activo.
# 'delta' es el tiempo real en segundos desde el frame anterior.
# ──────────────────────────────────────────────
func _process(delta: float) -> void:
	# 1. Avanzamos el reloj interno del ciclo.
	_ciclo.avanzar(delta)

	# 2. Aplicamos la hora a la escena 3D.
	aplicar_hora()

	# 3. Debug: imprimimos la hora cada 2 segundos reales para
	#    confirmar en el Output que el ciclo está corriendo.
	_t_debug += delta
	if _t_debug >= 2.0:
		_t_debug = 0.0
		print("[SistemaSol] hora=", snapped(_ciclo.hora, 0.01),
			  " | factor_sol=", snapped(CicloDia.factor_sol(_ciclo.hora), 0.01),
			  " | es_noche=", era_noche)

	# 4. Detectar cambio de día/noche y emitir señal UNA SOLA VEZ.
	var es_noche_ahora: bool = CicloDia.factor_sol(_ciclo.hora) <= 0.0
	if es_noche_ahora != era_noche:
		era_noche = es_noche_ahora
		cambio_noche.emit(es_noche_ahora)
		print("[SistemaSol] ¡Señal emitida! cambio_noche → es_noche=", es_noche_ahora)


# ──────────────────────────────────────────────
# aplicar_hora()
# Traduce la hora actual del CicloDia a valores visuales
# en los nodos 3D de la escena.
# ──────────────────────────────────────────────
func aplicar_hora() -> void:
	var h: float = _ciclo.hora

	# ── Rotación, energía y color del sol ────────────────────────
	# Guardamos en 'sol' una referencia válida gracias a _ready().
	# Si por alguna razón sigue siendo null, el 'if' lo protege.
	if sol:
		# rotation_degrees controla hacia dónde apunta la luz.
		# X = elevación (negada por cómo Godot orienta el nodo)
		# Y = azimut (ángulo horizontal)
		sol.rotation_degrees = Vector3(
			-CicloDia.elevacion(h),
			azimut,
			0.0
		)
		# Energía: 0 de noche, maxima al mediodía
		sol.light_energy = energia_sol * CicloDia.factor_sol(h)
		# Color: naranja al amanecer/atardecer, blanco al mediodía
		sol.light_color  = CicloDia.color_sol(h)

	# ── Luz ambiental del WorldEnvironment ───────────────────────
	if entorno and entorno.environment:
		entorno.environment.ambient_light_energy = lerpf(
			ambiente_noche,
			ambiente_dia,
			CicloDia.factor_sol(h)
		)


# ──────────────────────────────────────────────
# FUNCIONES ESTÁTICAS
# ──────────────────────────────────────────────

## Calcula la iluminación difusa (modelo de Lambert) sobre una superficie.
##
## El modelo de Lambert dice que la cantidad de luz que recibe una superficie
## depende del ángulo entre el rayo de luz y la normal de la superficie:
##   - Si la luz es perpendicular (ángulo 0°) → dot = 1.0 → luz máxima.
##   - Si la luz es rasante (ángulo 90°) → dot = 0.0 → sin luz.
##   - Si la luz viene de detrás → dot < 0 → no hay luz (usamos maxf).
##
## Parámetros:
##   normal     → vector unitario perpendicular a la superficie (apunta "afuera").
##   hacia_luz  → vector unitario que apunta HACIA la fuente de luz.
## Retorna:
##   factor de iluminación entre 0.0 y 1.0
static func lambert(normal: Vector3, hacia_luz: Vector3) -> float:
	# dot() = producto punto = cos(ángulo entre los dos vectores unitarios).
	# maxf(0.0, ...) elimina valores negativos (luz por detrás de la superficie).
	return maxf(0.0, normal.dot(hacia_luz))


## Estima la energía difusa que recibe el SUELO (superficie horizontal).
## Útil para gameplay: zonas de luz/sombra, efectos visuales en el piso.
##
## Retorna:
##   energía difusa en el suelo [0.0, energia_sol]
func prediccion_piso() -> float:
	# El suelo es horizontal → su normal apunta hacia arriba (eje Y en Godot).
	var normal_suelo: Vector3 = Vector3.UP

	# Calculamos el vector "hacia la luz" a partir de los ángulos del sol.
	var h: float = _ciclo.hora
	var angulo_elevacion_rad: float = deg_to_rad(-CicloDia.elevacion(h))
	var angulo_azimut_rad: float    = deg_to_rad(azimut)

	# Convertimos ángulos esféricos → vector 3D unitario.
	# Fórmula de geometría esférica:
	#   X = cos(pitch) * sin(yaw)
	#   Y = -sin(pitch)   ← invertido para coincidir con la rotación del nodo
	#   Z = cos(pitch) * cos(yaw)
	var hacia_luz: Vector3 = Vector3(
		cos(angulo_elevacion_rad) * sin(angulo_azimut_rad),
		-sin(angulo_elevacion_rad),
		cos(angulo_elevacion_rad) * cos(angulo_azimut_rad)
	).normalized()  # .normalized() garantiza magnitud = 1

	# Energía final = energía del sol * factor Lambert en el suelo.
	return energia_sol * lambert(normal_suelo, hacia_luz)
