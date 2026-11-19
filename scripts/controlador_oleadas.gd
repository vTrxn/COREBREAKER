class_name ControladorOleadas
extends Node
signal estado_cambiado(titulo: String, detalle: String)
signal oleada_superada(num: int)
signal sector_despejado()
var _scrapper: PackedScene; var _torreta: PackedScene
var _pts1: Array[Node] = []; var _pts2: Array[Node] = []
var _total: int = 2; var _cadencia: float = 1.1; var _pausa: float = 3.0; var _dist_min: float = 2.0
var _titulo_pref: String = "HORDA"; var _detalle_pref: String = "ENEMIGOS"
var _cola: Array[Dictionary] = []; var _num: int = 0; var _timer: float = 0.0
var _iniciado: bool = false; var _esperando: bool = false; var _despejado: bool = false
var _ult_rest: int = -1; var _gen_cb: Callable
func configurar(scrap: PackedScene, torr: PackedScene, p1: Array[Node], p2: Array[Node], total: int, cad: float, pausa: float, d_min: float, tit: String, det: String, gen: Callable) -> void:
	_scrapper = scrap; _torreta = torr; _pts1 = p1; _pts2 = p2; _total = total
	_cadencia = cad; _pausa = pausa; _dist_min = d_min; _titulo_pref = tit; _detalle_pref = det; _gen_cb = gen
func iniciar() -> void:
	if _iniciado: return
	_iniciado = true; _iniciar_oleada()
func _iniciar_oleada() -> void:
	_num += 1; _esperando = false; _cola = _gen_cb.call(_num, _scrapper, _torreta)
	_cola.shuffle(); _timer = 0.45; _ult_rest = -1
	_emitir_conteo()
func _process(delta: float) -> void:
	if not _iniciado or _despejado: return
	if _esperando:
		_timer -= delta
		if _timer <= 0.0: _iniciar_oleada()
		return
	if not _cola.is_empty():
		_timer -= delta
		if _timer <= 0.0: _spawnear_uno(); _timer = _cadencia
	var vivos := get_tree().get_nodes_in_group("enemigos").size()
	var rest := vivos + _cola.size()
	if rest != _ult_rest: _ult_rest = rest; _emitir_conteo(rest)
	if _cola.is_empty() and vivos == 0:
		if _num < _total:
			_esperando = true; _timer = _pausa; oleada_superada.emit(_num)
		else:
			_despejado = true; sector_despejado.emit()
func _emitir_conteo(rest: int = -1) -> void:
	var r := rest if rest >= 0 else _cola.size() + get_tree().get_nodes_in_group("enemigos").size()
	estado_cambiado.emit("%s %d / %d" % [_titulo_pref, _num, _total], "%s: %d" % [_detalle_pref, r])
func _spawnear_uno() -> void:
	if _cola.is_empty(): return
	var item: Dictionary = _cola.pop_back()
	var esc := item["escena"] as PackedScene
	var lista := _pts2 if int(item.get("piso", 1)) == 2 and not _pts2.is_empty() else _pts1
	var pt := _elegir_punto(lista)
	if esc and pt:
		var en := esc.instantiate() as Node3D
		get_parent().add_child(en); en.global_position = pt.global_position
func _elegir_punto(lista: Array[Node]) -> Node3D:
	if lista.is_empty(): return null
	var idx := range(lista.size()); idx.shuffle()
	var activos := get_tree().get_nodes_in_group("enemigos")
	for i in idx:
		var cand := lista[i] as Node3D
		if cand and activos.all(func(e): return not is_instance_valid(e) or e.global_position.distance_to(cand.global_position) >= _dist_min):
			return cand
	return lista[idx[0]] as Node3D
