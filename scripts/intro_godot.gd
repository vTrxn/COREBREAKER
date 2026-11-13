class_name IntroGodot
extends CanvasLayer
static var ya_mostrada: bool = false
const LOGO_TEX := preload("res://texturas/logo_vertical_monochrome_dark.png")
func _ready() -> void:
	if ya_mostrada:
		queue_free()
		return
	ya_mostrada = true
	layer = 100
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.0, 0.0, 0.0, 1.0)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var npi := Label.new()
	npi.text = "N.P.I."
	npi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npi.add_theme_font_size_override("font_size", 68)
	npi.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
	npi.modulate.a = 0.0
	centro.add_child(npi)
	var logo := TextureRect.new()
	logo.texture = LOGO_TEX
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(280, 280)
	logo.modulate.a = 0.0
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(logo)
	var tw := create_tween()
	tw.tween_interval(0.2)
	tw.tween_property(npi, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.8)
	tw.tween_property(npi, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.15)
	tw.tween_property(logo, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.8)
	tw.tween_property(fondo, "color:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.4)
	tw.tween_property(logo, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(queue_free)
