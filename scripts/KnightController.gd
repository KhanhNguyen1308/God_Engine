extends CharacterBody3D
class_name KnightController

signal telemetry_changed(data: Dictionary)
signal radar_contacts_updated(contacts: Array)
signal combat_message(text: String)

const ShellScene = preload("res://scripts/ArtilleryShell.gd")

@export var walk_speed := 16.0
@export var boost_speed := 28.0
@export var turn_speed := 1.8
@export var energy_max := 100.0
@export var shell_parent_path: NodePath

var energy := 100.0
var shield_on := true
var deployed := false
var charge := 3
var ammo := 18
var max_ammo := 18
var health := 160.0
var max_health := 160.0
var heat := 0.0
var barrel_wear := 0.0
var jammed := false
var jam_timer := 0.0
var melee_cooldown := 0.0
var turret_yaw := 0.0
var barrel_elevation := 32.0
var stability := 0.45
var cockpit_view := false
var radar_error := 20.0
var last_contacts: Array = []
var last_sonar_contacts: Array = []
var sonar_focus := false
var sonar_error := 34.0
var last_counter_reports: Array = []
var module_state := {
	"core": 1.0,
	"left_leg": 1.0,
	"right_leg": 1.0,
	"weapon": 1.0,
	"sensor": 1.0,
}

var _shell_parent: Node
var _body_visual: Node3D
var _turret: Node3D
var _barrel: Node3D
var _third_camera: Camera3D
var _cockpit_camera: Camera3D
var _damage_flash := 0.0

func _ready() -> void:
	energy = energy_max
	_shell_parent = get_node_or_null(shell_parent_path)
	if not _shell_parent:
		_shell_parent = get_tree().current_scene
	add_to_group("player")
	add_to_group("damageable")
	_build_visual()
	_set_active_camera()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_view"):
		cockpit_view = not cockpit_view
		_set_active_camera()
	if event.is_action_pressed("toggle_deploy"):
		deployed = not deployed
	if event.is_action_pressed("charge_up"):
		charge = clampi(charge + 1, 1, 5)
	if event.is_action_pressed("charge_down"):
		charge = clampi(charge - 1, 1, 5)
	if event.is_action_pressed("shield_toggle"):
		shield_on = not shield_on
	if event.is_action_pressed("melee"):
		melee_strike()
	if event.is_action_pressed("fire"):
		fire_main_gun()
	if event.is_action_pressed("radar_pulse"):
		pulse_radar(true)
	if event.is_action_pressed("sonar_focus"):
		sonar_focus = not sonar_focus

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_aim(delta)
	_update_energy(delta)
	_update_heat_and_jam(delta)
	_update_stability(delta)
	_update_melee(delta)
	_update_damage_flash(delta)
	pulse_radar(false)
	_update_sonar(delta)
	_emit_telemetry()

func fire_main_gun() -> void:
	if ammo <= 0:
		combat_message.emit("MAGAZINE EMPTY")
		return
	if jammed:
		combat_message.emit("BREECH JAMMED")
		return
	if heat >= 96.0:
		combat_message.emit("BARREL OVERHEATED")
		return
	ammo -= 1

	var shell := ShellScene.new()
	_shell_parent.add_child(shell)
	var muzzle := _barrel.global_transform.origin + -_barrel.global_transform.basis.z * 6.5
	var speed := 58.0 + float(charge) * 20.0
	var direction := -_barrel.global_transform.basis.z.normalized()
	var inaccuracy := (1.0 - stability) * (0.045 if deployed else 0.09)
	direction = (direction + Vector3(randf_range(-inaccuracy, inaccuracy), randf_range(-inaccuracy, inaccuracy), randf_range(-inaccuracy, inaccuracy))).normalized()
	shell.damage = 45.0 + float(charge) * 12.0
	shell.blast_radius = 7.0 + float(charge) * 1.5
	shell.launch(muzzle, direction * speed, self)

	heat = min(110.0, heat + 9.0 + float(charge) * 5.5)
	barrel_wear = min(100.0, barrel_wear + 0.35 + float(charge) * 0.2)
	stability = max(stability - 0.25, 0.0)
	if heat > 72.0 and randf() < (heat - 70.0) / 180.0 + barrel_wear / 350.0:
		jammed = true
		jam_timer = randf_range(2.5, 5.0)
		combat_message.emit("LOADER JAM - CLEARING")

