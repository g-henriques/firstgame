extends Weapon
## Magic Wand: bolts aimed at the nearest enemies.

const SPEED := 230.0


func fire() -> void:
	var count: int = stat("count") + player.amount
	var targets := nearest_enemies(count)
	if targets.is_empty():
		_timer = 0.1  # try again soon
		return
	for i in count:
		var target: Node2D = targets[i % targets.size()]
		var dir := (target.global_position + Vector2(0, -6) - global_position).normalized()
		if i >= targets.size():
			dir = dir.rotated(randf_range(-0.35, 0.35))
		var p: Projectile = PROJECTILE_SCENE.instantiate()
		p.setup("bolt", global_position, dir, SPEED, damage(), stat("pierce"), 2.0)
		p.scale = Vector2.ONE * sqrt(player.area)
		spawn_projectile(p)
