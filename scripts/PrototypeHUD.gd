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
	_module_panel.position = Vector2(24, 515)
	_module_panel.size = Vector2(230, 165)
	_module_panel.draw.connect(_draw_module_panel)
	add_child(_module_panel)

	_weapon_strip = Control.new()
	_weapon_strip.position = Vector2(420, 604)
	_weapon_strip.size = Vector2(440, 72)
	_weapon_strip.draw.connect(_draw_weapon_strip)
	add_child(_weapon_strip)

	_message = Label.new()
	_message.position = Vector2(440, 558)
	_message.size = Vector2(400, 34)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 17)
	_message.add_theme_color_override("font_color", Color(0.95, 0.82, 0.48, 0.95))
	add_child(_message)

	_scope = SensorScopeScene.new()
	_scope.position = Vector2(905, 462)
	_scope.size = Vector2(335, 205)
	_scope.custom_minimum_size = Vector2(335, 205)
	add_child(_scope)
	_render()

func _render() -> void:
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

func _draw_fire_control() -> void:
	var viewport_size: Vector2 = _fire_control.get_viewport_rect().size
	var center: Vector2 = viewport_size * 0.5
	var range_set: float = float(telemetry.get("range_set", 650.0))
	var stability: float = clamp(float(telemetry.get("stability", 0.0)), 0.0, 1.0)
	var arc_limit: float = float(telemetry.get("arc_limit", 82.0))
	var desired_az: float = float(telemetry.get("desired_azimuth", 0.0))
	var actual_az: float = float(telemetry.get("azimuth", 0.0))
	var color := Color(0.72, 0.98, 0.70, 0.9)
	var muted := Color(0.72, 0.98, 0.70, 0.32)
	var warning := Color(1.0, 0.42, 0.22, 0.92)

	var spread: float = lerp(58.0, 18.0, stability)
	_draw_crosshair(_fire_control, center, spread, color, muted)
	_draw_range_ladder(_fire_control, center + Vector2(92, -92), range_set, color, muted)
	_draw_lead_scale(_fire_control, center + Vector2(0, 72), color, muted)
	_draw_traverse_arc(_fire_control, center + Vector2(0, 122), arc_limit, desired_az, actual_az, color, warning)
	_fire_control.draw_string(ThemeDB.fallback_font, center + Vector2(-68, -74), "RNG %04dm" % int(range_set), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)
	_fire_control.draw_string(ThemeDB.fallback_font, center + Vector2(-72, -48), "EL %.1f  AZ %.1f" % [float(telemetry.get("elevation", 0.0)), actual_az], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, muted)
	if abs(desired_az) >= arc_limit - 1.5:
		_fire_control.draw_string(ThemeDB.fallback_font, center + Vector2(-66, 154), "HARDPOINT LIMIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, warning)

func _draw_crosshair(target: Control, center: Vector2, spread: float, color: Color, muted: Color) -> void:
	target.draw_line(center + Vector2(-spread, 0), center + Vector2(-12, 0), color, 2)
	target.draw_line(center + Vector2(12, 0), center + Vector2(spread, 0), color, 2)
	target.draw_line(center + Vector2(0, -spread), center + Vector2(0, -12), color, 2)
	target.draw_line(center + Vector2(0, 12), center + Vector2(0, spread), color, 2)
	target.draw_arc(center, spread, 0, TAU, 96, muted, 1.2)
	target.draw_circle(center, 2.5, color)

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

func _draw_traverse_arc(target: Control, origin: Vector2, arc_limit: float, desired_az: float, actual_az: float, color: Color, warning: Color) -> void:
	var width := 250.0
	target.draw_line(origin + Vector2(-width * 0.5, 0), origin + Vector2(width * 0.5, 0), Color(0.72, 0.98, 0.70, 0.28), 2)
	for angle in [-arc_limit, 0.0, arc_limit]:
		var x: float = origin.x + (angle / arc_limit) * width * 0.5
		target.draw_line(Vector2(x, origin.y - 10), Vector2(x, origin.y + 10), color, 1.5)
	var desired_x: float = origin.x + clamp(desired_az / arc_limit, -1.0, 1.0) * width * 0.5
	var actual_x: float = origin.x + clamp(actual_az / arc_limit, -1.0, 1.0) * width * 0.5
	target.draw_circle(Vector2(desired_x, origin.y), 6, warning)
	target.draw_circle(Vector2(actual_x, origin.y), 4, color)

func _draw_weapon_strip() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, _weapon_strip.size)
	_weapon_strip.draw_rect(rect, Color(0.01, 0.012, 0.01, 0.72), true)
	_weapon_strip.draw_rect(rect, Color(0.55, 0.78, 0.55, 0.38), false, 1.5)
	var jam: bool = bool(telemetry.get("jammed", false))
	var gun_color: Color = Color(1.0, 0.34, 0.18, 0.95) if jam else Color(0.65, 1.0, 0.62, 0.95)
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(16, 24), "MAIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, gun_color)
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(78, 24), "CHG %d" % int(telemetry.get("charge", 1)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, gun_color)
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(142, 24), "AMMO %02d" % int(telemetry.get("ammo", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, gun_color)
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(230, 24), "HEAT %03d" % int(telemetry.get("heat", 0.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.65, 0.32, 0.92))
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(338, 24), "Z/X CHG", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.65, 0.8, 0.62, 0.65))
	_weapon_strip.draw_string(ThemeDB.fallback_font, Vector2(338, 46), "Q/E RNG", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.65, 0.8, 0.62, 0.65))

func _draw_module_panel() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, _module_panel.size)
	_module_panel.draw_rect(rect, Color(0.01, 0.012, 0.01, 0.68), true)
	_module_panel.draw_rect(rect, Color(0.55, 0.78, 0.55, 0.32), false, 1.5)
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