func melee_strike() -> void:
	if melee_cooldown > 0.0 or energy < 8.0:
		return
	melee_cooldown = 2.8
	energy = max(energy - 8.0, 0.0)
	stability = max(stability - 0.18, 0.0)
	var forward := -global_transform.basis.z.normalized()
	var best: Node3D = null
	var best_score := -1.0
	for target in get_tree().get_nodes_in_group("damageable"):
		if target == self or not (target is Node3D) or not target.has_method("take_damage"):
			continue
		var offset: Vector3 = target.global_position - global_position
		var distance: float = offset.length()
		if distance > 11.0:
			continue
		var facing := forward.dot(offset.normalized())
		if facing > 0.45 and facing > best_score:
			best = target
			best_score = facing
	if best:
		best.take_damage(46.0, best.global_position + Vector3(0.0, 4.5, 0.0), "melee")
		combat_message.emit("MELEE HIT: shield bypass")
	else:
		combat_message.emit("MELEE WHIFF")

func take_damage(amount: float, hit_position: Vector3, damage_type: String) -> void:
	var final_damage := amount
	if shield_on and energy > 0.0:
		if damage_type == "energy" or damage_type == "kinetic_fast":
			final_damage *= 0.35
			energy = max(energy - amount * 0.18, 0.0)
		elif damage_type == "blast":
			final_damage *= 0.8
			energy = max(energy - amount * 0.05, 0.0)
		elif damage_type == "melee":
			final_damage *= 1.0
	health = max(health - final_damage, 0.0)
	var module := _module_from_local_hit(to_local(hit_position))
	module_state[module] = max(module_state[module] - final_damage / max_health, 0.0)
	_damage_flash = 0.3
	combat_message.emit("HIT %s: -%.0f" % [module.to_upper(), final_damage])

func get_radar_signature() -> float:
	return 1.2 if health > 0.0 else 0.0

func get_noise_signature(listener_position: Vector3) -> float:
	if health <= 0.0:
		return 0.0
	var speed_noise: float = clamp(Vector2(velocity.x, velocity.z).length() / boost_speed, 0.0, 1.0)
	var system_noise := 0.2 + speed_noise * 0.35
	if shield_on:
		system_noise += 0.12
	if heat > 50.0:
		system_noise += 0.18
	var distance: float = global_position.distance_to(listener_position)
	return clamp(system_noise * (1.0 - distance / 520.0), 0.0, 1.0)

func pulse_radar(active_ping: bool) -> void:
	if active_ping and energy >= 4.0:
		energy -= 4.0
		radar_error = max(8.0, radar_error - 10.0)
	else:
		radar_error = min(42.0, radar_error + get_physics_process_delta_time() * 2.0)

	var contacts: Array = []
	for node in get_tree().get_nodes_in_group("radar_contact"):
		if node == self or not (node is Node3D):
			continue
		if node.has_method("get_radar_signature") and node.get_radar_signature() <= 0.0:
			continue
		var offset: Vector3 = node.global_position - global_position
		var flat := Vector2(offset.x, offset.z)
		var range := flat.length()
		if range > 950.0:
			continue
		var bearing := rad_to_deg(atan2(offset.x, offset.z))
		var error := radar_error + range * 0.025
		contacts.append({
			"name": node.get("target_name") if node.get("target_name") != null else "Contact",
			"range": range,
			"bearing": bearing,
			"error": error,
			"mobile": bool(node.get("mobile")) if node.get("mobile") != null else false,
		})
	last_contacts = contacts
	var world := get_tree().current_scene
	last_counter_reports = world.get_counter_battery_reports(global_position) if world and world.has_method("get_counter_battery_reports") else []
	radar_contacts_updated.emit(contacts)


