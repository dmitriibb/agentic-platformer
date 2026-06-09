extends Node
class_name HealthComponent

signal health_changed(current_health: float, max_health: float)
signal damaged(amount: float, source: Node)
signal died(source: Node)

@export var max_health := 100.0:
	set(value):
		max_health = maxf(1.0, value)
		current_health = clampf(current_health, 0.0, max_health)
		if is_inside_tree():
			health_changed.emit(current_health, max_health)

@export var starts_full := true
@export var remove_owner_on_death := false

var current_health := 0.0


func _ready() -> void:
	if starts_full and current_health <= 0.0:
		current_health = max_health

	current_health = clampf(current_health, 0.0, max_health)
	health_changed.emit(current_health, max_health)


func configure(new_max_health: float, new_current_health := -1.0) -> void:
	max_health = new_max_health
	starts_full = new_current_health < 0.0
	current_health = max_health if starts_full else clampf(new_current_health, 0.0, max_health)

	if is_inside_tree():
		health_changed.emit(current_health, max_health)


func damage(amount: float, source: Node = null) -> float:
	if amount <= 0.0 or current_health <= 0.0:
		return 0.0

	var previous_health := current_health
	current_health = clampf(current_health - amount, 0.0, max_health)
	var actual_damage := previous_health - current_health

	if actual_damage <= 0.0:
		return 0.0

	damaged.emit(actual_damage, source)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		died.emit(source)
		if remove_owner_on_death:
			var node_to_remove := owner if owner != null else get_parent()
			if node_to_remove != null:
				node_to_remove.queue_free()

	return actual_damage


func heal(amount: float) -> float:
	if amount <= 0.0 or current_health <= 0.0:
		return 0.0

	var previous_health := current_health
	current_health = clampf(current_health + amount, 0.0, max_health)
	var actual_heal := current_health - previous_health

	if actual_heal > 0.0:
		health_changed.emit(current_health, max_health)

	return actual_heal


func is_alive() -> bool:
	return current_health > 0.0
