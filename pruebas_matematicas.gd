extends SceneTree
func _init() -> void:
	var e_test = LuzParpadeante.energia(2.0, 0.3, 1.0)
	print("\n[TEST 1] LuzParpadeante.energia(base=2.0, amp=0.3, ruido=1.0):")
	print("  Resultado calculado: ", e_test)
	print("  Esperado por guía:   2.600000 -> ", "CORRECTO" if is_equal_approx(e_test, 2.6) else "FALLO")
	var ruido = FastNoiseLite.new()
	ruido.seed = 7
	ruido.frequency = 1.0
	var val_ruido = ruido.get_noise_1d(1.0)
	var e_ruido = LuzParpadeante.energia(2.0, 0.3, val_ruido)
	print("\n[TEST 2] FastNoiseLite (semilla=7, t*v=1.0):")
	print("  Valor de ruido 1D:   ", val_ruido)
	print("  Energía calculada:   ", e_ruido)
	var e_inicial = 5.0
	var e_decaida = SistemaEventos.decaer(e_inicial, 0.0, 6.0, 0.5)
	var e_teorica = 5.0 * exp(-6.0 * 0.5)
	print("\n[TEST 3] SistemaEventos.decaer (pico=5.0, base=0.0, k=6.0, dt=0.5):")
	print("  Energía tras 0.5s:   ", e_decaida)
	print("  Fórmula teórica:     ", e_teorica)
	print("  % residual de pico:  ", (e_decaida / e_inicial) * 100.0, "%")
	print("  Cumple <= 5%:        ", "CORRECTO" if (e_decaida / e_inicial) <= 0.05 else "FALLO")

	var cb = Color(0.5, 0.8, 1.0)
	var ca = Color(1.0, 0.2, 0.2)
	print("\n[TEST 4] Interpolación cromática lineal (color_bajo.lerp(color_alto, v)):")
	print("  v = 0.0: ", cb.lerp(ca, 0.0))
	print("  v = 0.5: ", cb.lerp(ca, 0.5), " -> Esperado: Color(0.75, 0.5, 0.6)")
	print("  v = 1.0: ", cb.lerp(ca, 1.0))
	var e_target = 1.0 + 3.0 * 1.0
	var e_seg1 = 4.0 - 3.0 * exp(-4.0 * 1.0)
	var e_seg2 = 4.0 - 3.0 * exp(-4.0 * 2.0)
	print("\n[TEST 5] Seguimiento dinámico de energía (v=1.0, k=4.0):")
	print("  t = 1.0 s: E = ", e_seg1, " (Esperado ~3.945)")
	print("  t = 2.0 s: E = ", e_seg2, " (Esperado ~3.999)")
	print("\n[TEST 6] Atenuación solar sobre piso plano (E_max * sin^2(theta)):")
	for h in [8, 9, 10]:
		var theta_deg = (h - 6) * 15.0
		var theta_rad = deg_to_rad(theta_deg)
		var s = sin(theta_rad)
		var s2 = s * s
		print("  Hora ", h, "h (theta = ", theta_deg, "°): sin = ", s, ", sin^2 = ", s2)
	quit()