func _update_sonar(delta: float) -> void:
	if sonar_focus and energy > 0.0:
		energy = max(energy - 1.6 * delta, 0.0)
		sonar_error = max(8.0, sonar_error - 22.0 * delta)
	else:
		sonar_error = min(48.0, sonar_error + 8.0 * delta)

	var contacts: Array = []
	for node in get_tree().get_nodes_in_group("sonar_emitter"):
		if node == self or not (node is Node3D) or not node.has_method("get_noise_signature"):
			continue
		var strength: float = node.get_noise_signature(global_position)
		if strength <= 0.04:
			continue
		var offset: Vector3 = node.global_position - global_position
		var bearing: float = rad_to_deg(atan2(offset.x, offset.z))
		var confidence: float = clamp(strength * (1.3 if sonar_focus else 0.85), 0.0, 1.0)
		var bearing_error: float = sonar_error * (1.0 - confidence * 0.65)
		contacts.append({
			"name": node.get("target_name") if node.get("target_name") != null else "Noise",
			"bearing": bearing,
			"strength": strength,
			"error": bearing_error,
			"focus": sonar_focus,
		})
	contacts.sort_custom(func(a, b): return float(a.get("strength", 0.0)) > float(b.get("strength", 0.0)))
	last_sonar_contacts = contacts.slice(0, 5)

func service_at_base(full_service := true) -> void:
	ammo = max_ammo if full_service else mini(max_ammo, ammo + 8)
	energy = energy_max if full_service else min(energy_max, energy + 45.0)
	stability = 1.0
	if full_service:
		health = max_health
		heat = 0.0
		jammed = false
		jam_timer = 0.0
		for key in module_state.keys():
			module_state[key] = 1.0
	else:
		health = min(max_health, health + 35.0)
		heat = max(0.0, heat - 35.0)

func get_telemetry() -> Dictionary:
	return {
		"speed": Vector2(velocity.x, velocity.z).length(),
		"energy": energy,
		"ammo": ammo,
		"charge": charge,
		"elevation": barrel_elevation,
		"azimuth": rad_to_deg(turret_yaw),
		"stability": stability,
		"deployed": deployed,
		"view": "COCKPIT" if cockpit_view else "CHASE",
		"health": health,
		"heat": heat,
		"wear": barrel_wear,
		"jammed": jammed,
		"shield": shield_on,
		"melee": melee_cooldown,
		"counter": last_counter_reports,
		"sonar": last_sonar_contacts,
		"sonar_focus": sonar_focus,
		"sonar_error": sonar_error,
	}

func _handle_movement(delta: float) -> void:
	var forward := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var turn := Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	rotate_y(turn * turn_speed * delta)

	var leg_factor: float = min(module_state["left_leg"], module_state["right_leg"])
	var wants_boost := Input.is_action_pressed("boost") and energy > 1.0 and not deployed and leg_factor > 0.35
	var speed := boost_speed if wants_boost else walk_speed
	speed *= clamp(0.45 + leg_factor * 0.55, 0.25, 1.0)
	if deployed:
		speed = 1.5
	velocity.x = -global_transform.basis.z.x * forward * speed
	velocity.z = -global_transform.basis.z.z * forward * speed
	velocity.y -= 30.0 * delta
	move_and_slide()

	if wants_boost and abs(forward) > 0.1:
		energy = max(energy - 18.0 * delta, 0.0)

func _handle_aim(delta: float) -> void:
	var weapon_factor: float = module_state["weapon"]
	var yaw_input := Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
	var elev_input := Input.get_action_strength("aim_up") - Input.get_action_strength("aim_down")
	turret_yaw += yaw_input * delta * 0.75 * clamp(weapon_factor, 0.2, 1.0)
	barrel_elevation = clamp(barrel_elevation + elev_input * delta * 24.0 * clamp(weapon_factor, 0.2, 1.0), 0.0, 68.0)
	_turret.rotation.y = turret_yaw
	_barrel.rotation.x = deg_to_rad(barrel_elevation)

