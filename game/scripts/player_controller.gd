extends CharacterBody3D

@export var move_speed := 6.0
@export var jump_velocity := 8.0
@export var gravity := 22.0
@export var movement_plane_z := 0.0
@export var visual_path: NodePath = ^"Visual"
@export var idle_animation_name := &"Human_Idle"
@export var walk_animation_name := &"Human_Walk"

var was_jump_pressed := false
var _visual: Node3D
var _animation_player: AnimationPlayer
var _idle_animation: StringName = &""
var _walk_animation: StringName = &""


func _ready() -> void:
	_visual = get_node_or_null(visual_path) as Node3D
	_animation_player = _find_animation_player(_visual)
	_idle_animation = _resolve_animation(idle_animation_name, "idle")
	_walk_animation = _resolve_animation(walk_animation_name, "walk")
	_set_animation_looping(_idle_animation)
	_set_animation_looping(_walk_animation)
	_play_locomotion_animation(false)


func _physics_process(delta: float) -> void:
	var input_x := 0.0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_x -= 1.0

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_x += 1.0

	velocity.x = input_x * move_speed
	velocity.z = 0.0
	_update_facing(input_x)

	if is_on_floor():
		var jump_pressed := Input.is_key_pressed(KEY_SPACE)
		if jump_pressed and not was_jump_pressed:
			velocity.y = jump_velocity
		was_jump_pressed = jump_pressed
	else:
		velocity.y -= gravity * delta
		was_jump_pressed = Input.is_key_pressed(KEY_SPACE)

	move_and_slide()

	global_position.x = clampf(global_position.x, -6.45, 6.45)
	global_position.z = movement_plane_z
	_play_locomotion_animation(absf(input_x) > 0.01 and is_on_floor())


func _update_facing(input_x: float) -> void:
	if _visual == null or absf(input_x) < 0.01:
		return

	_visual.rotation.y = PI / 2.0 if input_x > 0.0 else -PI / 2.0


func _play_locomotion_animation(is_walking: bool) -> void:
	if _animation_player == null:
		return

	if is_walking:
		var speed_scale := clampf(absf(velocity.x) / maxf(move_speed, 0.001), 0.75, 1.35)
		_play_animation(_walk_animation, speed_scale)
	else:
		_play_animation(_idle_animation, 1.0)


func _play_animation(animation_name: StringName, speed_scale: float) -> void:
	if animation_name == &"":
		return

	if StringName(_animation_player.current_animation) != animation_name:
		_animation_player.play(animation_name, 0.12, speed_scale)
	else:
		_animation_player.speed_scale = speed_scale


func _set_animation_looping(animation_name: StringName) -> void:
	if _animation_player == null or animation_name == &"":
		return

	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR


func _resolve_animation(preferred_name: StringName, name_hint: String) -> StringName:
	if _animation_player == null:
		return &""

	if _animation_player.has_animation(preferred_name):
		return preferred_name

	var hint := name_hint.to_lower()
	for animation_name in _animation_player.get_animation_list():
		if String(animation_name).to_lower().contains(hint):
			return StringName(animation_name)

	var animation_names := _animation_player.get_animation_list()
	if animation_names.size() > 0:
		return StringName(animation_names[0])

	return &""


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null

	if root is AnimationPlayer:
		return root as AnimationPlayer

	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found

	return null
