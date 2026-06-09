extends Node3D
class_name HealthBar3D

const COMBAT_UTILS := preload("res://scripts/combat/combat_utils.gd")
const HEALTH_COMPONENT_SCRIPT := preload("res://scripts/components/health_component.gd")

@export var health_component_path: NodePath
@export var width := 1.3
@export var height := 0.12
@export var depth := 0.04
@export var y_offset := 2.1
@export var track_color := Color(0.1, 0.08, 0.08, 1.0)
@export var fill_color := Color(0.2, 0.95, 0.35, 1.0)

var _health: Node
var _track: MeshInstance3D
var _fill: MeshInstance3D


func _ready() -> void:
	position.y = y_offset
	_build_bar()
	_health = _find_health()

	if _health != null:
		_health.health_changed.connect(_on_health_changed)
		_on_health_changed(_health.current_health, _health.max_health)
	else:
		_update_fill(0.0)


func _build_bar() -> void:
	_track = MeshInstance3D.new()
	_track.name = "Track"
	_track.mesh = _make_box_mesh(Vector3(width, height, depth))
	_track.material_override = _make_material(track_color)
	add_child(_track)

	_fill = MeshInstance3D.new()
	_fill.name = "Fill"
	_fill.position.z = depth
	_fill.mesh = _make_box_mesh(Vector3(width, height, depth * 1.2))
	_fill.material_override = _make_material(fill_color)
	add_child(_fill)


func _on_health_changed(current_health: float, max_health: float) -> void:
	if max_health <= 0.0:
		_update_fill(0.0)
		return

	_update_fill(clampf(current_health / max_health, 0.0, 1.0))


func _update_fill(percent: float) -> void:
	if _fill == null:
		return

	_fill.visible = percent > 0.0
	var fill_width := maxf(width * percent, 0.001)
	(_fill.mesh as BoxMesh).size = Vector3(fill_width, height, depth * 1.2)
	_fill.position.x = -width * 0.5 + fill_width * 0.5


func _find_health():
	if health_component_path != NodePath():
		var health_from_path := get_node_or_null(health_component_path)
		if health_from_path != null and health_from_path.get_script() == HEALTH_COMPONENT_SCRIPT:
			return health_from_path

	return COMBAT_UTILS.find_health_component(get_parent())


func _make_box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	return material
