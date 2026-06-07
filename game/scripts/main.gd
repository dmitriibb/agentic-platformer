extends Node

const LEVEL_BUILDER_SCRIPT := preload("res://scripts/level_builder.gd")
const LEVEL_PATH := "res://levels/prototype_room.json"

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

	var level_builder := LEVEL_BUILDER_SCRIPT.new()
	level_builder.build_from_file(LEVEL_PATH, game_world)


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
