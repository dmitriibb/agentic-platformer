extends Area3D
class_name ProjectileAttack

const COMBAT_UTILS := preload("res://scripts/combat/combat_utils.gd")
const IMPACT_EXPLOSION_SCRIPT := preload("res://scripts/combat/impact_explosion_3d.gd")
const DEFAULT_COLOR := Color(1.0, 0.82, 0.18, 1.0)

@export var damage := 12.0
@export var speed := 12.0
@export var lifetime := 1.5
@export var radius := 0.2
@export var target_group := &"enemies"
@export var movement_plane_z := 0.0
@export var visual_color := DEFAULT_COLOR
@export var explosion_radius := 0.72
@export var explosion_lifetime := 0.32

var direction := Vector3.RIGHT
var source: Node

var _age := 0.0
var _has_impacted := false
var _collision_shape: CollisionShape3D
var _visual: MeshInstance3D


func _ready() -> void:
	monitoring = true
	monitorable = false

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	_ensure_collision()
	_ensure_visual()


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	global_position += direction * speed * delta
	global_position.z = movement_plane_z


func setup(
	new_damage: float,
	new_speed: float,
	new_lifetime: float,
	new_radius: float,
	new_target_group: StringName,
	new_direction: Vector3,
	new_source: Node,
	new_visual_color := DEFAULT_COLOR
) -> void:
	damage = new_damage
	speed = new_speed
	lifetime = new_lifetime
	radius = new_radius
	target_group = new_target_group
	source = new_source
	visual_color = new_visual_color

	if new_direction.length_squared() > 0.001:
		direction = new_direction.normalized()

	if _collision_shape != null and _collision_shape.shape is SphereShape3D:
		(_collision_shape.shape as SphereShape3D).radius = radius

	if _visual != null and _visual.mesh is SphereMesh:
		var sphere := _visual.mesh as SphereMesh
		sphere.radius = radius
		sphere.height = radius * 2.0


func _on_body_entered(body: Node3D) -> void:
	if _has_impacted or body == source:
		return

	if _node_or_parent_is_in_group(body, target_group):
		COMBAT_UTILS.apply_damage_to_node(body, damage, source)
		_impact()
		return

	if body is StaticBody3D:
		_impact()


func _impact() -> void:
	if _has_impacted:
		return

	_has_impacted = true
	_spawn_explosion()
	queue_free()


func _spawn_explosion() -> void:
	var explosion = IMPACT_EXPLOSION_SCRIPT.new()
	explosion.name = "ImpactExplosion"
	explosion.configure(visual_color, radius, explosion_radius, explosion_lifetime)

	var explosion_parent := get_parent()
	if explosion_parent == null:
		explosion_parent = get_tree().current_scene

	explosion_parent.add_child(explosion)
	explosion.global_position = global_position


func _ensure_collision() -> void:
	_collision_shape = get_node_or_null("Collision") as CollisionShape3D
	if _collision_shape != null:
		return

	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "Collision"
	var shape := SphereShape3D.new()
	shape.radius = radius
	_collision_shape.shape = shape
	add_child(_collision_shape)


func _ensure_visual() -> void:
	_visual = get_node_or_null("Visual") as MeshInstance3D
	if _visual != null:
		return

	_visual = MeshInstance3D.new()
	_visual.name = "Visual"
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	_visual.mesh = mesh
	_visual.material_override = _make_material(visual_color)
	add_child(_visual)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.35
	return material


func _node_or_parent_is_in_group(node: Node, group_name: StringName) -> bool:
	var current := node
	while current != null:
		if current.is_in_group(group_name):
			return true
		current = current.get_parent()

	return false
