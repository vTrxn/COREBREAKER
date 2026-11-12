class_name MenuPausa
extends CanvasLayer
@onready var control_raiz: Control = $ControlRaiz
@onready var slider_vol: HSlider = find_child("SliderVolumen") as HSlider
@onready var label_vol: Label = find_child("LabelVolumen") as Label
@onready var btn_reanudar: Button = find_child("BotonReanudar") as Button
@onready var btn_reiniciar: Button = find_child("BotonReiniciar") as Button
@onready var btn_salir: Button = find_child("BotonSalir") as Button
var bus_idx: int = 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus_idx = AudioServer.get_bus_index("Master")
	if control_raiz:
		control_raiz.visible = false
	if btn_reanudar:
		btn_reanudar.pressed.connect(_on_reanudar)
	if btn_reiniciar:
		btn_reiniciar.pressed.connect(_on_reiniciar)
	if btn_salir:
		btn_salir.pressed.connect(_on_salir)
	if slider_vol:
		slider_vol.value_changed.connect(_on_volumen_cambiado)
		var db_act := AudioServer.get_bus_volume_db(bus_idx)
		var lin_act := db_to_linear(db_act) if not AudioServer.is_bus_mute(bus_idx) else 0.0
		slider_vol.value = lin_act
		_actualizar_texto_volumen(lin_act)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		alternar_pausa()
		get_viewport().set_input_as_handled()
func alternar_pausa() -> void:
	var nueva_pausa := not get_tree().paused
	get_tree().paused = nueva_pausa
	if control_raiz:
		control_raiz.visible = nueva_pausa
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if nueva_pausa else Input.MOUSE_MODE_CAPTURED
	if nueva_pausa and btn_reanudar:
		btn_reanudar.grab_focus()
func _on_reanudar() -> void:
	get_tree().paused = false
	if control_raiz:
		control_raiz.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _on_reiniciar() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()
func _on_salir() -> void:
	get_tree().quit()
func _on_volumen_cambiado(val: float) -> void:
	var silencio := val <= 0.001
	AudioServer.set_bus_mute(bus_idx, silencio)
	if not silencio:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))
	_actualizar_texto_volumen(val)
func _actualizar_texto_volumen(val: float) -> void:
	if label_vol:
		label_vol.text = "VOLUMEN MASTER: %d%%" % int(roundf(val * 100.0))