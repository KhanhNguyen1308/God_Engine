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

	var start_ammo: int = player.ammo
	var start_range: float = player.desired_range
	player._adjust_range(1)
	_check(player.desired_range > start_range, "range adjust increases range set")
	player.desired_turret_yaw = deg_to_rad(player.main_traverse_limit + 50.0)
	player._handle_aim(0.1)
	_check(abs(rad_to_deg(player.desired_turret_yaw)) <= player.main_traverse_limit, "hardpoint clamps desired aim")
	player.pulse_radar(true)
	_check(player.last_contacts.size() >= 3, "radar sees targets")
	player.sonar_focus = false
	player._update_sonar(0.1)
	_check(player.last_sonar_contacts.size() >= 1, "sonar hears emitters")
	var passive_error: float = player.sonar_error
	player.sonar_focus = true
	player._update_sonar(1.0)
	_check(player.sonar_error < passive_error, "sonar focus narrows bearing error")
	player.fire_main_gun()
	_check(player.ammo == start_ammo - 1, "fire consumes ammo")
	_check(player.heat > 0.0, "fire adds heat")

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