func _update_energy(delta: float) -> void:
	var shield_drain := 3.5 if shield_on else 0.0
	energy = clamp(energy - shield_drain * delta + 5.0 * delta, 0.0, energy_max)

func _update_heat_and_jam(delta: float) -> void:
	heat = max(0.0, heat - delta * (7.0 if deployed else 4.0))
	if jammed:
		jam_timer -= delta
		if jam_timer <= 0.0:
			jammed = false
			combat_message.emit("BREECH CLEAR")

func _update_stability(delta: float) -> void:
	var moving := Vector2(velocity.x, velocity.z).length()
	var target := 0.35
	if deployed:
		target = 0.96
	elif moving < 0.5:
		target = 0.75
	else:
		target = clamp(0.72 - moving / boost_speed * 0.45, 0.18, 0.72)
	target *= clamp(module_state["left_leg"], 0.35, 1.0)
	target *= clamp(module_state["right_leg"], 0.35, 1.0)
	stability = move_toward(stability, target, delta * (0.45 if deployed else 0.25))

func _update_melee(delta: float) -> void:
	melee_cooldown = max(melee_cooldown - delta, 0.0)

func _update_damage_flash(delta: float) -> void:
	_damage_flash = max(_damage_flash - delta, 0.0)

func _module_from_local_hit(local_hit: Vector3) -> String:
	if local_hit.y > 6.5:
		return "sensor"
	if local_hit.x < -1.4:
		return "left_leg"
	if local_hit.x > 1.4:
		return "right_leg"
	if local_hit.z < -2.0:
		return "weapon"
	return "core"

func _emit_telemetry() -> void:
	telemetry_changed.emit(get_telemetry())

func _set_active_camera() -> void:
	if not _third_camera or not _cockpit_camera:
		return
	_third_camera.current = not cockpit_view
	_cockpit_camera.current = cockpit_view

func _build_visual() -> void:
	_body_visual = Node3D.new()
	add_child(_body_visual)

	var torso := _box(Vector3(4.0, 6.0, 3.0), Vector3(0.0, 5.0, 0.0), Color(0.34, 0.28, 0.21))
	_body_visual.add_child(torso)
	var left_leg := _box(Vector3(1.2, 4.0, 1.2), Vector3(-1.2, 2.0, 0.0), Color(0.23, 0.21, 0.18))
	_body_visual.add_child(left_leg)
	var right_leg := _box(Vector3(1.2, 4.0, 1.2), Vector3(1.2, 2.0, 0.0), Color(0.23, 0.21, 0.18))
	_body_visual.add_child(right_leg)
	var melee_arm := _box(Vector3(0.8, 4.2, 0.8), Vector3(-2.8, 5.0, -0.5), Color(0.29, 0.25, 0.20))
	_body_visual.add_child(melee_arm)

	_turret = Node3D.new()
	_turret.position = Vector3(0.0, 8.1, 0.0)
	_body_visual.add_child(_turret)
	_turret.add_child(_box(Vector3(3.5, 1.5, 3.0), Vector3.ZERO, Color(0.44, 0.33, 0.20)))

	_barrel = Node3D.new()
	_barrel.position = Vector3(0.0, 0.2, -1.9)
	_turret.add_child(_barrel)
	_barrel.add_child(_box(Vector3(0.55, 0.55, 8.0), Vector3(0.0, 0.0, -4.0), Color(0.12, 0.11, 0.10)))

	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 2.2
	capsule.height = 8.0
	collider.shape = capsule
	collider.position.y = 4.0
	add_child(collider)

	_third_camera = Camera3D.new()
	_third_camera.position = Vector3(0.0, 12.0, 21.0)
	_third_camera.rotation_degrees.x = -24.0
	add_child(_third_camera)

	_cockpit_camera = Camera3D.new()
	_cockpit_camera.position = Vector3(0.0, 7.6, -1.2)
	_cockpit_camera.rotation_degrees.x = -7.0
	add_child(_cockpit_camera)

func _box(size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh.material_override = material
	return mesh
