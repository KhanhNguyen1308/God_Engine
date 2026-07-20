extends CanvasLayer
class_name PrototypeHUD

var telemetry := {}
var contacts: Array = []
var message := "BASE READY"

var _status: Label
var _radar: Label
var _help: Label

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
	_status = Label.new()
	_status.position = Vector2(18, 16)
	_status.size = Vector2(430, 270)
	_status.add_theme_font_size_override("font_size", 17)
	add_child(_status)

	_radar = Label.new()
	_radar.position = Vector2(18, 300)
	_radar.size = Vector2(530, 390)
	_radar.add_theme_font_size_override("font_size", 16)
	add_child(_radar)

	_help = Label.new()
	_help.position = Vector2(720, 16)
	_help.size = Vector2(540, 205)
	_help.add_theme_font_size_override("font_size", 15)
	_help.text = "W/S move  A/D turn  Shift boost\nJ/L azimuth  I/K elevation  Q/E charge\nMouse1 fire  R radar pulse  B brace\nF melee  G shield  T sonar focus  Tab view"
	add_child(_help)
	_render()

func _render() -> void:
	if not _status:
		return
	_status.text = "LIGHT SCOUT KNIGHT\n"
	_status.text += "View: %s  Brace: %s  Shield: %s\n" % [telemetry.get("view", "CHASE"), "LOCKED" if telemetry.get("deployed", false) else "MOBILE", "ON" if telemetry.get("shield", false) else "OFF"]
	_status.text += "HP: %05.1f  Energy: %05.1f  Ammo: %02d\n" % [telemetry.get("health", 0.0), telemetry.get("energy", 0.0), telemetry.get("ammo", 0)]
	_status.text += "Charge: %d  Elev: %04.1f  Az: %04.1f\n" % [telemetry.get("charge", 1), telemetry.get("elevation", 0.0), telemetry.get("azimuth", 0.0)]
	_status.text += "Stability: %03d%%  Speed: %04.1f\n" % [int(telemetry.get("stability", 0.0) * 100.0), telemetry.get("speed", 0.0)]
	_status.text += "Heat: %03d%%  Wear: %03d%%  Breech: %s\n" % [int(telemetry.get("heat", 0.0)), int(telemetry.get("wear", 0.0)), "JAM" if telemetry.get("jammed", false) else "CLEAR"]
	_status.text += "Melee CD: %.1fs  Logistics: %s" % [telemetry.get("melee", 0.0), message]

	_radar.text = "RADAR CONTACTS\n"
	if contacts.is_empty():
		_radar.text += "No returns. Press R for active pulse.\n"
	for contact in contacts:
		_radar.text += "%s  RNG %04dm  BRG %+04.0f  ERR +/-%.0fm%s\n" % [
			contact.get("name", "Contact"),
			int(contact.get("range", 0.0)),
			contact.get("bearing", 0.0),
			contact.get("error", 0.0),
			" MOV" if contact.get("mobile", false) else "",
		]

	var reports: Array = telemetry.get("counter", [])
	var sonar: Array = telemetry.get("sonar", [])
	_radar.text += "\nSONAR / AUDIO DIRECTION %s\n" % ["FOCUS" if telemetry.get("sonar_focus", false) else "PASSIVE"]
	if sonar.is_empty():
		_radar.text += "No readable engine noise. Toggle T to focus.\n"
	for contact in sonar:
		_radar.text += "%s  BRG %+04.0f  STR %03d%%  ERR +/-%.0fdeg\n" % [
			contact.get("name", "Noise"),
			contact.get("bearing", 0.0),
			int(contact.get("strength", 0.0) * 100.0),
			contact.get("error", 0.0),
		]

	_radar.text += "\nCOUNTER-BATTERY\n"
	if reports.is_empty():
		_radar.text += "No hostile trajectories.\n"
	for report in reports:
		_radar.text += "ORIGIN RNG %04dm  BRG %+04.0f  SHELL %+04.0f  TTL %.1f\n" % [
			int(report.get("range", 0.0)),
			report.get("bearing", 0.0),
			report.get("shell_bearing", 0.0),
			report.get("ttl", 0.0),
		]
