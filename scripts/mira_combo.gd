class_name MiraCombo
extends Control
const COLORES: Array[Color] = [Color(0.18, 0.9, 0.42, 1.0), Color(1.0, 0.83, 0.15, 1.0), Color(1.0, 0.48, 0.09, 1.0), Color(1.0, 0.16, 0.16, 1.0)]
const BARRA_W := 5.0
const BARRA_H := 42.0
const CAP_NIVEL := 100.0
var combo: float = 0.0
var pausa_decaer: float = 0.0
var hit_pop: float = 0.0
var parry_pulso: float = 0.0
var parry_flash: float = 0.0
var parry_ref: BrazoParry = null
func _ready() -> void:
	var jug := get_tree().get_first_node_in_group("jugador") as Jugador
	if jug:
		jug.dano_infligido.connect(registrar_dano)
		parry_ref = jug.parry_b
		if parry_ref:
			parry_ref.parry_activado.connect(func(): parry_pulso = 1.0; queue_redraw())
			parry_ref.parry_conectado.connect(func(fuerte: bool): parry_flash = 1.0 if fuerte else 0.7; hit_pop = 1.0; queue_redraw())
func registrar_dano(cantidad: float) -> void:
	combo = minf(CAP_NIVEL * COLORES.size(), combo + maxf(0.0, cantidad) * 1.15)
	pausa_decaer = 0.65
	hit_pop = 1.0
	queue_redraw()
func _process(delta: float) -> void:
	var cambio := parry_ref != null and not parry_ref.can_parry
	if hit_pop > 0.0:
		hit_pop = maxf(0.0, hit_pop - delta * 6.5)
		cambio = true
	if parry_pulso > 0.0:
		parry_pulso = maxf(0.0, parry_pulso - delta * 4.5)
		cambio = true
	if parry_flash > 0.0:
		parry_flash = maxf(0.0, parry_flash - delta * 4.0)
		cambio = true
	if pausa_decaer > 0.0:
		pausa_decaer -= delta
	elif combo > 0.0:
		var nivel := mini(COLORES.size() - 1, int(combo / CAP_NIVEL))
		combo = maxf(0.0, combo - (20.0 + nivel * 6.0) * delta)
		cambio = true
	if cambio:
		queue_redraw()
func _draw() -> void:
	var c := size * 0.5
	var gap := 5.0 + hit_pop * 4.5 + parry_pulso * 3.0
	var largo := 7.0
	var col_mira := Color(1.0, 0.72, 0.02, 1.0).lerp(Color(0.2, 0.95, 1.0, 1.0), maxf(parry_pulso, parry_flash)).lerp(Color.WHITE, hit_pop * 0.6)
	var col_borde := Color(0.05, 0.06, 0.08, 0.85)
	for d: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var p0: Vector2 = c + d * gap
		var p1: Vector2 = c + d * (gap + largo)
		draw_line(p0, p1, col_borde, 3.5)
		draw_line(p0, p1, col_mira, 1.8)
	draw_circle(c, 2.5, col_borde)
	draw_circle(c, 1.5, col_mira)
	if parry_flash > 0.05:
		draw_arc(c, 10.0 + (1.0 - parry_flash) * 14.0, 0.0, TAU, 24, Color(0.25, 0.95, 1.0, parry_flash * 0.95), 2.2)
	if parry_ref and not parry_ref.can_parry and not parry_ref.is_parrying:
		var prog := clampf(1.0 - parry_ref.t_cooldown / maxf(parry_ref.cd_max, 0.01), 0.0, 1.0)
		var col_cd := Color(0.2, 0.85, 1.0, 0.9) if parry_ref.cd_max < 1.0 else Color(1.0, 0.45, 0.15, 0.9)
		draw_rect(Rect2(c.x - 11.0, c.y + 18.0, 22.0, 3.0), Color(0.08, 0.1, 0.14, 0.8))
		draw_rect(Rect2(c.x - 10.0, c.y + 18.5, 20.0 * prog, 2.0), col_cd)
	if hit_pop > 0.05:
		var hc := Color(1.0, 1.0, 1.0, hit_pop * 0.9)
		for diag: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var n: Vector2 = diag.normalized()
			draw_line(c + n * 4.5, c + n * 9.5, hc, 1.6)
	var bx := c.x + 22.0
	var by := c.y - BARRA_H * 0.5
	draw_rect(Rect2(bx - 1.0, by - 1.0, BARRA_W + 2.0, BARRA_H + 2.0), col_borde)
	var max_combo := CAP_NIVEL * COLORES.size()
	if combo <= 0.0:
		draw_rect(Rect2(bx, by, BARRA_W, BARRA_H), Color(0.12, 0.14, 0.18, 0.65))
		return
	var tier := mini(COLORES.size() - 1, int(floorf((combo - 0.001) / CAP_NIVEL)))
	var fondo: Color = Color(0.12, 0.14, 0.18, 0.85) if tier == 0 else COLORES[tier - 1]
	var frente: Color = COLORES[tier]
	var frac := 1.0 if combo >= max_combo else fmod(combo, CAP_NIVEL) / CAP_NIVEL
	if frac == 0.0 and combo > 0.0:
		frac = 1.0
	var fill_h := BARRA_H * clampf(frac, 0.0, 1.0)
	draw_rect(Rect2(bx, by, BARRA_W, BARRA_H), fondo)
	draw_rect(Rect2(bx, by + BARRA_H - fill_h, BARRA_W, fill_h), frente)