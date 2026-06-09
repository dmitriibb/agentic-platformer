extends CharacterBody3D

const COMBAT_UTILS := preload("res://scripts/combat/combat_utils.gd")
const PROJECTILE_SCRIPT := preload("res://scripts/combat/projectile_attack.gd")
const SWORD_HITBOX_SCRIPT := preload("res://scripts/combat/sword_hitbox.gd")

@export var move_speed := 6.0
@export var jump_velocity := 8.0
@export var gravity := 22.0
@export var max_air_jumps := 1
@export var min_x := -6.45
@export var max_x := 6.45
@export var movement_plane_z := 0.0
@export var visual_path: NodePath = ^"Visual"
@export var idle_animation_name := &"Human_Idle"
@export var walk_animation_name := &"Human_Walk"
@export var melee_attack_animation_name := &"Human_Sword_Attack"
@export var melee_attack_damage := 25.0
@export var melee_attack_range := 1.45
@export var melee_attack_offset := 0.95
@export var melee_attack_cooldown := 0.64
@export var melee_attack_active_time := 0.16
@export var melee_attack_duration := 0.62
@export var melee_attack_damage_delay := 0.32
@export var ranged_attack_damage := 16.0
@export var ranged_attack_cooldown := 0.55
@export var ranged_projectile_speed := 12.0
@export var ranged_projectile_lifetime := 1.7
@export var ranged_projectile_radius := 0.22
@export var attack_height := 1.1

var was_jump_pressed := false
var was_melee_pressed := false
var was_ranged_pressed := false
var air_jumps_remaining := 0
var _visual: Node3D
var _animation_player: AnimationPlayer
var _idle_animation: StringName = &""
var _walk_animation: StringName = &""
var _melee_attack_animation: StringName = &""
var _visual_base_position := Vector3.ZERO
var _facing_sign := 1.0
var _melee_cooldown_remaining := 0.0
var _ranged_cooldown_remaining := 0.0
var _sword_hitbox: Node
var _melee_animation_remaining := 0.0


func _ready() -> void:
	add_to_group(&"player")
	_ensure_sword_hitbox()
	_visual = get_node_or_null(visual_path) as Node3D
	_animation_player = _find_animation_player(_visual)
	if _visual != null:
		_visual_base_position = _visual.position
	_idle_animation = _resolve_animation(idle_animation_name, "idle")
	_walk_animation = _resolve_animation(walk_animation_name, "walk")
	_melee_attack_animation = _resolve_animation(melee_attack_animation_name, "sword_attack", false)
	_set_animation_looping(_idle_animation)
	_set_animation_looping(_walk_animation)
	_set_animation_looping(_melee_attack_animation, Animation.LOOP_NONE)
	_play_locomotion_animation(false)
	_update_sword_facing()


func _physics_process(delta: float) -> void:
	_melee_cooldown_remaining = maxf(_melee_cooldown_remaining - delta, 0.0)
	_ranged_cooldown_remaining = maxf(_ranged_cooldown_remaining - delta, 0.0)
	_melee_animation_remaining = maxf(_melee_animation_remaining - delta, 0.0)
	_update_attacks()

	var input_x := 0.0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_x -= 1.0

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_x += 1.0

	velocity.x = input_x * move_speed
	velocity.z = 0.0
	_update_facing(input_x)

	var jump_pressed := Input.is_key_pressed(KEY_SPACE)
	if is_on_floor():
		air_jumps_remaining = max_air_jumps
	else:
		velocity.y -= gravity * delta

	if jump_pressed and not was_jump_pressed:
		if is_on_floor():
			velocity.y = jump_velocity
		elif air_jumps_remaining > 0:
			velocity.y = jump_velocity
			air_jumps_remaining -= 1

	was_jump_pressed = jump_pressed

	move_and_slide()

	if is_on_floor():
		air_jumps_remaining = max_air_jumps

	global_position.x = clampf(global_position.x, min_x, max_x)
	global_position.z = movement_plane_z
	_update_melee_body_animation()
	_play_locomotion_animation(absf(input_x) > 0.01 and is_on_floor())


func _update_facing(input_x: float) -> void:
	if absf(input_x) < 0.01:
		return

	_facing_sign = 1.0 if input_x > 0.0 else -1.0

	if _visual == null:
		return

	_visual.rotation.y = PI / 2.0 if input_x > 0.0 else -PI / 2.0
	_update_sword_facing()


func _update_attacks() -> void:
	var melee_pressed := Input.is_key_pressed(KEY_1) or Input.is_key_pressed(KEY_KP_1)
	if melee_pressed and not was_melee_pressed:
		_try_melee_attack()
	was_melee_pressed = melee_pressed

	var ranged_pressed := Input.is_key_pressed(KEY_2) or Input.is_key_pressed(KEY_KP_2)
	if ranged_pressed and not was_ranged_pressed:
		_try_ranged_attack()
	was_ranged_pressed = ranged_pressed


