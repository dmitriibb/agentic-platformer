extends Node3D
class_name ImpactExplosion3D

@export var lifetime := 0.32
@export var start_radius := 0.12
@export var end_radius := 0.72
@export var color := Color(1.0, 0.58, 0.12, 1.0)

var _age := 0.0
var _core: MeshInstance3D
var _ring: MeshInstance3D
var _core_material: StandardMaterial3D
var _ring_material: StandardMaterial3D


func _ready() -> void:
	_build_visuals()


func _process(delta: float) -> void:
	_age += delta
	var progress := clampf(_age / lifetime, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - progress, 2.0)
	var radius := lerpf(start_radius, end_radius, eased)
	var fade := 1.0 - progress

	_core.scale = Vector3.ONE * radius
	_ring.scale = Vector3(radius * 1.45, radius * 0.16, radius * 1.45)

	_set_alpha(_core_material, fade * 0.75)
	_set_alpha(_ring_material, fade * 0.45)

	if _age >= lifetime:
		queue_free()


func configure(new_color: Color, new_start_radius: float, new_end_radius: float, new_lifetime: float) -> void:
	color = new_color
	start_radius = new_start_radius
	end_radius = new_end_radius
	lifetime = maxf(new_lifetime, 0.01)


func _build_visuals() -> void:
	_core_material = _make_material(color)
	_ring_material = _make_material(Color(1.0, 0.9, 0.38, 1.0))

	_core = MeshInstance3D.new()
	_core.name = "Core"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 1.0
	core_mesh.height = 2.0
	core_mesh.radial_segments = 16
	core_mesh.rings = 8
	_core.mesh = core_mesh
	_core.material_override = _core_material
	add_child(_core)

	_ring = MeshInstance3D.new()
	_ring.name = "ShockRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.72
	ring_mesh.outer_radius = 1.0
	_ring.mesh = ring_mesh
	_ring.rotation_degrees.x = 90.0
	_ring.material_override = _ring_material
	add_child(_ring)


func _make_material(material_color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = material_color
	material.emission_enabled = true
	material.emission = material_color
	material.emission_energy_multiplier = 0.65
	material.roughness = 0.48
	return material


func _set_alpha(material: StandardMaterial3D, alpha: float) -> void:
	var next_color := material.albedo_color
	next_color.a = clampf(alpha, 0.0, 1.0)
	material.albedo_color = next_color

	var next_emission := material.emission
	next_emission.a = next_color.a
	material.emission = next_emission
