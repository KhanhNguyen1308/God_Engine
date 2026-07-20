extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await physics_frame
	await physics_frame

	var player = scene.player
	_check(player != null, "player spawned")
	_check(scene.hud != null, "hud spawned")
	_check(get_nodes_in_group("radar_contact").size() >= 3, "radar contacts spawned")
	_check(abs(player._bearing_from_direction(Vector3(0.0, 0.0, -1.0))) < 0.1, "bearing forward is zero")
	_check(abs(player._bearing_from_direction(Vector3(1.0, 0.0, 0.0)) - 90.0) < 0.1, "bearing right is positive")
	_check(abs(player._bearing_from_direction(Vector3(-1.0, 0.0, 0.0)) + 90.0) < 0.1, "bearing left is negative")
	_check(abs(abs(player._bearing_from_direction(Vector3(0.0, 0.0, 1.0))) - 180.0) < 0.1, "bearing rear is 180")

	var mouse_start_yaw: float = player.desired_turret_yaw
	var mouse_start_elevation: float = player.desired_elevation
	var mouse_event := InputEventMouseMotion.new()
	mouse_event.relative = Vector2(24.0, -18.0)
	player._input(mouse_event)
	_check(player.desired_turret_yaw != mouse_start_yaw, "mouse motion changes desired turret yaw")
	_check(player.desired_elevation > mouse_start_elevation, "mouse motion up raises desired elevation")
	_check(player.aim_screen_offset.x != 0.0 and player.aim_screen_offset.y != 0.0, "mouse motion moves aim reticle away from screen center")
	_check(player.get_telemetry().get("aim_screen_offset", Vector2.ZERO) == player.aim_screen_offset, "telemetry exposes aim reticle screen offset")
	var sight_press := InputEventAction.new()
	sight_press.action = "aim_sight"
	sight_press.pressed = true
	player._input(sight_press)
	_check(player.gun_sight_active, "right mouse aim sight activates gun sight")
	_check(player._gun_sight_camera.current, "gun sight uses dedicated sight camera")
	_check(abs(player._gun_sight_camera.rotation.y - player.desired_turret_yaw) < 0.01, "gun sight camera follows desired yaw")
	_check(abs(player._gun_sight_camera.rotation.x - deg_to_rad(player.desired_elevation)) < 0.01, "gun sight camera follows desired elevation")
	var sight_release := InputEventAction.new()
	sight_release.action = "aim_sight"
	sight_release.pressed = false
	player._input(sight_release)
	_check(not player.gun_sight_active, "aim sight releases back to normal camera")

	var start_ammo: int = player.ammo
	var start_range: float = player.desired_range
	player._adjust_range(1)
	_check(player.desired_range > start_range, "range adjust increases range set")
	var start_elevation: float = player.desired_elevation
	player.desired_elevation = start_elevation + 8.0
	player._handle_aim(0.5)
	_check(player.barrel_elevation > start_elevation, "weapon elevates toward desired aim")
	player.desired_turret_yaw = deg_to_rad(player.main_traverse_limit + 50.0)
	player._handle_aim(0.1)
	_check(abs(rad_to_deg(player.desired_turret_yaw)) <= player.main_traverse_limit, "hardpoint clamps desired aim")
	player.pulse_radar(true)
	_check(player.last_contacts.size() >= 3, "radar sees targets")
	var static_bearing_ok := false
	for contact in player.last_contacts:
		if contact.get("name") == "Static Gun Battery":
			static_bearing_ok = float(contact.get("bearing", 999.0)) > -90.0 and float(contact.get("bearing", 999.0)) < 90.0
	_check(static_bearing_ok, "front-right radar contact uses forward bearing")
	player.sonar_focus = false
	player._update_sonar(0.1)
	_check(player.last_sonar_contacts.size() >= 1, "sonar hears emitters")
	var passive_error: float = player.sonar_error
	player.sonar_focus = true
	player._update_sonar(1.0)
	_check(player.sonar_error < passive_error, "sonar focus narrows bearing error")
	var shells_before: int = 0
	for child in scene.get_children():
		if child is ArtilleryShell:
			shells_before += 1
	player.fire_main_gun()
	_check(player.ammo == start_ammo - 1, "fire consumes ammo")
	_check(player.heat > 0.0, "fire adds heat")
	_check(player._barrel_recoil > 0.0, "fire triggers barrel recoil")
	var shell_found := false
	for child in scene.get_children():
		if child is ArtilleryShell and child.velocity.y > 0.0:
			shell_found = true
	_check(shell_found, "fire spawns visible upward ballistic shell")

	var enemy: Node = null
	for node in get_nodes_in_group("radar_contact"):
		if node.get("target_name") == "Enemy Knight AI":
			enemy = node
			break
	_check(enemy != null, "enemy AI spawned")
	if enemy:
		player.global_position = enemy.global_position + Vector3(0.0, 0.0, 8.0)
		player.look_at(enemy.global_position, Vector3.UP)
		var enemy_hp: float = enemy.health
		player.melee_strike()
		_check(enemy.health < enemy_hp, "melee damages enemy")

	var hp_before: float = player.health
	player.take_damage(20.0, player.global_position + Vector3(0.0, 4.0, 0.0), "blast")
	_check(player.health < hp_before, "player takes damage")
	player.service_at_base(false)
	_check(player.health > hp_before - 20.0, "outpost service repairs partially")
	player.service_at_base(true)
	_check(player.health == player.max_health and player.ammo == player.max_ammo, "main base full service")

	if failures.is_empty():
		print("GOD_ENGINE_SMOKE_TEST PASS")
		quit(0)
	else:
		for failure in failures:
			printerr("GOD_ENGINE_SMOKE_TEST FAIL: ", failure)
		quit(1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