func _try_melee_attack() -> void:
	if _melee_cooldown_remaining > 0.0:
		return

	_ensure_sword_hitbox()
	_update_sword_facing()
	_sword_hitbox.activate(
		self,
		_facing_sign,
		melee_attack_damage,
		&"enemies",
		melee_attack_active_time,
		attack_height,
		melee_attack_offset,
		melee_attack_range - melee_attack_offset,
		melee_attack_duration,
		melee_attack_damage_delay
	)
	_melee_cooldown_remaining = melee_attack_cooldown
	_melee_animation_remaining = melee_attack_duration
	_play_melee_attack_animation()


func _try_ranged_attack() -> void:
	if _ranged_cooldown_remaining > 0.0:
		return

	var projectile = PROJECTILE_SCRIPT.new()
	projectile.name = "PlayerProjectile"
	projectile.setup(
		ranged_attack_damage,
		ranged_projectile_speed,
		ranged_projectile_lifetime,
		ranged_projectile_radius,
		&"enemies",
		Vector3(_facing_sign, 0.0, 0.0),
		self
	)
	projectile.movement_plane_z = movement_plane_z

	var projectile_parent := get_parent()
	if projectile_parent == null:
		projectile_parent = get_tree().current_scene

	projectile_parent.add_child(projectile)
	projectile.global_position = global_position + Vector3(_facing_sign * 0.85, attack_height, 0.0)
	_ranged_cooldown_remaining = ranged_attack_cooldown


func _ensure_sword_hitbox() -> void:
	if _sword_hitbox != null and is_instance_valid(_sword_hitbox):
		return

	_sword_hitbox = get_node_or_null("SwordHitbox")
	if _sword_hitbox != null:
		_sword_hitbox.set_visual_enabled(false)
		return

	_sword_hitbox = SWORD_HITBOX_SCRIPT.new()
	_sword_hitbox.name = "SwordHitbox"
	add_child(_sword_hitbox)
	_sword_hitbox.set_visual_enabled(false)
	_update_sword_facing()


func _update_sword_facing() -> void:
	if _sword_hitbox == null or not is_instance_valid(_sword_hitbox):
		return

	_sword_hitbox.set_facing(_facing_sign)


func _update_melee_body_animation() -> void:
	if _visual == null:
		return

	if _melee_animation_remaining <= 0.0:
		_visual.rotation.z = lerpf(_visual.rotation.z, 0.0, 0.35)
		_visual.position = _visual.position.lerp(_visual_base_position, 0.35)
		return

	var progress := 1.0 - clampf(_melee_animation_remaining / maxf(melee_attack_duration, 0.001), 0.0, 1.0)
	var lunge := 0.0

	if progress < 0.22:
		var windup := _ease_sine(progress / 0.22)
		lunge = lerpf(0.0, -0.03, windup)
	elif progress < 0.48:
		var lift := _ease_sine((progress - 0.22) / 0.26)
		lunge = lerpf(-0.03, 0.02, lift)
	elif progress < 0.72:
		var slash := _ease_sine((progress - 0.48) / 0.24)
		lunge = lerpf(0.02, 0.10, slash)
	else:
		var recover := _ease_sine((progress - 0.72) / 0.28)
		lunge = lerpf(0.10, 0.0, recover)

	_visual.rotation.z = 0.0
	_visual.position = _visual_base_position + Vector3(_facing_sign * lunge, 0.0, 0.0)


func _play_melee_attack_animation() -> void:
	if _animation_player == null or _melee_attack_animation == &"":
		return

	var animation := _animation_player.get_animation(_melee_attack_animation)
	var speed_scale := 1.0
	if animation != null:
		speed_scale = animation.length / maxf(melee_attack_duration, 0.001)

	_animation_player.play(_melee_attack_animation, 0.04, speed_scale)


func _play_locomotion_animation(is_walking: bool) -> void:
	if _animation_player == null:
		return

	if _melee_animation_remaining > 0.0 and _melee_attack_animation != &"":
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


func _set_animation_looping(animation_name: StringName, loop_mode := Animation.LOOP_LINEAR) -> void:
	if _animation_player == null or animation_name == &"":
		return

	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = loop_mode


func _ease_sine(value: float) -> float:
	return sin(clampf(value, 0.0, 1.0) * PI * 0.5)


func _resolve_animation(preferred_name: StringName, name_hint: String, fallback_to_first := true) -> StringName:
	if _animation_player == null:
		return &""

	if _animation_player.has_animation(preferred_name):
		return preferred_name

	var hint := name_hint.to_lower()
	for animation_name in _animation_player.get_animation_list():
		if String(animation_name).to_lower().contains(hint):
			return StringName(animation_name)

	if fallback_to_first:
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
