class_name Weapon
extends Node2D
## Base class for automatic weapons. Fires every `cooldown()` seconds.

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

var id := ""
var level := 1
var player: Player

var _timer := 0.5


func stat(key: String):
	return DB.WEAPONS[id]["levels"][level - 1][key]


func damage() -> float:
	return stat("damage") * player.might


func cooldown() -> float:
	return stat("cooldown") * player.cooldown


func level_up() -> void:
	level = mini(level + 1, DB.MAX_WEAPON_LEVEL)
	_on_level_changed()


func _physics_process(delta: float) -> void:
	if player == null or player.dead:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = cooldown()
		fire()


func fire() -> void:
	pass


func _on_level_changed() -> void:
	pass


func spawn_projectile(projectile: Projectile) -> void:
	var layer := get_tree().get_first_node_in_group("projectile_layer")
	if layer:
		layer.add_child(projectile)


func nearest_enemies(count: int, max_range := 400.0) -> Array:
	var origin := global_position
	var found := []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d := origin.distance_squared_to(enemy.global_position)
		if d <= max_range * max_range:
			found.append([d, enemy])
	found.sort_custom(func(a, b): return a[0] < b[0])
	var result := []
	for i in mini(count, found.size()):
		result.append(found[i][1])
	return result
