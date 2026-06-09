extends RefCounted
class_name CombatUtils

const HEALTH_COMPONENT_SCRIPT := preload("res://scripts/components/health_component.gd")


static func apply_damage_to_node(target: Node, damage: float, source: Node = null) -> bool:
	var health = find_health_component(target)
	if health == null or not health.is_alive():
		return false

	return health.damage(damage, source) > 0.0


static func apply_damage_to_group(
	source_node: Node,
	target_group: StringName,
	center: Vector3,
	radius: float,
	damage: float,
	source: Node = null
) -> int:
	if source_node == null or source_node.get_tree() == null or radius <= 0.0:
		return 0

	var hit_count := 0
	var damaged_health_ids := {}

	for target in source_node.get_tree().get_nodes_in_group(target_group):
		if not (target is Node3D) or target == source_node:
			continue

		var target_node := target as Node3D
		if target_node.global_position.distance_to(center) > radius:
			continue

		var health = find_health_component(target_node)
		if health == null or not health.is_alive():
			continue

		var health_id = health.get_instance_id()
		if damaged_health_ids.has(health_id):
			continue

		if health.damage(damage, source) > 0.0:
			damaged_health_ids[health_id] = true
			hit_count += 1

	return hit_count


static func find_health_component(node: Node):
	if node == null:
		return null

	if _is_health_component(node):
		return node

	var health = _find_health_component_down(node)
	if health != null:
		return health

	var parent := node.get_parent()
	while parent != null:
		if _is_health_component(parent):
			return parent

		health = _find_direct_health_child(parent)
		if health != null:
			return health

		parent = parent.get_parent()

	return null


static func _find_health_component_down(node: Node):
	for child in node.get_children():
		if _is_health_component(child):
			return child

	for child in node.get_children():
		var found = _find_health_component_down(child)
		if found != null:
			return found

	return null


static func _find_direct_health_child(node: Node):
	for child in node.get_children():
		if _is_health_component(child):
			return child

	return null


static func _is_health_component(node: Node) -> bool:
	return node != null and node.get_script() == HEALTH_COMPONENT_SCRIPT
