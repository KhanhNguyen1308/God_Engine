extends DamageableTarget
class_name EnemyKnightAI

const ShellScene = preload("res://scripts/ArtilleryShell.gd")

@export var player_path: NodePath
@export var patrol_radius := 42.0
@export var detection_range := 330.0
@export var direct_fire_range := 190.0
@export var close_range := 22.0

var ai_state := "PATROL"
var fire_cooldown := 3.0
var melee_cooldown := 0.0
var investigate_position := Vector3.ZERO
var noise_burst := 0.0
var _player: Node3D
var _shell_parent: Node

func _ready() -> void:
	target_name = "Enemy Knight AI"
	max_health = 150.0
	mobile = true
	super._ready()
	_player = get_node_or_null(player_path)
	_shell_parent = get_tree().current_scene
	modulate_label(Color(1.0, 0.32, 0.22))

func _physics_process(delta: float) -> void:
	if health <= 0.0:
		return
	fire_cooldown = max(fire_cooldown - delta, 0.0)
	melee_cooldown = max(melee_cooldown - delta, 0.0)
	noise_burst = max(noise_burst - delta, 0.0)
	if not _player:
		super._physics_process(delta)
		return

	var distance := global_position.distance_to(_player.global_position)
	if distance < close_range:
		ai_state = "CLOSE_ASSAULT"
	elif distance < detection_range:
		ai_state = "DIRECT_FIRE"
	elif investigate_position != Vector3.ZERO:
		ai_state = "INVESTIGATE"
	else:
		ai_state = "PATROL"

	match ai_state:
		"PATROL":
			_patrol(delta)
		"INVESTIGATE":
			_move_toward(investigate_position, delta, move_speed * 0.8)
		"DIRECT_FIRE":
			_face(_player.global_position, delta)
			_move_toward(_player.global_position, delta, move_speed * 0.35)
			_try_fire(distance)
		"CLOSE_ASSAULT":
			_face(_player.global_position, delta * 1.4)
			_try_melee()

func investigate_impact(position: Vector3) -> void:
	if health <= 0.0:
		return
	investigate_position = position

func _patrol(delta: float) -> void:
	_route_phase += delta * move_speed / max(patrol_radius, 1.0)
	global_position.x = _route_origin.x + cos(_route_phase) * patrol_radius
	global_position.z = _route_origin.z + sin(_route_phase * 0.8) * patrol_radius * 0.5

func _move_toward(target: Vector3, delta: float, speed: float) -> void:
	var flat := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if flat.length() < 3.0:
		return
	global_position += flat.normalized() * speed * delta
	_face(target, delta)

func _face(target: Vector3, delta: float) -> void:
	var flat := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if flat.length() < 0.1:
		return
	var desired := atan2(flat.x, flat.z)
	rotation.y = lerp_angle(rotation.y, desired, clamp(delta * 2.4, 0.0, 1.0))

func _try_fire(distance: float) -> void:
	if fire_cooldown > 0.0 or distance > direct_fire_range:
		return
	fire_cooldown = randf_range(3.4, 5.8)
	var shell := ShellScene.new()
	_shell_parent.add_child(shell)
	var start := global_position + Vector3(0.0, 6.0, 0.0) + -global_transform.basis.z * 4.5
	var aim := (_player.global_position + Vector3(0.0, 4.0, 0.0) - start).normalized()
	aim = (aim + Vector3(randf_range(-0.04, 0.04), randf_range(0.0, 0.05), randf_range(-0.04, 0.04))).normalized()
	shell.damage = 26.0
	shell.blast_radius = 5.5
	shell.launch(start, aim * 92.0, self)
	noise_burst = 4.0

func _try_melee() -> void:
	if melee_cooldown > 0.0 or not _player.has_method("take_damage"):
		return
	melee_cooldown = 3.5
	noise_burst = 2.5
	_player.take_damage(32.0, _player.global_position + Vector3(0.0, 5.0, 0.0), "melee")

func modulate_label(color: Color) -> void:
	if _status_label:
		_status_label.modulate = color

func get_noise_signature(listener_position: Vector3) -> float:
	if health <= 0.0:
		return 0.0
	var distance: float = global_position.distance_to(listener_position)
	var state_noise := 0.35
	if ai_state == "PATROL":
		state_noise = 0.45
	elif ai_state == "INVESTIGATE":
		state_noise = 0.62
	elif ai_state == "DIRECT_FIRE":
		state_noise = 0.78
	elif ai_state == "CLOSE_ASSAULT":
		state_noise = 0.95
	state_noise += min(noise_burst * 0.35, 1.0)
	return clamp(state_noise * (1.0 - distance / 620.0), 0.0, 1.0)
