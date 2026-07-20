extends Node3D

const KnightControllerScene = preload("res://scripts/KnightController.gd")
const DamageableTargetScene = preload("res://scripts/DamageableTarget.gd")
const EnemyKnightAIScene = preload("res://scripts/EnemyKnightAI.gd")
const BaseZoneScene = preload("res://scripts/BaseZone.gd")
const HUDScene = preload("res://scripts/PrototypeHUD.gd")

var player: KnightController
var hud: PrototypeHUD
var counter_battery_reports: Array = []

func _ready() -> void:
	randomize()
	_build_lighting()
	_build_world()
	_spawn_player()
	_spawn_targets()
	_spawn_hud()

func _physics_process(delta: float) -> void:
	for report in counter_battery_reports:
		report["ttl"] = float(report.get("ttl", 0.0)) - delta
	counter_battery_reports = counter_battery_reports.filter(func(report): return float(report.get("ttl", 0.0)) > 0.0)

func register_projectile_trajectory(start_position: Vector3, start_velocity: Vector3, launcher: Node) -> void:
	if launcher == player:
		return
	var flat := Vector2(start_velocity.x, start_velocity.z)
	counter_battery_reports.append({
		"origin": start_position,
		"bearing": rad_to_deg(atan2(start_velocity.x, -start_velocity.z)),
		"speed": flat.length(),
		"ttl": 9.0,
	})

func get_counter_battery_reports(from_position: Vector3) -> Array:
	var reports: Array = []
	for report in counter_battery_reports:
		var origin: Vector3 = report["origin"]
		var offset := origin - from_position
		reports.append({
			"range": Vector2(offset.x, offset.z).length(),
			"bearing": rad_to_deg(atan2(offset.x, -offset.z)),
			"shell_bearing": report["bearing"],
			"ttl": report["ttl"],
		})
	return reports

func notify_artillery_impact(position: Vector3, launcher: Node) -> void:
	for enemy in get_tree().get_nodes_in_group("radar_contact"):
		if enemy == launcher:
			continue
		if enemy.has_method("investigate_impact") and enemy.global_position.distance_to(position) < 230.0:
			enemy.investigate_impact(position)

func spawn_impact_marker(position: Vector3, radius: float) -> void:
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	marker.mesh = sphere
	marker.global_position = Vector3(position.x, max(position.y, 0.35), position.z)
	marker.scale.y = 0.08
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.42, 0.12, 0.42)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override = material
	add_child(marker)
	await get_tree().create_timer(1.4).timeout
	if is_instance_valid(marker):
		marker.queue_free()

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	sun.light_energy = 2.2
	add_child(sun)

	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.33, 0.31, 0.27)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.34, 0.28)
	env.ambient_light_energy = 0.8
	world.environment = env
	add_child(world)

func _build_world() -> void:
	var ground_body := StaticBody3D.new()
	add_child(ground_body)
	var ground_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1100.0, 1100.0)
	ground_mesh.mesh = plane
	ground_mesh.material_override = _material(Color(0.28, 0.25, 0.19))
	ground_body.add_child(ground_mesh)
	var ground_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1100.0, 0.2, 1100.0)
	ground_shape.shape = shape
	ground_shape.position.y = -0.1
	ground_body.add_child(ground_shape)

	for i in range(18):
		var hill := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(randf_range(28.0, 70.0), randf_range(14.0, 42.0), randf_range(28.0, 90.0))
		hill.mesh = box
		hill.position = Vector3(randf_range(-430.0, 430.0), box.size.y * 0.5, randf_range(-430.0, 430.0))
		hill.rotation_degrees.y = randf_range(0.0, 180.0)
		hill.material_override = _material(Color(0.20, 0.18, 0.15))
		add_child(hill)

	for i in range(10):
		var stack := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		var stack_radius := randf_range(4.0, 9.0)
		cylinder.top_radius = stack_radius
		cylinder.bottom_radius = stack_radius
		cylinder.height = randf_range(24.0, 52.0)
		stack.mesh = cylinder
		stack.position = Vector3(randf_range(-220.0, 250.0), cylinder.height * 0.5, randf_range(80.0, 330.0))
		stack.material_override = _material(Color(0.30, 0.24, 0.17))
		add_child(stack)

	var base := BaseZoneScene.new()
	base.zone_name = "MAIN BASE"
	base.full_service = true
	base.position = Vector3(0.0, 0.0, 65.0)
	base.knight_serviced.connect(_on_base_service)
	add_child(base)

	var outpost := BaseZoneScene.new()
	outpost.zone_name = "FORWARD OUTPOST"
	outpost.full_service = false
	outpost.radius = 13.0
	outpost.position = Vector3(-185.0, 0.0, -95.0)
	outpost.knight_serviced.connect(_on_base_service)
	add_child(outpost)

func _spawn_player() -> void:
	player = KnightControllerScene.new()
	player.name = "LightScoutKnight"
	player.position = Vector3(0.0, 1.0, 35.0)
	player.shell_parent_path = NodePath("..")
	add_child(player)

func _spawn_targets() -> void:
	var static_target := DamageableTargetScene.new()
	static_target.target_name = "Static Gun Battery"
	static_target.position = Vector3(145.0, 0.0, -310.0)
	add_child(static_target)

	var convoy := DamageableTargetScene.new()
	convoy.target_name = "Moving Convoy"
	convoy.mobile = true
	convoy.max_health = 80.0
	convoy.position = Vector3(-170.0, 0.0, -240.0)
	convoy.route_radius = 55.0
	convoy.move_speed = 10.0
	add_child(convoy)

	var enemy_knight := EnemyKnightAIScene.new()
	enemy_knight.position = Vector3(70.0, 0.0, -150.0)
	enemy_knight.player_path = player.get_path()
	add_child(enemy_knight)

func _spawn_hud() -> void:
	hud = HUDScene.new()
	add_child(hud)
	player.telemetry_changed.connect(hud.set_telemetry)
	player.radar_contacts_updated.connect(hud.set_contacts)
	player.combat_message.connect(hud.show_message)

func _on_base_service(full_service: bool) -> void:
	if hud:
		hud.show_message("FULL SERVICE" if full_service else "OUTPOST FIELD SERVICE")

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material
