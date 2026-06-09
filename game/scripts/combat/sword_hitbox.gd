extends Area3D
class_name SwordHitbox

const COMBAT_UTILS := preload("res://scripts/combat/combat_utils.gd")
const DEFAULT_SWORD_SCENE := "res://assets_export/weapons/simple_sword.glb"

@export var damage := 20.0
@export var target_group := &"enemies"
@export var active_time := 0.18
@export var base_offset := 0.85
@export var sweep_distance := 0.55
@export var attack_height := 1.1
@export var hitbox_size := Vector3(1.15, 0.35, 0.35)
@export var weapon_scene_path := DEFAULT_SWORD_SCENE
@export var visual_enabled := true
@export var idle_offset := Vector3(0.48, 1.02, 0.0)
@export var idle_rotation_degrees := Vector3(0.0, 0.0, -64.0)
@export var swing_start_rotation_degrees := Vector3(0.0, 0.0, -118.0)
@export var swing_end_rotation_degrees := Vector3(0.0, 0.0, 34.0)

var source: Node

var _active := false
var _age := 0.0
var _visual_attack_time := 0.18
var _damage_start_time := 0.0
var _direction_sign := 1.0
var _damaged_health_ids := {}
var _collision_shape: CollisionShape3D
var _visual_root: Node3D


func _ready() -> void:
	monitoring = false
	monitorable = false
	visible = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	_ensure_collision()
	_ensure_visual()
	_set_idle_pose()


func _physics_process(delta: float) -> void:
	if not _active:
		return

	_age += delta
	_update_attack_pose()
	if _is_damage_window_active():
		_damage_overlapping_bodies()

	if _age >= _visual_attack_time:
		_deactivate()


func activate(
	new_source: Node,
	new_direction_sign: float,
	new_damage: float,
	new_target_group: StringName,
	new_active_time: float,
	new_attack_height: float,
	new_base_offset: float,
	new_sweep_distance: float,
	new_visual_attack_time := -1.0,
	new_damage_start_time := 0.0
) -> void:
	source = new_source
	_direction_sign = 1.0 if new_direction_sign >= 0.0 else -1.0
	damage = new_damage
	target_group = new_target_group
	active_time = maxf(new_active_time, 0.01)
	_damage_start_time = maxf(new_damage_start_time, 0.0)
	_visual_attack_time = maxf(new_visual_attack_time, active_time + _damage_start_time)
	attack_height = new_attack_height
	base_offset = new_base_offset
	sweep_distance = maxf(new_sweep_distance, 0.0)

	_age = 0.0
	_damaged_health_ids.clear()
	_active = true
	monitoring = true
	visible = true
	_update_attack_pose()
	if _is_damage_window_active():
		_damage_overlapping_bodies()
		call_deferred("_damage_overlapping_bodies")


func is_attacking() -> bool:
	return _active


func set_facing(new_direction_sign: float) -> void:
	_direction_sign = 1.0 if new_direction_sign >= 0.0 else -1.0
	if not _active:
		_set_idle_pose()


func set_visual_enabled(new_visual_enabled: bool) -> void:
	visual_enabled = new_visual_enabled

	if visual_enabled:
		_ensure_visual()
		_set_idle_pose()
	elif _visual_root != null and is_instance_valid(_visual_root):
		_visual_root.queue_free()
		_visual_root = null


func _update_attack_pose() -> void:
	var progress := clampf(_age / maxf(_visual_attack_time, 0.001), 0.0, 1.0)
	var pose := _sample_attack_pose(progress)
	position = Vector3(_direction_sign * pose.x, pose.y, 0.0)

	if _visual_root != null:
		_visual_root.scale.x = _direction_sign
		_visual_root.position = Vector3(-_direction_sign * hitbox_size.x * 0.5, 0.0, 0.0)
		_visual_root.rotation_degrees = Vector3(0.0, 0.0, pose.z)


func _set_idle_pose() -> void:
	position = Vector3(_direction_sign * idle_offset.x, idle_offset.y, idle_offset.z)

	if _visual_root != null:
		_visual_root.scale.x = _direction_sign
		_visual_root.position = Vector3.ZERO
		_visual_root.rotation_degrees = idle_rotation_degrees


func _damage_overlapping_bodies() -> void:
	if not _active or not _is_damage_window_active():
		return

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _collision_shape.shape
	query.transform = _get_query_transform()
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 0xFFFFFFFF

	if source is CollisionObject3D:
		query.exclude = [(source as CollisionObject3D).get_rid()]

	for result in space_state.intersect_shape(query, 16):
		_try_damage_body(result.get("collider"))

	for body in get_overlapping_bodies():
		_try_damage_body(body)


