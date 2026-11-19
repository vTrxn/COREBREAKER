extends CanvasLayer
var _ocupado: bool = false
var _top: ColorRect; var _bot: ColorRect; var _flash: ColorRect
var _linea_top: ColorRect; var _linea_bot: ColorRect
var _box: VBoxContainer; var _lbl_tag: Label; var _lbl_tit: Label; var _lbl_sub: Label
var _barra_bg: ColorRect; var _barra_fg: ColorRect
var _sfx: AudioStreamPlayer
func _ready() -> void:
	layer = 128; process_mode = Node.PROCESS_MODE_ALWAYS
	_flash = _rect(Color(0.15, 0.92, 1.0, 0.0), Vector2.ZERO, Vector2.ONE)
	_top = _rect(Color(0.03, 0.05, 0.08, 1.0), Vector2(0, -0.55), Vector2(1, 0))
	_bot = _rect(Color(0.03, 0.05, 0.08, 1.0), Vector2(0, 1.0), Vector2(1, 1.55))
	_linea_top = _rect(Color(0.1, 0.9, 1.0, 1.0), Vector2(0, 0.985), Vector2(1, 1.0), _top)
	_linea_bot = _rect(Color(0.1, 0.9, 1.0, 1.0), Vector2(0, 0.0), Vector2(1, 0.015), _bot)
	_box = VBoxContainer.new(); _box.set_anchors_preset(Control.PRESET_CENTER)
	_box.offset_left = -360; _box.offset_right = 360; _box.offset_top = -78; _box.offset_bottom = 78
	_box.alignment = BoxContainer.ALIGNMENT_CENTER; _box.add_theme_constant_override("separation", 10)
	_box.modulate.a = 0.0; add_child(_box)
	_lbl_tag = _label("WARP TELEPORT // COREBREAKER", 14, Color(0.15, 0.88, 1.0))
	_lbl_tit = _label("SECTOR 02", 34, Color(0.95, 0.98, 1.0))
	_lbl_sub = _label("SINCRONIZANDO SISTEMAS...", 16, Color(0.65, 0.78, 0.88))
	_barra_bg = ColorRect.new(); _barra_bg.color = Color(0.1, 0.16, 0.22, 1.0)
	_barra_bg.custom_minimum_size = Vector2(460, 6); _barra_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(_barra_bg)
	_barra_fg = ColorRect.new(); _barra_fg.color = Color(0.1, 0.92, 1.0, 1.0)
	_barra_fg.set_anchors_preset(Control.PRESET_LEFT_WIDE); _barra_fg.anchor_right = 0.0
	_barra_bg.add_child(_barra_fg)
	_sfx = AudioStreamPlayer.new(); _sfx.stream = load("res://audio/dash.mp3")
	_sfx.volume_db = -2.0; add_child(_sfx)
	visible = false
func _rect(col: Color, a_min: Vector2, a_max: Vector2, parent: Node = self) -> ColorRect:
	var r := ColorRect.new(); r.color = col; r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_left = a_min.x; r.anchor_top = a_min.y; r.anchor_right = a_max.x; r.anchor_bottom = a_max.y
	parent.add_child(r); return r
func _label(txt: String, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text = txt; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", sz); l.add_theme_color_override("font_color", col)
	_box.add_child(l); return l
func viajar_a(ruta: String, titulo: String, subtitulo: String = "TRANSFIRIENDO UNIDAD...") -> void:
	if _ocupado or ruta.is_empty(): return
	_ocupado = true; visible = true; get_tree().paused = true; Engine.time_scale = 1.0
	_lbl_tit.text = titulo; _lbl_sub.text = subtitulo; _barra_fg.anchor_right = 0.0
	_linea_top.modulate.a = 1.0; _linea_bot.modulate.a = 1.0
	var cam := get_viewport().get_camera_3d(); var fov_orig := cam.fov if cam else 75.0
	if _sfx: _sfx.pitch_scale = 1.35; _sfx.play()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
	if cam: tw.tween_property(cam, "fov", 118.0, 0.36)
	tw.tween_property(_flash, "color:a", 0.72, 0.14); tw.tween_property(_flash, "color:a", 0.0, 0.24).set_delay(0.14)
	tw.tween_property(_top, "anchor_top", 0.0, 0.38); tw.tween_property(_top, "anchor_bottom", 0.502, 0.38)
	tw.tween_property(_bot, "anchor_top", 0.498, 0.38); tw.tween_property(_bot, "anchor_bottom", 1.0, 0.38)
	await tw.finished
	var tw_ui := create_tween().set_parallel(true)
	tw_ui.tween_property(_linea_top, "modulate:a", 0.0, 0.14); tw_ui.tween_property(_linea_bot, "modulate:a", 0.0, 0.14)
	tw_ui.tween_property(_box, "modulate:a", 1.0, 0.18)
	tw_ui.tween_property(_barra_fg, "anchor_right", 1.0, 0.58).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw_ui.finished
	var err := get_tree().change_scene_to_file(ruta)
	if err != OK:
		if is_instance_valid(cam): cam.fov = fov_orig
		_restaurar(true); return
	get_tree().paused = false
	await get_tree().process_frame; await get_tree().process_frame
	if not get_tree().paused: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _sfx: _sfx.pitch_scale = 0.82; _sfx.play()
	await _restaurar(false)
func _restaurar(despausar: bool) -> void:
	var tw_out := create_tween().set_parallel(true).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw_out.tween_property(_box, "modulate:a", 0.0, 0.15)
	tw_out.tween_property(_linea_top, "modulate:a", 1.0, 0.08); tw_out.tween_property(_linea_bot, "modulate:a", 1.0, 0.08)
	tw_out.tween_property(_top, "anchor_top", -0.55, 0.48).set_delay(0.1)
	tw_out.tween_property(_top, "anchor_bottom", 0.0, 0.48).set_delay(0.1)
	tw_out.tween_property(_bot, "anchor_top", 1.0, 0.48).set_delay(0.1)
	tw_out.tween_property(_bot, "anchor_bottom", 1.55, 0.48).set_delay(0.1)
	await tw_out.finished
	if despausar: get_tree().paused = false
	visible = false; _ocupado = false
