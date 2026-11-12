extends SceneTree

var step := 0
var mundo: Node3D
var cam: Camera3D
var jugador: CharacterBody3D
var sistema_eventos: Node
var luz_techo: OmniLight3D
var luz_evento: OmniLight3D
var luz_variable: OmniLight3D
var luz_telegrafiado: SpotLight3D

func _init() -> void:
	print("--- INICIANDO GENERADOR DE CAPTURAS COREBREAKER ---")
	var mundo_res = load("res://Mundo.tscn")
	mundo = mundo_res.instantiate()
	root.add_child(mundo)

	var dir = DirAccess.open("res://")
	if not dir.dir_exists("capturas_taller"):
		dir.make_dir("capturas_taller")

	jugador = mundo.get_node_or_null("Jugador") as CharacterBody3D
	if jugador:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	luz_techo = mundo.get_node_or_null("LuzTecho") as OmniLight3D
	luz_evento = mundo.get_node_or_null("LuzEvento") as OmniLight3D
	sistema_eventos = mundo.get_node_or_null("SistemaEventos")

	luz_variable = OmniLight3D.new()
	luz_variable.name = "LuzVariableEstilo"
	luz_variable.position = Vector3(0, 4.0, 0)
	luz_variable.omni_range = 18.0
	luz_variable.omni_attenuation = 1.0
	mundo.add_child(luz_variable)

	if sistema_eventos:
		sistema_eventos.set("luz_variable", luz_variable)

	luz_telegrafiado = SpotLight3D.new()
	luz_telegrafiado.name = "LuzTelegrafiadoJefe"
	luz_telegrafiado.position = Vector3(0, 6.5, -4.0)
	luz_telegrafiado.rotation_degrees = Vector3(-90, 0, 0)
	luz_telegrafiado.spot_angle = 24.0
	luz_telegrafiado.spot_range = 10.0
	luz_telegrafiado.light_color = Color(0.615, 0.306, 0.867)
	luz_telegrafiado.light_energy = 0.0
	mundo.add_child(luz_telegrafiado)

	cam = Camera3D.new()
	cam.name = "CamaraTaller"
	mundo.add_child(cam)
	_ejecutar_capturas()

func _ejecutar_capturas() -> void:
	# Esperar compilación inicial de shaders
	for i in range(10):
		await process_frame

	# Vista aérea general
	cam.current = true
	cam.position = Vector3(0, 16.0, 19.0)
	cam.look_at(Vector3(0, 1.0, -1.0), Vector3.UP)
	if luz_techo:
		luz_techo.light_energy = 3.0
	await _esperar_frames(3)
	_guardar("01_arena_vista_general.png")

	# Luz parpadeante: pico y valle
	cam.position = Vector3(-8.0, 4.0, 8.0)
	cam.look_at(Vector3(0, 3.5, 0), Vector3.UP)
	if luz_techo:
		luz_techo.light_energy = 4.2
	await _esperar_frames(3)
	_guardar("02_luz_parpadeante_pico.png")

	if luz_techo:
		luz_techo.light_energy = 1.8
	await _esperar_frames(3)
	_guardar("03_luz_parpadeante_valle.png")

	# Primera persona
	if jugador:
		var cam_jug = jugador.get_node_or_null("Camera3D") as Camera3D
		if cam_jug:
			cam_jug.current = true
	if luz_techo:
		luz_techo.light_energy = 2.5
	await _esperar_frames(3)
	_guardar("04_primera_persona_hud_linterna.png")

	# Destello reactivo
	cam.current = true
	cam.position = Vector3(0, 2.8, -2.2)
	cam.look_at(Vector3(0, 1.2, -6.0), Vector3.UP)
	if luz_evento:
		luz_evento.global_position = Vector3(0, 1.6, -6.0)
		luz_evento.light_color = Color(0.224, 1.0, 0.078)
		luz_evento.light_energy = 5.0
	await _esperar_frames(3)
	_guardar("05_destello_reactivo_t0.png")

	if luz_evento:
		luz_evento.light_energy = 1.11
	await _esperar_frames(3)
	_guardar("06_destello_reactivo_t025.png")

	if luz_evento:
		luz_evento.light_energy = 0.25
	await _esperar_frames(3)
	_guardar("07_destello_reactivo_t050.png")

	if luz_evento:
		luz_evento.light_energy = 0.0

	# Luz variable por rango de estilo
	cam.position = Vector3(0, 2.5, 4.5)
	cam.look_at(Vector3(0, 2.5, 0), Vector3.UP)
	if luz_techo:
		luz_techo.light_energy = 1.2

	luz_variable.light_color = Color(0.5, 0.8, 1.0)
	luz_variable.light_energy = 1.0
	await _esperar_frames(3)
	_guardar("08_luz_variable_rango_d.png")

	luz_variable.light_color = Color(0.75, 0.5, 0.6)
	luz_variable.light_energy = 2.5
	await _esperar_frames(3)
	_guardar("09_luz_variable_rango_b.png")

	luz_variable.light_color = Color(1.0, 0.2, 0.2)
	luz_variable.light_energy = 4.0
	await _esperar_frames(3)
	_guardar("10_luz_variable_rango_ultrakill.png")

	luz_variable.light_energy = 0.0

	# Telegrafiado del jefe
	cam.position = Vector3(2.5, 1.8, -0.5)
	cam.look_at(Vector3(0, 0.2, -4.0), Vector3.UP)
	if luz_techo:
		luz_techo.light_energy = 5.5
		luz_techo.light_color = Color(0.615, 0.306, 0.867)
	luz_telegrafiado.light_energy = 6.0
	await _esperar_frames(3)
	_guardar("11_patron_telegrafiado_jefe.png")

	# Área del disparador
	cam.position = Vector3(-3.5, 2.0, -4.0)
	cam.look_at(Vector3(0, 0.5, -6.0), Vector3.UP)
	luz_telegrafiado.light_energy = 0.0
	if luz_techo:
		luz_techo.light_energy = 2.8
	await _esperar_frames(3)
	_guardar("12_area_disparador_taller.png")

	print("--- TODAS LAS CAPTURAS GENERADAS CON ÉXITO ---")
	quit()

func _esperar_frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _guardar(nombre_archivo: String) -> void:
	var img = root.get_texture().get_image()
	if img:
		var ruta = "res://capturas_taller/" + nombre_archivo
		img.save_png(ruta)
		print("Guardada: ", ruta)
	else:
		printerr("No se pudo capturar: ", nombre_archivo)