func _get_query_transform() -> Transform3D:
	var area_transform := global_transform
	var parent_3d := get_parent() as Node3D
	if parent_3d != null:
		area_transform = parent_3d.global_transform * transform

	return area_transform * _collision_shape.transform


func _on_body_entered(body: Node3D) -> void:
	_try_damage_body(body)


func _try_damage_body(body: Node) -> void:
	if not _active or not _is_damage_window_active() or body == source:
		return

	if not _node_or_parent_is_in_group(body, target_group):
		return

	var health = COMBAT_UTILS.find_health_component(body)
	if health == null or not health.is_alive():
		return

	var health_id = health.get_instance_id()
	if _damaged_health_ids.has(health_id):
		return

	if health.damage(damage, source) > 0.0:
		_damaged_health_ids[health_id] = true


func _deactivate() -> void:
	_active = false
	monitoring = false
	visible = true
	_set_idle_pose()


func _ensure_collision() -> void:
	_collision_shape = get_node_or_null("Collision") as CollisionShape3D
	if _collision_shape == null:
		_collision_shape = CollisionShape3D.new()
		_collision_shape.name = "Collision"
		add_child(_collision_shape)

	var shape := BoxShape3D.new()
	shape.size = hitbox_size
	_collision_shape.shape = shape


func _ensure_visual() -> void:
	if not visual_enabled:
		return

	if _visual_root != null and is_instance_valid(_visual_root):
		return

	_visual_root = Node3D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)

	var sword_scene: PackedScene
	if ResourceLoader.exists(weapon_scene_path, "PackedScene"):
		sword_scene = ResourceLoader.load(weapon_scene_path, "PackedScene") as PackedScene

	if sword_scene != null:
		var instance := sword_scene.instantiate()
		instance.name = "SimpleSword"
		_visual_root.add_child(instance)
	else:
		_add_fallback_visual()


func _add_fallback_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "FallbackSword"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.1, 0.08, 0.08)
	mesh_instance.mesh = mesh
	mesh_instance.position.x = 0.55

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.78, 0.82, 0.88, 1.0)
	material.roughness = 0.36
	mesh_instance.material_override = material
	_visual_root.add_child(mesh_instance)


func _lerp_degrees(from_degrees: Vector3, to_degrees: Vector3, weight: float) -> Vector3:
	return Vector3(
		lerpf(from_degrees.x, to_degrees.x, weight),
		lerpf(from_degrees.y, to_degrees.y, weight),
		lerpf(from_degrees.z, to_degrees.z, weight)
	)


func _sample_attack_pose(progress: float) -> Vector3:
	var ready_pose := Vector3(idle_offset.x, idle_offset.y, idle_rotation_degrees.z)
	var pullback_pose := Vector3(base_offset * 0.35, attack_height + 0.12, swing_start_rotation_degrees.z)
	var overhead_pose := Vector3(base_offset * 0.48, attack_height + 0.68, -205.0)
	var slash_pose := Vector3(base_offset + sweep_distance, attack_height + 0.08, swing_end_rotation_degrees.z)
	var follow_pose := Vector3(base_offset + sweep_distance * 0.82, attack_height - 0.22, 12.0)

	if progress < 0.18:
		return _lerp_vector3(ready_pose, pullback_pose, _ease_sine(progress / 0.18))

	if progress < 0.42:
		return _lerp_vector3(pullback_pose, overhead_pose, _ease_sine((progress - 0.18) / 0.24))

	if progress < 0.62:
		return _lerp_vector3(overhead_pose, slash_pose, _ease_sine((progress - 0.42) / 0.20))

	if progress < 0.78:
		return _lerp_vector3(slash_pose, follow_pose, _ease_sine((progress - 0.62) / 0.16))

	return _lerp_vector3(follow_pose, ready_pose, _ease_sine((progress - 0.78) / 0.22))


func _is_damage_window_active() -> bool:
	return _age >= _damage_start_time and _age <= _damage_start_time + active_time


func _lerp_vector3(from_value: Vector3, to_value: Vector3, weight: float) -> Vector3:
	return Vector3(
		lerpf(from_value.x, to_value.x, weight),
		lerpf(from_value.y, to_value.y, weight),
		lerpf(from_value.z, to_value.z, weight)
	)


func _ease_sine(value: float) -> float:
	return sin(clampf(value, 0.0, 1.0) * PI * 0.5)


func _node_or_parent_is_in_group(node: Node, group_name: StringName) -> bool:
	var current := node
	while current != null:
		if current.is_in_group(group_name):
			return true
		current = current.get_parent()

	return false
