extends RefCounted
class_name LevelBuilder


func build_from_file(level_path: String, parent: Node3D) -> void:
	var level_data := _load_level_file(level_path)
	if level_data.is_empty():
		return

	build_from_data(level_data, parent)


func build_from_data(level_data: Dictionary, parent: Node3D) -> void:
	var level_root := Node3D.new()
	level_root.name = str(level_data.get("name", "Level"))
	parent.add_child(level_root)

	var environment_data := _as_dictionary(level_data.get("environment", {}))
	if not environment_data.is_empty():
		_add_environment(environment_data, level_root)

	for light_value in _as_array(level_data.get("lights", [])):
		var light_data := _as_dictionary(light_value)
		if not light_data.is_empty():
			_add_light(light_data, level_root)

	for object_value in _as_array(level_data.get("objects", [])):
		var object_data := _as_dictionary(object_value)
		if not object_data.is_empty():
			_add_object(object_data, level_root)

	var player_data := _as_dictionary(level_data.get("player", {}))
	if not player_data.is_empty():
		_add_player(player_data, level_root)

	var camera_data := _as_dictionary(level_data.get("camera", {}))
	if not camera_data.is_empty():
		_add_camera(camera_data, level_root)


func _load_level_file(level_path: String) -> Dictionary:
	if not FileAccess.file_exists(level_path):
		push_error("Level file not found: %s" % level_path)
		return {}

	var file := FileAccess.open(level_path, FileAccess.READ)
	if file == null:
		push_error("Could not open level file: %s" % level_path)
		return {}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		push_error(
			"Could not parse level file %s at line %d: %s"
			% [level_path, json.get_error_line(), json.get_error_message()]
		)
		return {}

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("Level file must contain one JSON object: %s" % level_path)
		return {}

	return json.data


func _add_environment(environment_data: Dictionary, parent: Node3D) -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = str(environment_data.get("name", "WorldEnvironment"))

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = _read_color(
		environment_data.get("background_color", [0.08, 0.09, 0.11, 1.0]),
		Color(0.08, 0.09, 0.11)
	)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = _read_color(
		environment_data.get("ambient_light_color", [0.38, 0.42, 0.48, 1.0]),
		Color(0.38, 0.42, 0.48)
	)
	environment.ambient_light_energy = float(environment_data.get("ambient_light_energy", 0.7))

	world_environment.environment = environment
	parent.add_child(world_environment)


func _add_light(light_data: Dictionary, parent: Node3D) -> void:
	var light_type := str(light_data.get("type", "directional")).to_lower()

	match light_type:
		"directional":
			var light := DirectionalLight3D.new()
			light.name = _read_name(light_data, "DirectionalLight3D")
			light.rotation_degrees = _read_vector3(light_data.get("rotation_degrees", []), Vector3.ZERO)
			light.light_energy = float(light_data.get("energy", 1.0))
			parent.add_child(light)
		_:
			push_warning("Unsupported light type in level data: %s" % light_type)


func _add_object(object_data: Dictionary, parent: Node3D) -> void:
	var object_type := str(object_data.get("type", "")).to_lower()

	match object_type:
		"box":
			_add_box(object_data, parent)
		_:
			push_warning("Unsupported object type in level data: %s" % object_type)


func _add_box(object_data: Dictionary, parent: Node3D) -> void:
	var has_collision := bool(object_data.get("collision", true))
	var body: Node3D
	if has_collision:
		body = StaticBody3D.new()
	else:
		body = Node3D.new()

	body.name = _read_name(object_data, "Box")
	body.position = _read_vector3(object_data.get("position", []), Vector3.ZERO)
	parent.add_child(body)

	var box_size := _read_vector3(object_data.get("size", [1.0, 1.0, 1.0]), Vector3.ONE)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(
		_read_color(object_data.get("color", [1.0, 1.0, 1.0, 1.0]), Color.WHITE),
		float(object_data.get("roughness", 0.78))
	)
	body.add_child(mesh_instance)

	if has_collision:
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		var shape := BoxShape3D.new()
		shape.size = box_size
		collision.shape = shape
		body.add_child(collision)


func _add_player(player_data: Dictionary, parent: Node3D) -> void:
	var player := CharacterBody3D.new()
	player.name = _read_name(player_data, "Player")
	player.position = _read_vector3(player_data.get("position", []), Vector3.ZERO)

	var script_path := str(player_data.get("script", ""))
	if script_path != "":
		var script_resource := load(script_path)
		if script_resource is Script:
			player.set_script(script_resource)
		else:
			push_warning("Could not load player script from level data: %s" % script_path)

	_apply_node_properties(player, _as_dictionary(player_data.get("controller", {})))
	_add_player_visual(_as_dictionary(player_data.get("visual", {})), player)
	_add_player_collision(_as_dictionary(player_data.get("collision", {})), player)
	parent.add_child(player)


