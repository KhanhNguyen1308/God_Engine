extends CanvasLayer
class_name PrototypeHUD

const SensorScopeScene = preload("res://scripts/SensorScope.gd")

var telemetry := {}
var contacts: Array = []
var message := "READY"

var _fire_control: Control
var _module_panel: Control
var _weapon_strip: Control
var _message: Label
var _scope: Control

func _ready() -> void:
	_build_ui()

func set_telemetry(data: Dictionary) -> void:
	telemetry = data
	_render()

func set_contacts(new_contacts: Array) -> void:
	contacts = new_contacts
	_render()

func show_message(text: String) -> void:
	message = text
	_render()

func _build_ui() -> void:
	_fire_control = Control.new()
	_fire_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fire_control.draw.connect(_draw_fire_control)
	add_child(_fire_control)

	_module_panel = Control.new()
	_module_panel.draw.connect(_draw_module_panel)
	add_child(_module_panel)

	_weapon_strip = Control.new()
	_weapon_strip.draw.connect(_draw_weapon_strip)
	add_child(_weapon_strip)

	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 16)
	_message.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48, 0.95))
	add_child(_message)

	_scope = SensorScopeScene.new()
	add_child(_scope)
	_render()

func _render() -> void:
	_layout_ui()
	if _message:
		var aligned := "ON TARGET" if telemetry.get("gun_aligned", false) else "TRAVERSING"
		_message.text = "%s  |  %s" % [message, aligned]
	if _scope:
		_scope.set_data(telemetry, contacts)
	if _fire_control:
		_fire_control.queue_redraw()
	if _module_panel:
		_module_panel.queue_redraw()
	if _weapon_strip:
		_weapon_strip.queue_redraw()

func _layout_ui() -> void:
	if not _fire_control:
		return
	var viewport_size: Vector2 = _fire_control.get_viewport_rect().size
	var margin := 24.0
	if _module_panel:
		_module_panel.position = Vector2(margin, max(margin, viewport_size.y - 188.0))
		_module_panel.size = Vector2(230, 165)
	if _weapon_strip:
		_weapon_strip.size = Vector2(min(500.0, viewport_size.x - 360.0), 72.0)
		_weapon_strip.position = Vector2((viewport_size.x - _weapon_strip.size.x) * 0.5, max(margin, viewport_size.y - 92.0))
	if _message:
		_message.size = Vector2(min(460.0, viewport_size.x - 360.0), 30.0)
		_message.position = Vector2((viewport_size.x - _message.size.x) * 0.5, max(margin, viewport_size.y - 138.0))
	if _scope:
		_scope.size = Vector2(335, 205)
		_scope.custom_minimum_size = _scope.size
		_scope.position = Vector2(max(margin, viewport_size.x - _scope.size.x - margin), max(margin, viewport_size.y - _scope.size.y - 28.0))

