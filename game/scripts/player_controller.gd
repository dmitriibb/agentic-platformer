extends CharacterBody3D

@export var move_speed := 6.0
@export var jump_velocity := 8.0
@export var gravity := 22.0
@export var movement_plane_z := 0.0

var was_jump_pressed := false


func _physics_process(delta: float) -> void:
	var input_x := 0.0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_x -= 1.0

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_x += 1.0

	velocity.x = input_x * move_speed
	velocity.z = 0.0

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

