@tool
extends EditorScenePostImport

const NO_SHADOW_PROPS = [
	"cage_bulkhead_lamp_9481", "ceiling_troffer_4tube_pbr", "small-fluorescent-lamp-02",
	"wall_breaker_box_440v", "soda_cup_straw_prop02", "mech-keyboard-lowpoly-01",
	"widescreen_monitor_v1", "diag-pc-display-free3d", "wall_telemetry_screen_04",
	"sector_wall_sign_light", "jumppad_octagon_scifi"
]

const VIS_RANGE = {
	"soda_cup_straw_prop02": 26.0,
	"mech-keyboard-lowpoly-01": 26.0,
	"cage_bulkhead_lamp_9481": 36.0,
	"wall_breaker_box_440v": 36.0,
	"biohazard_specimen_jar_02": 38.0,
	"cryo_canister_jar_blue": 38.0,
	"widescreen_monitor_v1": 36.0,
	"diag-pc-display-free3d": 36.0,
	"gaming_pc_tower_cyber": 36.0,
	"office_swivel_chair_free": 46.0,
	"wall_telemetry_screen_04": 48.0,
	"small-fluorescent-lamp-02": 46.0,
	"ceiling_troffer_4tube_pbr": 50.0,
	"old_hazard_barrel_v2": 50.0,
	"mil_ammo_supply_case_03": 48.0,
	"sector_wall_sign_light": 52.0,
	"jumppad_octagon_scifi": 56.0,
	"control-console-desk-01": 58.0,
	"garage_workbench_metal": 58.0,
	"double-metal-locker-lowpoly": 58.0,
	"steel_crew_locker_open": 58.0,
	"modular-server-rack-07": 58.0,
	"heavy-cargo-crate-scifi": 60.0,
	"industrial-railing-2m-lowpoly": 58.0,
	"metal_safety_rail_4m_pbr": 58.0,
}

func _post_import(scene: Node) -> Object:
	var stem := get_source_file().get_file().get_basename()
	var no_shadow := stem in NO_SHADOW_PROPS
	var v_end: float = VIS_RANGE.get(stem, 0.0)
	_apply_recursive(scene, no_shadow, v_end)
	return scene

func _apply_recursive(node: Node, no_shadow: bool, v_end: float) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if no_shadow:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if v_end > 0.0:
			mi.visibility_range_end = v_end
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	for c in node.get_children():
		_apply_recursive(c, no_shadow, v_end)
