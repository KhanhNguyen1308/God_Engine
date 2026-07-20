extends Area3D
class_name ArtilleryShell

var velocity := Vector3.ZERO
var blast_radius := 8.0
var damage := 55.0
var life_time := 20.0
var shell_gravity := 24.0
var source: Node
var damage_type := "blast"

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	mesh.mesh = sphere
	mesh.material_override = _make_material(Color(0.95, 0.78, 0.38))
	add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	collision.shape = shape
	add_child(collision)

func launch(start_position: Vector3, start_velocity: Vector3, launcher: Node) -> void:
	global_position = start_position
	velocity = start_velocity
	source = launcher
	var world := get_tree().current_scene
	if world and world.has_method("register_projectile_trajectory"):
		world.register_projectile_trajectory(start_position, start_velocity, launcher)

func _physics_process(delta: float) -> void:
	life_time -= delta
	velocity.y -= shell_gravity * delta
	global_position += velocity * delta

	if global_position.y <= 0.15 or life_time <= 0.0:
		_impact()

func _impact() -> void:
	var world := get_tree().current_scene
	if world:
		if world.has_method("spawn_impact_marker"):
			world.call_deferred("spawn_impact_marker", global_position, blast_radius)
		if world.has_method("notify_artillery_impact"):
			world.call_deferred("notify_artillery_impact", global_position, source)

	for target in get_tree().get_nodes_in_group("damageable"):
		if target == source or not target.has_method("take_damage"):
			continue
		var distance := global_position.distance_to(target.global_position)
		if distance <= blast_radius:
			var falloff: float = 1.0 - clamp(distance / blast_radius, 0.0, 1.0)
			target.take_damage(damage * falloff, global_position, damage_type)

	queue_free()

func _on_body_entered(body: Node) -> void:
	if body == source:
		return
	_impact()

func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.35
	return material