func _add_player_visual(visual_data: Dictionary, player: CharacterBody3D) -> void:
	var visual := Node3D.new()
	visual.name = str(visual_data.get("container_name", "Visual"))
	visual.rotation_degrees = _read_vector3(visual_data.get("rotation_degrees", [0.0, 90.0, 0.0]), Vector3(0.0, 90.0, 0.0))
	visual.scale = _read_vector3(visual_data.get("scale", [1.0, 1.0, 1.0]), Vector3.ONE)
	player.add_child(visual)

	var scene_path := str(visual_data.get("scene", ""))
	var visual_scene: PackedScene
	if scene_path != "" and ResourceLoader.exists(scene_path, "PackedScene"):
		visual_scene = ResourceLoader.load(scene_path, "PackedScene") as PackedScene

	if visual_scene != null:
		var instance := visual_scene.instantiate()
		instance.name = str(visual_data.get("instance_name", "VisualInstance"))
		visual.add_child(instance)
	else:
		_add_fallback_player_visual(visual, visual_data)


func _add_fallback_player_visual(parent: Node3D, visual_data: Dictionary) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = str(visual_data.get("fallback_name", "FallbackVisual"))
	mesh_instance.position = _read_vector3(visual_data.get("fallback_position", [0.0, 1.0, 0.0]), Vector3(0.0, 1.0, 0.0))

	var mesh := BoxMesh.new()
	mesh.size = _read_vector3(visual_data.get("fallback_size", [0.75, 1.8, 0.45]), Vector3(0.75, 1.8, 0.45))
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(
		_read_color(visual_data.get("fallback_color", [0.95, 0.68, 0.22, 1.0]), Color(0.95, 0.68, 0.22)),
		0.78
	)
	parent.add_child(mesh_instance)


func _add_player_collision(collision_data: Dictionary, player: CharacterBody3D) -> void:
	if collision_data.is_empty():
		return

	var collision := CollisionShape3D.new()
	collision.name = _read_name(collision_data, "Collision")
	collision.position = _read_vector3(collision_data.get("position", []), Vector3.ZERO)

	var collision_type := str(collision_data.get("type", "capsule")).to_lower()
	match collision_type:
		"capsule":
			var shape := CapsuleShape3D.new()
			shape.radius = float(collision_data.get("radius", 0.32))
			shape.height = float(collision_data.get("height", 2.2))
			collision.shape = shape
		"box":
			var shape := BoxShape3D.new()
			shape.size = _read_vector3(collision_data.get("size", [1.0, 1.0, 1.0]), Vector3.ONE)
			collision.shape = shape
		_:
			push_warning("Unsupported player collision type in level data: %s" % collision_type)
			return

	player.add_child(collision)


func _add_camera(camera_data: Dictionary, parent: Node3D) -> void:
	var camera := Camera3D.new()
	camera.name = _read_name(camera_data, "Camera3D")
	camera.position = _read_vector3(camera_data.get("position", []), Vector3.ZERO)
	camera.current = bool(camera_data.get("current", true))
	parent.add_child(camera)

	if camera_data.has("look_at"):
		camera.look_at(_read_vector3(camera_data.get("look_at", []), Vector3.ZERO), Vector3.UP)


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _apply_node_properties(node: Node, properties: Dictionary) -> void:
	for property_name in properties:
		node.set(str(property_name), properties[property_name])


func _read_name(data: Dictionary, fallback: String) -> String:
	var node_name := str(data.get("name", fallback))
	if node_name == "":
		return fallback
	return node_name


func _read_vector3(value: Variant, fallback: Vector3) -> Vector3:
	var values := _as_array(value)
	if values.size() < 3:
		return fallback

	return Vector3(float(values[0]), float(values[1]), float(values[2]))


func _read_color(value: Variant, fallback: Color) -> Color:
	if typeof(value) == TYPE_STRING:
		return Color.html(str(value))

	var values := _as_array(value)
	if values.size() < 3:
		return fallback

	var alpha := 1.0
	if values.size() >= 4:
		alpha = float(values[3])

	return Color(float(values[0]), float(values[1]), float(values[2]), alpha)


func _as_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _as_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []
