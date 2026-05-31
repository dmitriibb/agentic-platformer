extends Node

const PLAYER_SCRIPT := preload("res://scripts/player_controller.gd")

var menu_layer: CanvasLayer
var start_button: Button
var exit_button: Button
var confirm_exit: ConfirmationDialog
var game_world: Node3D
var is_game_running := false


func _ready() -> void:
	_build_game_world()
	_build_menu()
	_show_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if confirm_exit.visible:
			confirm_exit.hide()
			return

		if is_game_running:
			_show_menu()


func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.name = "MainMenuLayer"
	menu_layer.layer = 10
	add_child(menu_layer)

	var root := Control.new()
	root.name = "MenuRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(root)

	var dim := ColorRect.new()
	dim.name = "DimBackground"
	dim.color = Color(0.02, 0.025, 0.03, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "MenuPanel"
	panel.custom_minimum_size = Vector2(380, 260)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Agentic Platformer"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)

	start_button = Button.new()
	start_button.text = "Start"
	start_button.custom_minimum_size = Vector2(0, 46)
	start_button.pressed.connect(_on_start_pressed)
	layout.add_child(start_button)

	exit_button = Button.new()
	exit_button.text = "Exit"
	exit_button.custom_minimum_size = Vector2(0, 46)
	exit_button.pressed.connect(_on_exit_pressed)
	layout.add_child(exit_button)

	confirm_exit = ConfirmationDialog.new()
	confirm_exit.title = "Exit Game?"
	confirm_exit.dialog_text = "Close the game?"
	confirm_exit.ok_button_text = "Exit"
	confirm_exit.confirmed.connect(_on_exit_confirmed)
	menu_layer.add_child(confirm_exit)


func _build_game_world() -> void:
	game_world = Node3D.new()
	game_world.name = "GameWorld"
	game_world.visible = false
	add_child(game_world)

	_add_lighting()
	_add_room()
	_add_player()
	_add_camera()


func _add_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 2.2
	game_world.add_child(sun)

	var ambient := WorldEnvironment.new()
	ambient.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.08, 0.09, 0.11)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.38, 0.42, 0.48)
	environment.ambient_light_energy = 0.7
	ambient.environment = environment
	game_world.add_child(ambient)


func _add_room() -> void:
	_create_box("Floor", Vector3(0, -0.25, 0), Vector3(14, 0.5, 6), Color(0.22, 0.24, 0.25))
	_create_box("BackWall", Vector3(0, 1.5, -3.25), Vector3(14, 3, 0.5), Color(0.15, 0.16, 0.18))
	_create_box("LeftWall", Vector3(-7.25, 1.5, 0), Vector3(0.5, 3, 6), Color(0.12, 0.13, 0.15))
	_create_box("RightWall", Vector3(7.25, 1.5, 0), Vector3(0.5, 3, 6), Color(0.12, 0.13, 0.15))


func _create_box(node_name: String, box_position: Vector3, box_size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = box_position
	game_world.add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(color)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)

	return body


func _add_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "PlayerCube"
	player.position = Vector3(0, 0.6, 0)
	player.set_script(PLAYER_SCRIPT)
	game_world.add_child(player)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Visual"
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _make_material(Color(0.95, 0.68, 0.22))
	player.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE
	collision.shape = shape
	player.add_child(collision)


func _add_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 5.4, 10)
	camera.current = true
	game_world.add_child(camera)
	camera.look_at(Vector3(0, 0.9, 0), Vector3.UP)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material


func _show_menu() -> void:
	menu_layer.visible = true
	get_tree().paused = true
	menu_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	start_button.grab_focus()


func _hide_menu() -> void:
	menu_layer.visible = false
	get_tree().paused = false


func _on_start_pressed() -> void:
	is_game_running = true
	game_world.visible = true
	_hide_menu()


func _on_exit_pressed() -> void:
	confirm_exit.popup_centered()


func _on_exit_confirmed() -> void:
	get_tree().quit()
