extends Area3D
class_name BaseZone

signal knight_serviced(full_service: bool)

@export var full_service := true
@export var zone_name := "MAIN BASE"
@export var radius := 18.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_build_visual()

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("service_at_base"):
		body.service_at_base(full_service)
		knight_serviced.emit(full_service)

func _build_visual() -> void:
	var pad := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.25
	pad.mesh = cylinder
	pad.position.y = 0.06
	pad.material_override = _make_material(Color(0.16, 0.45, 0.34, 0.7) if full_service else Color(0.46, 0.35, 0.13, 0.65))
	add_child(pad)

	var label := Label3D.new()
	label.text = zone_name
	label.position = Vector3(0.0, 3.0, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.6, 1.0, 0.75) if full_service else Color(1.0, 0.78, 0.38)
	add_child(label)

	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 5.0
	collision.shape = shape
	collision.position.y = 2.5
	add_child(collision)

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material
