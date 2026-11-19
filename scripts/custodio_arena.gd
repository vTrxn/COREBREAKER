class_name CustodioArena
extends Node3D
@onready var musica: AudioStreamPlayer = get_node_or_null("MusicaNivel") as AudioStreamPlayer
@onready var hud: HUD = get_node_or_null("HUD") as HUD
@onready var luz_alarma: LuzParpadeante = get_node_or_null("LuzAlarma") as LuzParpadeante
@onready var barrera_entrada: StaticBody3D = get_node_or_null("CompuertaEntrada") as StaticBody3D
@onready var barrera_salida: StaticBody3D = get_node_or_null("BarreraEvacuacion") as StaticBody3D
@onready var portal: PortalNivel = get_node_or_null("PortalTP") as PortalNivel
@onready var boss_hud: CanvasLayer = get_node_or_null("BossHUD") as CanvasLayer
func _ready() -> void:
	if musica: musica.finished.connect(musica.play); musica.play()
	if boss_hud: boss_hud.visible = false
	if barrera_entrada: barrera_entrada.collision_layer = 0; barrera_entrada.visible = false
	if barrera_salida: barrera_salida.collision_layer = 0; barrera_salida.visible = false
	if portal: portal.activar(true)
	if hud: hud.mostrar_estado("SECTOR 03: REFINERIA TARTARUS", "EXPLORA LA CAMARA DEL NUCLEO")
