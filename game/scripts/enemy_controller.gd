extends CharacterBody3D
class_name EnemyController

const COMBAT_UTILS := preload("res://scripts/combat/combat_utils.gd")
const PROJECTILE_SCRIPT := preload("res://scripts/combat/projectile_attack.gd")
const SWORD_HITBOX_SCRIPT := preload("res://scripts/combat/sword_hitbox.gd")

@export var movement_mode := "stand"
@export var move_speed := 2.2
@export var gravity := 22.0
@export var patrol_min_x := -4.0
@export var patrol_max_x := 4.0
@export var chase_range := 7.0
@export var stop_distance := 1.35
@export var movement_plane_z := 0.0

@export var target_group := &"player"
@export var attack_mode := "melee"
@export var attack_height := 0.85
@export var melee_damage := 10.0
@export var melee_range := 1.35
@export var melee_cooldown := 1.0
@export var melee_active_time := 0.22
@export var melee_offset := 0.72
@export var ranged_damage := 8.0
@export var ranged_range := 7.5
@export var ranged_cooldown := 1.6
@export var projectile_speed := 8.5
@export var projectile_lifetime := 2.0
@export var projectile_radius := 0.18
@export var destroy_on_death := true

var _facing_sign := -1.0
var _attack_cooldown_remaining := 0.0
var _health: Node
var _sword_hitbox: Node


func _ready() -> void:
	add_to_group(&"enemies")
	_ensure_sword_hitbox()
	_update_sword_facing()
	global_position.z = movement_plane_z

	_health = COMBAT_UTILS.find_health_component(self)
	if _health != null and not _health.died.is_connected(_on_died):
		_health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)

	var target := _find_target()
	_update_movement(delta, target)
	move_and_slide()
	global_position.z = movement_plane_z
	_try_attack(target)


func _update_movement(delta: float, target: Node3D) -> void:
	velocity.z = 0.0

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	match movement_mode.to_lower():
		"stand", "idle", "none":
			velocity.x = 0.0
		"patrol", "move":
			_update_patrol_velocity()
		"chase":
			_update_chase_velocity(target)
		_:
			velocity.x = 0.0


func _update_patrol_velocity() -> void:
	if patrol_min_x > patrol_max_x:
		var old_min := patrol_min_x
		patrol_min_x = patrol_max_x
		patrol_max_x = old_min

	if global_position.x <= patrol_min_x:
		_facing_sign = 1.0
	elif global_position.x >= patrol_max_x:
		_facing_sign = -1.0

	_update_sword_facing()
	velocity.x = _facing_sign * move_speed


func _update_chase_velocity(target: Node3D) -> void:
	if target == null:
		velocity.x = 0.0
		return

	var offset_x := target.global_position.x - global_position.x
	if absf(offset_x) > 0.01:
		_facing_sign = 1.0 if offset_x > 0.0 else -1.0
		_update_sword_facing()

	if absf(offset_x) > stop_distance and global_position.distance_to(target.global_position) <= chase_range:
		velocity.x = _facing_sign * move_speed
	else:
		velocity.x = 0.0


func _try_attack(target: Node3D) -> void:
	if target == null or _attack_cooldown_remaining > 0.0:
		return

	var offset_x := target.global_position.x - global_position.x
	if absf(offset_x) > 0.01:
		_facing_sign = 1.0 if offset_x > 0.0 else -1.0
		_update_sword_facing()

	match attack_mode.to_lower():
		"melee":
			_try_melee_attack()
		"ranged", "range":
			_try_ranged_attack(target)
		"melee_and_ranged", "hybrid":
			if global_position.distance_to(target.global_position) <= melee_range:
				_try_melee_attack()
			else:
				_try_ranged_attack(target)


func _try_melee_attack() -> void:
	_ensure_sword_hitbox()
	_update_sword_facing()
	_sword_hitbox.activate(
		self,
		_facing_sign,
		melee_damage,
		target_group,
		melee_active_time,
		attack_height,
		melee_offset,
		melee_range - melee_offset
	)
	_attack_cooldown_remaining = melee_cooldown


func _try_ranged_attack(target: Node3D) -> void:
	if global_position.distance_to(target.global_position) > ranged_range:
		return

	_spawn_projectile(_facing_sign)
	_attack_cooldown_remaining = ranged_cooldown


func _spawn_projectile(direction_sign: float) -> void:
	var projectile = PROJECTILE_SCRIPT.new()
	projectile.name = "EnemyProjectile"
	projectile.setup(
		ranged_damage,
		projectile_speed,
		projectile_lifetime,
		projectile_radius,
		target_group,
		Vector3(direction_sign, 0.0, 0.0),
		self,
		Color(1.0, 0.18, 0.14, 1.0)
	)
	projectile.movement_plane_z = movement_plane_z

	var projectile_parent := get_parent()
	if projectile_parent == null:
		projectile_parent = get_tree().current_scene

	projectile_parent.add_child(projectile)
	projectile.global_position = global_position + Vector3(direction_sign * 0.85, attack_height, 0.0)


func _ensure_sword_hitbox() -> void:
	if _sword_hitbox != null and is_instance_valid(_sword_hitbox):
		return

	_sword_hitbox = get_node_or_null("SwordHitbox")
	if _sword_hitbox != null:
		return

	_sword_hitbox = SWORD_HITBOX_SCRIPT.new()
	_sword_hitbox.name = "SwordHitbox"
	add_child(_sword_hitbox)
	_update_sword_facing()


func _update_sword_facing() -> void:
	if _sword_hitbox == null or not is_instance_valid(_sword_hitbox):
		return

	_sword_hitbox.set_facing(_facing_sign)


func _find_target() -> Node3D:
	var closest_target: Node3D
	var closest_distance := INF

	for candidate in get_tree().get_nodes_in_group(target_group):
		if not (candidate is Node3D):
			continue

		var health = COMBAT_UTILS.find_health_component(candidate)
		if health != null and not health.is_alive():
			continue

		var candidate_node := candidate as Node3D
		var distance := global_position.distance_to(candidate_node.global_position)
		if distance < closest_distance:
			closest_target = candidate_node
			closest_distance = distance

	return closest_target


func _on_died(_source: Node) -> void:
	if destroy_on_death:
		queue_free()
