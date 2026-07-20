extends CanvasLayer
class_name PrototypeHUD

const SensorScopeScene = preload("res://scripts/SensorScope.gd")

var telemetry := {}
var contacts: Array = []
var message := "BASE READY"

var _status_panel: Control
var _gun_panel: ColorRect
var _gun: Label
var _message: Label
var _reticle: Control
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
	_status_panel = Control.new()
	_status_panel.position = Vector2(18, 16)
	_status_panel.size = Vector2(460, 116)
	_status_panel.draw.connect(_draw_status_panel)
	add_child(_status_panel)

	_gun_panel = ColorRect.new()
	_gun_panel.position = Vector2(18, 142)
	_gun_panel.size = Vector2(230, 84)
	_gun_panel.color = Color(0.01, 0.014, 0.01, 0.72)
	add_child(_gun_panel)

	_gun = Label.new()
	_gun.position = Vector2(30, 152)
	_gun.size = Vector2(210, 72)
	_gun.add_theme_font_size_override("font_size", 17)
	_gun.add_theme_color_override("font_color", Color(0.62, 1.0, 0.68, 0.92))
	add_child(_gun)

	_message = Label.new()
	_message.position = Vector2(420, 628)
	_message.size = Vector2(440, 48)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 20)
	_message.add_theme_color_override("font_color", Color(1.0, 0.76, 0.36, 0.95))
	add_child(_message)

	_reticle = Control.new()
	_reticle.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reticle.draw.connect(_draw_reticle)
	add_child(_reticle)

	_scope = SensorScopeScene.new()
	_scope.position = Vector2(805, 380)
	_scope.size = Vector2(450, 292)
	_scope.custom_minimum_size = Vector2(450, 292)
	add_child(_scope)
	_render()

func _render() -> void:
	if not _gun:
		return
	var stability: float = float(telemetry.get("stability", 0.0)) * 100.0
	var mode := "BRACE" if telemetry.get("deployed", false) else "MOBILE"
	var shield := "SHIELD" if telemetry.get("shield", false) else "NO SHIELD"
	var jam := "JAM" if telemetry.get("jammed", false) else "READY"
	_gun.text = "CHG %d   AMMO %02d\nEL %.1f  AZ %.1f\nSTAB %03d%%  %s" % [
		int(telemetry.get("charge", 1)),
		int(telemetry.get("ammo", 0)),
		float(telemetry.get("elevation", 0.0)),
		float(telemetry.get("azimuth", 0.0)),
		int(stability),
		jam,
	]
	_message.text = "%s   %s" % [message, shield if mode == "MOBILE" else mode]
	if _scope:
		_scope.set_data(telemetry, contacts)
	if _reticle:
		_reticle.queue_redraw()
	if _status_panel:
		_status_panel.queue_redraw()

func _draw_status_panel() -> void:
	var panel := Rect2(Vector2.ZERO, _status_panel.size)
	_status_panel.draw_rect(panel, Color(0.01, 0.014, 0.01, 0.72), true)
	_status_panel.draw_rect(panel, Color(0.35, 0.86, 0.55, 0.5), false, 2.0)
	_draw_bar(_status_panel, Vector2(14, 16), 420.0, "HP", float(telemetry.get("health", 0.0)) / 160.0, Color(0.78, 0.18, 0.12, 0.95))
	_draw_bar(_status_panel, Vector2(14, 46), 420.0, "EN", float(telemetry.get("energy", 0.0)) / 100.0, Color(0.23, 0.72, 1.0, 0.95))
	_draw_bar(_status_panel, Vector2(14, 76), 420.0, "HT", float(telemetry.get("heat", 0.0)) / 110.0, Color(1.0, 0.58, 0.18, 0.95))

func _draw_bar(target: Control, origin: Vector2, width: float, label: String, ratio: float, color: Color) -> void:
	var clamped: float = clamp(ratio, 0.0, 1.0)
	target.draw_string(ThemeDB.fallback_font, origin + Vector2(0, 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.86, 0.74, 0.9))
	var bar_rect := Rect2(origin + Vector2(34, 2), Vector2(width - 34, 15))
	target.draw_rect(bar_rect, Color(0.08, 0.1, 0.08, 0.9), true)
	target.draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * clamped, bar_rect.size.y)), color, true)
	target.draw_rect(bar_rect, Color(0.65, 0.8, 0.62, 0.45), false, 1.0)

func _draw_reticle() -> void:
	var viewport_size: Vector2 = _reticle.get_viewport_rect().size
	var center: Vector2 = viewport_size * 0.5
	var stability: float = clamp(float(telemetry.get("stability", 0.0)), 0.0, 1.0)
	var spread: float = lerp(54.0, 14.0, stability)
	var color: Color = Color(0.75, 1.0, 0.72, 0.88)
	_reticle.draw_line(center + Vector2(-spread, 0), center + Vector2(-10, 0), color, 2.0)
	_reticle.draw_line(center + Vector2(10, 0), center + Vector2(spread, 0), color, 2.0)
	_reticle.draw_line(center + Vector2(0, -spread), center + Vector2(0, -10), color, 2.0)
	_reticle.draw_line(center + Vector2(0, 10), center + Vector2(0, spread), color, 2.0)
	_reticle.draw_arc(center, spread, 0.0, TAU, 64, color * Color(1, 1, 1, 0.34), 1.0)
	if telemetry.get("jammed", false):
		_reticle.draw_arc(center, spread + 7.0, 0.0, TAU, 64, Color(1.0, 0.2, 0.1, 0.9), 2.0)