func _draw_fire_control() -> void:
	var viewport_size: Vector2 = _fire_control.get_viewport_rect().size
	var center: Vector2 = viewport_size * 0.5
	var range_set: float = float(telemetry.get("range_set", 650.0))
	var stability: float = clamp(float(telemetry.get("stability", 0.0)), 0.0, 1.0)
	var arc_limit: float = float(telemetry.get("arc_limit", 82.0))
	var desired_az: float = float(telemetry.get("desired_azimuth", 0.0))
	var actual_az: float = float(telemetry.get("azimuth", 0.0))
	var heading: float = float(telemetry.get("heading", 0.0))
	var desired_bearing: float = float(telemetry.get("desired_world_bearing", heading + desired_az))
	var actual_bearing: float = float(telemetry.get("actual_world_bearing", heading + actual_az))
	var actual_el: float = float(telemetry.get("elevation", 0.0))
	var desired_el: float = float(telemetry.get("desired_elevation", actual_el))
	var color := Color(0.62, 0.95, 0.66, 0.88)
	var muted := Color(0.62, 0.95, 0.66, 0.28)
	var amber := Color(1.0, 0.74, 0.34, 0.92)
	var blue := Color(0.36, 0.78, 1.0, 0.88)
	var warning := Color(1.0, 0.42, 0.22, 0.92)

	_draw_compass(_fire_control, viewport_size, heading, desired_bearing, actual_bearing, color, amber, blue, muted)
	var spread: float = lerp(58.0, 18.0, stability)
	_draw_fire_control_reticle(_fire_control, center, spread, heading, desired_bearing, actual_bearing, actual_el, desired_el, color, muted, amber, blue)
	_draw_range_ladder(_fire_control, center + Vector2(92, -92), range_set, color, muted)
	_draw_lead_scale(_fire_control, center + Vector2(0, 72), color, muted)
	_draw_traverse_arc(_fire_control, center + Vector2(0, 122), arc_limit, desired_az, actual_az, color, amber, warning)
	_fire_control.draw_string(ThemeDB.fallback_font, center + Vector2(-66, -78), "RNG %04dm" % int(range_set), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)
	_fire_control.draw_string(ThemeDB.fallback_font, center + Vector2(-72, -51), "EL %.1f/%.1f" % [actual_el, desired_el], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, muted)
	if bool(telemetry.get("gun_sight", false)):
		_fire_control.draw_string(ThemeDB.fallback_font, center + Vector2(-54, -108), "GUN SIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, amber)
	if abs(desired_az) >= arc_limit - 1.5:
		_fire_control.draw_string(ThemeDB.fallback_font, center + Vector2(-68, 154), "HARDPOINT LIMIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, warning)

func _draw_compass(target: Control, viewport_size: Vector2, heading: float, desired_bearing: float, actual_bearing: float, color: Color, amber: Color, blue: Color, muted: Color) -> void:
	var width: float = min(760.0, viewport_size.x - 160.0)
	var origin := Vector2((viewport_size.x - width) * 0.5, 28.0)
	var center_x: float = origin.x + width * 0.5
	var y := origin.y
	target.draw_line(Vector2(origin.x, y), Vector2(origin.x + width, y), muted, 1.5)
	for rel in range(-90, 91, 15):
		var x: float = center_x + float(rel) / 90.0 * width * 0.5
		var tick_h := 16.0 if rel % 45 == 0 else 9.0
		var tick_color: Color = color if rel == 0 else muted
		target.draw_line(Vector2(x, y - tick_h * 0.5), Vector2(x, y + tick_h), tick_color, 1.2)
		if rel % 45 == 0:
			var bearing := _wrap_degrees(heading + float(rel))
			target.draw_string(ThemeDB.fallback_font, Vector2(x - 18.0, y + 29.0), _bearing_label(bearing), HORIZONTAL_ALIGNMENT_CENTER, 36.0, 12, tick_color)
	_draw_compass_marker(target, center_x, y - 18.0, color, "H")
	_draw_bearing_marker(target, center_x, y, width, heading, actual_bearing, blue, "G")
	_draw_bearing_marker(target, center_x, y, width, heading, desired_bearing, amber, "A")
	for contact in contacts.slice(0, min(contacts.size(), 6)):
		var bearing: float = float(contact.get("bearing", 0.0))
		var rel: float = _angle_delta(bearing, heading)
		if abs(rel) <= 92.0:
			var x: float = center_x + rel / 90.0 * width * 0.5
			target.draw_circle(Vector2(x, y + 18.0), 3.5, color * Color(1, 1, 1, 0.65))
	target.draw_string(ThemeDB.fallback_font, Vector2(origin.x, y - 12.0), "COMPASS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, muted)

func _draw_compass_marker(target: Control, x: float, y: float, color: Color, label: String) -> void:
	var points := PackedVector2Array([Vector2(x, y), Vector2(x - 7.0, y + 12.0), Vector2(x + 7.0, y + 12.0)])
	target.draw_colored_polygon(points, color)
	target.draw_string(ThemeDB.fallback_font, Vector2(x - 8.0, y - 2.0), label, HORIZONTAL_ALIGNMENT_CENTER, 16.0, 10, Color(0.02, 0.03, 0.02, 0.9))

func _draw_bearing_marker(target: Control, center_x: float, y: float, width: float, heading: float, bearing: float, color: Color, label: String) -> void:
	var rel: float = clamp(_angle_delta(bearing, heading), -90.0, 90.0)
	var x: float = center_x + rel / 90.0 * width * 0.5
	target.draw_line(Vector2(x, y - 22.0), Vector2(x, y + 22.0), color, 2.0)
	target.draw_string(ThemeDB.fallback_font, Vector2(x - 8.0, y - 28.0), label, HORIZONTAL_ALIGNMENT_CENTER, 16.0, 11, color)

func _draw_fire_control_reticle(target: Control, center: Vector2, spread: float, heading: float, desired_bearing: float, actual_bearing: float, actual_el: float, desired_el: float, color: Color, muted: Color, amber: Color, blue: Color) -> void:
	# War Thunder-style mouse aim: screen center is the commanded aim point; gun marker lags behind it.
	_draw_crosshair(target, center, spread, amber, muted)
	var px_per_azimuth_degree := 5.0
	var px_per_elevation_degree := 4.8
	var gun_x: float = clamp(_angle_delta(actual_bearing, desired_bearing) * px_per_azimuth_degree, -170.0, 170.0)
	var gun_y: float = clamp(-(actual_el - desired_el) * px_per_elevation_degree, -130.0, 130.0)
	var gun_pos := center + Vector2(gun_x, gun_y)
	var hull_offset: float = clamp(_angle_delta(heading, desired_bearing) * px_per_azimuth_degree, -170.0, 170.0)
	target.draw_line(center, gun_pos, blue * Color(1, 1, 1, 0.34), 1.2)
	_draw_gun_marker(target, gun_pos, blue)
	_draw_hull_marker(target, center + Vector2(hull_offset, 50.0), color)
	target.draw_string(ThemeDB.fallback_font, center + Vector2(14.0, -12.0), "AIM", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, amber)
	target.draw_string(ThemeDB.fallback_font, gun_pos + Vector2(13.0, -6.0), "GUN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, blue * Color(1, 1, 1, 0.72))

func _draw_crosshair(target: Control, center: Vector2, spread: float, color: Color, muted: Color) -> void:
	target.draw_line(center + Vector2(-spread, 0), center + Vector2(-12, 0), color, 2)
	target.draw_line(center + Vector2(12, 0), center + Vector2(spread, 0), color, 2)
	target.draw_line(center + Vector2(0, -spread), center + Vector2(0, -12), color, 2)
	target.draw_line(center + Vector2(0, 12), center + Vector2(0, spread), color, 2)
	target.draw_arc(center, spread, 0, TAU, 96, muted, 1.2)
	target.draw_circle(center, 2.5, color)

func _draw_aim_marker(target: Control, pos: Vector2, color: Color, label: String) -> void:
	target.draw_line(pos + Vector2(-16, 0), pos + Vector2(-5, 0), color, 1.6)
	target.draw_line(pos + Vector2(5, 0), pos + Vector2(16, 0), color, 1.6)
	target.draw_line(pos + Vector2(0, -11), pos + Vector2(0, -4), color, 1.6)
	target.draw_line(pos + Vector2(0, 4), pos + Vector2(0, 11), color, 1.6)
	target.draw_string(ThemeDB.fallback_font, pos + Vector2(10, -8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

func _draw_gun_marker(target: Control, pos: Vector2, color: Color) -> void:
	target.draw_arc(pos, 10.0, 0.0, TAU, 36, color, 1.6)
	target.draw_line(pos + Vector2(-18, 0), pos + Vector2(-10, 0), color, 1.4)
	target.draw_line(pos + Vector2(10, 0), pos + Vector2(18, 0), color, 1.4)
	target.draw_line(pos + Vector2(0, -18), pos + Vector2(0, -10), color, 1.4)
	target.draw_line(pos + Vector2(0, 10), pos + Vector2(0, 18), color, 1.4)

func _draw_hull_marker(target: Control, pos: Vector2, color: Color) -> void:
	var points := PackedVector2Array([Vector2(pos.x, pos.y - 9), Vector2(pos.x - 12, pos.y + 8), Vector2(pos.x + 12, pos.y + 8)])
	target.draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), color, 1.8)

func _draw_range_ladder(target: Control, origin: Vector2, range_set: float, color: Color, muted: Color) -> void:
	target.draw_line(origin + Vector2(0, -86), origin + Vector2(0, 86), muted, 1)
	for i in range(-4, 5):
		var y: float = origin.y + float(i) * 20.0
		var tick_range: int = int(range_set + float(i) * 100.0)
		target.draw_line(Vector2(origin.x - 14, y), Vector2(origin.x + 14, y), color if i == 0 else muted, 1.5)
		if i % 2 == 0:
			target.draw_string(ThemeDB.fallback_font, Vector2(origin.x + 20, y + 5), str(max(tick_range, 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color if i == 0 else muted)

func _draw_lead_scale(target: Control, origin: Vector2, color: Color, muted: Color) -> void:
	target.draw_line(origin + Vector2(-120, 0), origin + Vector2(120, 0), muted, 1)
	for i in range(-4, 5):
		var x: float = origin.x + float(i) * 30.0
		var h: float = 18.0 if i == 0 else 10.0
		target.draw_line(Vector2(x, origin.y - h), Vector2(x, origin.y + h), color if i == 0 else muted, 1.5)

func _draw_traverse_arc(target: Control, origin: Vector2, arc_limit: float, desired_az: float, actual_az: float, color: Color, amber: Color, warning: Color) -> void:
	var width := 270.0
	var base := Color(0.62, 0.95, 0.66, 0.28)
	target.draw_line(origin + Vector2(-width * 0.5, 0), origin + Vector2(width * 0.5, 0), base, 2)
	for angle in [-arc_limit, -arc_limit * 0.5, 0.0, arc_limit * 0.5, arc_limit]:
		var x: float = origin.x + (angle / arc_limit) * width * 0.5
		var h := 13.0 if abs(angle) == arc_limit or angle == 0.0 else 8.0
		target.draw_line(Vector2(x, origin.y - h), Vector2(x, origin.y + h), color if angle == 0.0 else base, 1.5)
	var desired_x: float = origin.x + clamp(desired_az / arc_limit, -1.0, 1.0) * width * 0.5
	var actual_x: float = origin.x + clamp(actual_az / arc_limit, -1.0, 1.0) * width * 0.5
	var limit_color: Color = warning if abs(desired_az) >= arc_limit - 1.5 else amber
	target.draw_circle(Vector2(desired_x, origin.y), 6, limit_color)
	target.draw_circle(Vector2(actual_x, origin.y), 4, color)
	target.draw_string(ThemeDB.fallback_font, origin + Vector2(-width * 0.5 - 22.0, 4.0), "L", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, base)
	target.draw_string(ThemeDB.fallback_font, origin + Vector2(width * 0.5 + 12.0, 4.0), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, base)
	target.draw_string(ThemeDB.fallback_font, origin + Vector2(-40.0, 28.0), "AZ %.1f / %.1f" % [actual_az, desired_az], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)

func _draw_weapon_strip() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, _weapon_strip.size)
	_weapon_strip.draw_rect(rect, Color(0.006, 0.010, 0.008, 0.70), true)
	_weapon_strip.draw_rect(rect, Color(0.55, 0.78, 0.55, 0.34), false, 1.5)
	var jam: bool = bool(telemetry.get("jammed", false))
	var gun_color: Color = Color(1.0, 0.34, 0.18, 0.95) if jam else Color(0.65, 1.0, 0.62, 0.95)
	var heat_color := Color(1.0, 0.65, 0.32, 0.92)
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(16, 24), "MAIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, gun_color)
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(82, 24), "CHG %d" % int(telemetry.get("charge", 1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, gun_color)
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(150, 24), "AMMO %02d" % int(telemetry.get("ammo", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, gun_color)
	_draw_strip_bar(Vector2(245, 15), 80, clamp(float(telemetry.get("heat", 0.0)) / 110.0, 0.0, 1.0), heat_color)
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(338, 24), "HEAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, heat_color)
	var sight_text := "RMB SIGHT" if not bool(telemetry.get("gun_sight", false)) else "SIGHT ON"
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(16, 52), "Q/E RNG   Z/X CHG   " + sight_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.65, 0.8, 0.62, 0.58))

func _draw_strip_bar(pos: Vector2, width: float, ratio: float, color: Color) -> void:
	_weapon_strip.draw_rect(Rect2(pos, Vector2(width, 8)), Color(0.08, 0.1, 0.08, 0.9), true)
	_weapon_strip.draw_rect(Rect2(pos, Vector2(width * ratio, 8)), color, true)

func _draw_module_panel() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, _module_panel.size)
	_module_panel.draw_rect(rect, Color(0.006, 0.010, 0.008, 0.66), true)
	_module_panel.draw_rect(rect, Color(0.55, 0.78, 0.55, 0.30), false, 1.5)
	var hp_ratio: float = clamp(float(telemetry.get("health", 0.0)) / 160.0, 0.0, 1.0)
	var energy_ratio: float = clamp(float(telemetry.get("energy", 0.0)) / 100.0, 0.0, 1.0)
	_draw_silhouette_box(Vector2(98, 18), Vector2(36, 44), hp_ratio)
	_draw_silhouette_box(Vector2(76, 66), Vector2(24, 60), hp_ratio)
	_draw_silhouette_box(Vector2(132, 66), Vector2(24, 60), hp_ratio)
	_module_panel.draw_string(ThemeDB.fallback_font, Vector2(16, 22), "KNIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.92, 0.68, 0.82))
	_module_panel.draw_string(ThemeDB.fallback_font, Vector2(16, 144), "CORE %.0f%%" % (hp_ratio * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.75, 0.92, 0.68, 0.82))
	_draw_tiny_bar(Vector2(116, 135), 88, energy_ratio, Color(0.28, 0.72, 1.0, 0.9))

func _draw_silhouette_box(pos: Vector2, size: Vector2, hp_ratio: float) -> void:
	var color: Color = Color(0.65, 1.0, 0.62, 0.85).lerp(Color(1.0, 0.24, 0.12, 0.92), 1.0 - hp_ratio)
	_module_panel.draw_rect(Rect2(pos, size), color, false, 2.0)

func _draw_tiny_bar(pos: Vector2, width: float, ratio: float, color: Color) -> void:
	var rect: Rect2 = Rect2(pos, Vector2(width, 8))
	_module_panel.draw_rect(rect, Color(0.08, 0.1, 0.08, 0.9), true)
	_module_panel.draw_rect(Rect2(pos, Vector2(width * ratio, 8)), color, true)

func _angle_delta(angle: float, reference: float) -> float:
	return wrapf(angle - reference, -180.0, 180.0)

func _wrap_degrees(angle: float) -> float:
	return wrapf(angle, -180.0, 180.0)

func _bearing_label(bearing: float) -> String:
	var wrapped := fposmod(bearing + 360.0, 360.0)
	if wrapped >= 337.5 or wrapped < 22.5:
		return "N"
	if wrapped < 67.5:
		return "NE"
	if wrapped < 112.5:
		return "E"
	if wrapped < 157.5:
		return "SE"
	if wrapped < 202.5:
		return "S"
	if wrapped < 247.5:
		return "SW"
	if wrapped < 292.5:
		return "W"
	return "NW"
