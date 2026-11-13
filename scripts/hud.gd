class_name HUD
extends CanvasLayer
@onready var sangrado_aviso: Label = $MarginContainer/VBoxContainer/LabelSangrado
@onready var label_nivel: Label = $MarginContainer/VBoxContainer/LabelNivel
@onready var barra_xp: ProgressBar = $MarginContainer/VBoxContainer/BarraXP
@onready var label_horda: Label = find_child("LabelHorda") as Label
@onready var label_restantes: Label = find_child("LabelRestantes") as Label
@onready var label_municion: Label = find_child("LabelMunicion") as Label
@onready var flash_dano: ColorRect = $FlashDano
@onready var filtro_vida: ColorRect = $FiltroVida
@onready var muerte_box: VBoxContainer = $MuerteBox
@onready var btn_reiniciar: Button = $MuerteBox/BtnReiniciar
var hp_ant: float = -1.0
var tw_dano: Tween = null
var muerto: bool = false
func _ready() -> void:
	var p := get_tree().get_first_node_in_group("jugador") as Jugador
	if p:
		p.cambio_salud.connect(_on_salud)
		p.alerta_sangrado.connect(_on_sangrado)
		p.cambio_xp.connect(_on_xp)
		if p.arma:
			p.arma.cambio_municion.connect(_on_municion)
			_on_municion(p.arma.balas, p.arma.balas_max, p.arma.recargando)
	if sangrado_aviso:
		sangrado_aviso.visible = false
	if btn_reiniciar:
		btn_reiniciar.pressed.connect(func(): get_tree().reload_current_scene())
func _on_salud(act: float, max_v: float) -> void:
	var ratio := clampf(act / maxf(max_v, 1.0), 0.0, 1.0)
	if filtro_vida:
		filtro_vida.visible = ratio < 0.999
		var mat := filtro_vida.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("ratio", ratio)
	if hp_ant >= 0.0 and act < hp_ant - 1.0:
		_mostrar_flash()
	hp_ant = act
	if act <= 0.0 and not muerto:
		_mostrar_game_over()
func _mostrar_game_over() -> void:
	muerto = true
	$CenterContainer.visible = false
	if muerte_box:
		muerte_box.visible = true
	if btn_reiniciar:
		btn_reiniciar.visible = false
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(btn_reiniciar):
			btn_reiniciar.visible = true
	)
func _mostrar_flash() -> void:
	if not flash_dano:
		return
	if tw_dano and tw_dano.is_valid():
		tw_dano.kill()
	var a_act := flash_dano.color.a
	var a_nuevo := clampf(maxf(a_act + 0.15, 0.32), 0.32, 0.55)
	flash_dano.color = Color(0.85, 0.05, 0.05, a_nuevo)
	tw_dano = create_tween()
	tw_dano.tween_interval(0.12)
	tw_dano.tween_property(flash_dano, "color:a", 0.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
func _on_sangrado(on: bool) -> void:
	if sangrado_aviso:
		sangrado_aviso.visible = on
func _on_xp(act: float, max_v: float, lvl: int) -> void:
	if label_nivel:
		label_nivel.text = "NIVEL %d" % lvl
	if barra_xp:
		barra_xp.max_value = max_v
		barra_xp.value = act
func actualizar_horda(num: int, restantes: int) -> void:
	if label_horda:
		label_horda.text = "HORDA %d" % num
	if label_restantes:
		label_restantes.text = "ENEMIGOS: %d" % restantes
func _on_municion(act: int, max_v: int, rec: bool) -> void:
	if label_municion:
		label_municion.text = "RECARGANDO..." if rec else ("%d / %d" % [act, max_v])
