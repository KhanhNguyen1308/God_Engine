extends Control
class_name SensorScope

var contacts: Array = []
var telemetry := {}

var radar_color := Color(0.32, 0.95, 0.68, 0.88)
var sonar_color := Color(0.48, 0.82, 1.0, 0.88)
var warning_color := Color(1.0, 0.48, 0.22, 0.95)
var panel_color := Color(0.005, 0.009, 0.006, 0.82)

func set_data(new_telemetry: Dictionary, new_contacts: Array) -> void:
	telemetry = new_telemetry
	contacts = new_contacts
	queue_redraw()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, panel_color, true)
	draw_rect(rect, radar_color * Color(1, 1, 1, 0.55), false, 2.0)
	_draw_radar(Vector2(size.x * 0.72, size.y * 0.48), min(size.x, size.y) * 0.32)
	_draw_sonar(Vector2(12.0, size.y * 0.72), Vector2(size.x * 0.56, size.y * 0.22))
	_draw_counter(Vector2(12.0, 14.0))

func _draw_radar(center: Vector2, radius: float) -> void:
	draw_arc(center, radius, 0.0, TAU, 96, radar_color * Color(1, 1, 1, 0.45), 1.0)
	draw_arc(center, radius * 0.72, 0.0, TAU, 96, radar_color * Color(1, 1, 1, 0.18), 1.0)
	draw_arc(center, radius * 0.45, 0.0, TAU, 96, radar_color * Color(1, 1, 1, 0.23), 1.0)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, radius), radar_color * Color(1, 1, 1, 0.22), 1.0)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), radar_color * Color(1, 1, 1, 0.22), 1.0)
	draw_line(center, center + Vector2(0, -radius), radar_color, 2.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-radius, -radius - 8), "RADAR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, radar_color)

	var heading: float = float(telemetry.get("heading", 0.0))
	for contact in contacts:
		var relative: float = deg_to_rad(_angle_delta(float(contact.get("bearing", 0.0)), heading))
		var range: float = clamp(float(contact.get("range", 0.0)) / 950.0, 0.0, 1.0)
		var point: Vector2 = center + Vector2(sin(relative), -cos(relative)) * radius * range
		var dot_radius: float = 6.0 if contact.get("mobile", false) else 4.0
		draw_circle(point, dot_radius + 3.0, radar_color * Color(1, 1, 1, 0.22))
		draw_circle(point, dot_radius, radar_color)

func _draw_sonar(origin: Vector2, area: Vector2) -> void:
	var mid_y: float = origin.y + area.y * 0.5
	draw_line(Vector2(origin.x, mid_y), Vector2(origin.x + area.x, mid_y), sonar_color * Color(1, 1, 1, 0.28), 1.0)
	draw_line(Vector2(origin.x + area.x * 0.5, origin.y), Vector2(origin.x + area.x * 0.5, origin.y + area.y), sonar_color * Color(1, 1, 1, 0.18), 1.0)

	var heading: float = float(telemetry.get("heading", 0.0))
	var sonar: Array = telemetry.get("sonar", [])
	for contact in sonar:
		var relative: float = _angle_delta(float(contact.get("bearing", 0.0)), heading)
		var normalized: float = clamp(relative / 180.0, -1.0, 1.0)
		var center_x: float = origin.x + area.x * (0.5 + normalized * 0.5)
		var strength: float = clamp(float(contact.get("strength", 0.0)), 0.0, 1.0)
		var error: float = clamp(float(contact.get("error", 0.0)) / 48.0, 0.0, 1.0)
		var packet_width: float = lerp(44.0, 110.0, error)
		var amplitude: float = lerp(8.0, area.y * 0.48, strength)
		var points: PackedVector2Array = PackedVector2Array()
		for i in range(36):
			var t: float = float(i) / 35.0
			var x: float = center_x - packet_width * 0.5 + packet_width * t
			var envelope: float = sin(t * PI)
			var y: float = mid_y + sin(t * TAU * 3.0) * amplitude * envelope
			points.append(Vector2(x, y))
		var color: Color = sonar_color.lerp(warning_color, strength * 0.35)
		draw_polyline(points, color, 3.0)

	var mode: String = "FOCUS" if telemetry.get("sonar_focus", false) else "PASSIVE"
	draw_string(ThemeDB.fallback_font, origin + Vector2(0, -6), "SONAR " + mode, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, sonar_color)
	draw_string(ThemeDB.fallback_font, origin + Vector2(area.x * 0.47, area.y + 14), "FWD", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, sonar_color * Color(1, 1, 1, 0.65))

func _draw_counter(origin: Vector2) -> void:
	var reports: Array = telemetry.get("counter", [])
	if reports.is_empty():
		return
	draw_string(ThemeDB.fallback_font, origin, "COUNTER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, warning_color)
	for i in range(min(reports.size(), 2)):
		var report: Dictionary = reports[i]
		var text: String = "%03dm %+.0f" % [int(report.get("range", 0.0)), float(report.get("bearing", 0.0))]
		draw_string(ThemeDB.fallback_font, origin + Vector2(0, 16 + i * 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, warning_color)

func _angle_delta(angle: float, reference: float) -> float:
	return wrapf(angle - reference, -180.0, 180.0)
