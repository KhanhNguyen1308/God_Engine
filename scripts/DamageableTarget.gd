extends Node3D
class_name DamageableTarget

@export var target_name := "Target"
@export var max_health := 100.0
@export var mobile := false
@export var route_radius := 35.0
@export var move_speed := 8.0

var health := 100.0
var module_state := {
	"core": 1.0,
	"left_leg": 1.0,
	"right_leg": 1.0,
	"weapon": 1.0,
	"sensor": 1.0,
}
var _route_origin := Vector3.ZERO
var _route_phase := 0.0
var _status_label: Label3D
var _body_mesh: MeshInstance3D

func _ready() -> void:
	health = max_health
	_route_origin = global_position
	add_to_group("damageable")
	add_to_group("radar_contact")
	add_to_group("sonar_emitter")
	_build_visual()
	_update_label()

func _physics_process(delta: float) -> void:
	if mobile and health > 0.0:
		_route_phase += delta * move_speed / max(route_radius, 1.0)
		global_position.x = _route_origin.x + cos(_route_phase) * route_radius
		global_position.z = _route_origin.z + sin(_route_phase * 0.7) * route_radius * 0.55

func take_damage(amount: float, hit_position: Vector3, damage_type: String) -> void:
	if health <= 0.0:
		return

	health = max(health - amount, 0.0)
	var local_hit := to_local(hit_position)
	var module := _module_from_local_hit(local_hit)
	module_state[module] = max(module_state[module] - amount / max_health, 0.0)
	_flash_damage(damage_type)
	_update_label()

	if health <= 0.0:
		_destroy()

func get_radar_signature() -> float:
	if health <= 0.0:
		return 0.0
	return 1.0 if mobile else 0.75

func get_noise_signature(listener_position: Vector3) -> float:
	if health <= 0.0:
		return 0.0
	var distance: float = global_position.distance_to(listener_position)
	var base_noise := 0.2
	if mobile:
		base_noise += 0.45
	if module_state["left_leg"] < 0.6 or module_state["right_leg"] < 0.6:
		base_noise += 0.2
	return clamp(base_noise * (1.0 - distance / 520.0), 0.0, 1.0)

func _module_from_local_hit(local_hit: Vector3) -> String:
	if local_hit.y > 4.0:
		return "sensor"
	if local_hit.x < -1.8:
		return "left_leg"
	if local_hit.x > 1.8:
		return "right_leg"
	if local_hit.z < -2.0:
		return "weapon"
	return "core"

func _build_visual() -> void:
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(5.0, 7.0, 4.0)
	body.mesh = box
	body.position.y = 3.5
	body.material_override = _make_material(Color(0.42, 0.34, 0.25))
	add_child(body)
	_body_mesh = body

	var gun := MeshInstance3D.new()
	var barrel := BoxMesh.new()
	barrel.size = Vector3(1.0, 1.0, 7.5)
	gun.mesh = barrel
	gun.position = Vector3(0.0, 5.5, -4.5)
	gun.material_override = _make_material(Color(0.18, 0.17, 0.15))
	add_child(gun)

	var label := Label3D.new()
	label.position = Vector3(0.0, 8.7, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.85, 0.45)
	add_child(label)
	_status_label = label

	var collision := StaticBody3D.new()
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 7.0, 4.0)
	shape_node.shape = shape
	shape_node.position.y = 3.5
	collision.add_child(shape_node)
	add_child(collision)

func _update_label() -> void:
	if _status_label:
		_status_label.text = "%s\nHP %.0f%%" % [target_name, health]

func _flash_damage(_damage_type: String) -> void:
	if not _body_mesh:
		return
	_body_mesh.material_override = _make_material(Color(0.75, 0.25, 0.12))
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(_body_mesh):
		_body_mesh.material_override = _make_material(Color(0.42, 0.34, 0.25))

func _destroy() -> void:
	_status_label.text = "%s\nDESTROYED" % target_name
	_body_mesh.material_override = _make_material(Color(0.06, 0.05, 0.04))
	remove_from_group("radar_contact")

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material

