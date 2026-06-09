extends SceneTree

const COMBAT_UTILS := preload("res://scripts/combat/combat_utils.gd")
const IMPACT_EXPLOSION_SCRIPT := preload("res://scripts/combat/impact_explosion_3d.gd")
const LEVEL_BUILDER_SCRIPT := preload("res://scripts/level_builder.gd")
const LEVEL_PATH := "res://levels/prototype_room.json"

var _failed := false
var _has_run := false


func _process(_delta: float) -> bool:
	if _has_run:
		return false

	_has_run = true
	_run()
	return false


func _run() -> void:
	var root := Node3D.new()
	root.name = "CombatSmokeRoot"
	get_root().add_child(root)

	var builder = LEVEL_BUILDER_SCRIPT.new()
	builder.build_from_file(LEVEL_PATH, root)

	var level := root.get_node_or_null("PrototypeRoom") as Node3D
	_assert(level != null, "prototype level builds")
	if _failed:
		_finish()
		return

	var player := level.get_node_or_null("Player") as CharacterBody3D
	var melee_enemy := level.get_node_or_null("RedMeleePatroller") as CharacterBody3D
	var ranged_enemy := level.get_node_or_null("RedRangeSentinel") as CharacterBody3D

	_assert(player != null, "player exists")
	_assert(melee_enemy != null, "melee enemy exists")
	_assert(ranged_enemy != null, "ranged enemy exists")

	player.set_physics_process(false)
	melee_enemy.set_physics_process(false)
	ranged_enemy.set_physics_process(false)

	var player_health = COMBAT_UTILS.find_health_component(player)
	var melee_health = COMBAT_UTILS.find_health_component(melee_enemy)
	var ranged_health = COMBAT_UTILS.find_health_component(ranged_enemy)

	_assert(player_health != null, "player health component exists")
	_assert(melee_health != null, "melee enemy health component exists")
	_assert(ranged_health != null, "ranged enemy health component exists")
	_assert(player.get_node_or_null("HealthBar") != null, "player health bar exists")
	_assert(melee_enemy.get_node_or_null("HealthBar") != null, "melee enemy health bar exists")
	var player_sword := player.get_node_or_null("SwordHitbox")
	var enemy_sword := melee_enemy.get_node_or_null("SwordHitbox")
	_assert(player_sword != null, "player sword hitbox exists")
	_assert(enemy_sword != null, "enemy sword hitbox exists")
	_assert(player_sword != null and player_sword.visible, "player sword hitbox stays available while idle")
	_assert(enemy_sword != null and enemy_sword.visible, "enemy sword is visible while idle")
	_assert(_find_descendant_named(player, "HeldSword_Blade") != null, "player sword mesh is anchored in the character rig")
	var player_animation_player := _find_animation_player(player)
	_assert(
		player_animation_player != null and player_animation_player.has_animation(&"Human_Sword_Attack"),
		"player model exposes sword attack animation: %s" % _animation_names(player_animation_player)
	)

	if _failed:
		_finish()
		return

	player.global_position = melee_enemy.global_position + Vector3(-1.0, 0.0, 0.0)
	player.set("_facing_sign", 1.0)
	var melee_health_before = melee_health.current_health
	player.call("_try_melee_attack")
	_assert(float(player.get("_melee_animation_remaining")) > float(player.get("melee_attack_active_time")), "player melee has windup and recovery animation time")
	for frame_index in range(30):
		await physics_frame
	_assert(melee_health.current_health < melee_health_before, "player melee damages enemy health")

	player.global_position = ranged_enemy.global_position + Vector3(-3.0, 0.0, 0.0)
	player.set("_facing_sign", 1.0)
	var player_projectiles_before := _count_children_named(level, "PlayerProjectile")
	player.call("_try_ranged_attack")
	_assert(_count_children_named(level, "PlayerProjectile") > player_projectiles_before, "player ranged attack spawns projectile")
	var player_projectile := _find_child_named(level, "PlayerProjectile")
	_assert(player_projectile != null, "player projectile is available for impact")
	var ranged_health_before_projectile = ranged_health.current_health
	var player_explosions_before := _count_children_with_script(level, IMPACT_EXPLOSION_SCRIPT)
	if player_projectile != null:
		player_projectile.call("_on_body_entered", ranged_enemy)
		_assert(ranged_health.current_health < ranged_health_before_projectile, "player projectile damages enemy health")
		_assert(_count_children_with_script(level, IMPACT_EXPLOSION_SCRIPT) > player_explosions_before, "player projectile impact spawns explosion")

	melee_enemy.global_position = player.global_position + Vector3(1.0, 0.0, 0.0)
	melee_enemy.set("attack_mode", "melee")
	melee_enemy.set("_attack_cooldown_remaining", 0.0)
	melee_enemy.set("_facing_sign", -1.0)
	await physics_frame
	var player_health_before = player_health.current_health
	melee_enemy.call("_try_melee_attack")
	await physics_frame
	_assert(player_health.current_health < player_health_before, "enemy melee damages player health")

	ranged_enemy.global_position = player.global_position + Vector3(3.0, 0.0, 0.0)
	ranged_enemy.set("attack_mode", "ranged")
	ranged_enemy.set("_attack_cooldown_remaining", 0.0)
	var enemy_projectiles_before := _count_children_named(level, "EnemyProjectile")
	ranged_enemy.call("_try_attack", player)
	_assert(_count_children_named(level, "EnemyProjectile") > enemy_projectiles_before, "enemy ranged attack spawns projectile")
	var enemy_projectile := _find_child_named(level, "EnemyProjectile")
	_assert(enemy_projectile != null, "enemy projectile is available for impact")
	var player_health_before_projectile = player_health.current_health
	var enemy_explosions_before := _count_children_with_script(level, IMPACT_EXPLOSION_SCRIPT)
	if enemy_projectile != null:
		enemy_projectile.call("_on_body_entered", player)
		_assert(player_health.current_health < player_health_before_projectile, "enemy projectile damages player health")
		_assert(_count_children_with_script(level, IMPACT_EXPLOSION_SCRIPT) > enemy_explosions_before, "enemy projectile impact spawns explosion")

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		push_error("FAIL: " + message)
		_failed = true


func _count_children_named(node: Node, child_name: String) -> int:
	var count := 0
	for child in node.get_children():
		if String(child.name).begins_with(child_name):
			count += 1
	return count


func _find_child_named(node: Node, child_name: String) -> Node:
	for child in node.get_children():
		if String(child.name).begins_with(child_name):
			return child

	return null


func _find_descendant_named(node: Node, child_name: String) -> Node:
	if String(node.name).begins_with(child_name):
		return node

	for child in node.get_children():
		var found := _find_descendant_named(child, child_name)
		if found != null:
			return found

	return null


func _count_children_with_script(node: Node, script: Script) -> int:
	var count := 0
	for child in node.get_children():
		if child.get_script() == script:
			count += 1
	return count


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer

	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found

	return null


func _animation_names(animation_player: AnimationPlayer) -> String:
	if animation_player == null:
		return "<no AnimationPlayer>"

	var names: Array[String] = []
	for animation_name in animation_player.get_animation_list():
		names.append(str(animation_name))

	return ", ".join(names)


func _finish() -> void:
	if _failed:
		quit(1)
	else:
		print("Combat smoke test passed.")
		quit(0)
