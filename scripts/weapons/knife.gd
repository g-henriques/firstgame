extends Weapon
## Throwing Knife: fast piercing knives thrown where the player faces.

const SPEED := 340.0
const SPACING := 7.0


func fire() -> void:
	var count: int = stat("count") + player.amount
	var dir := player.facing
	var side := dir.orthogonal()
	for i in count:
		var offset := side * (i - (count - 1) / 2.0) * SPACING
		var p: Projectile = PROJECTILE_SCENE.instantiate()
		p.setup("knife", global_position + offset, dir, SPEED, damage(), stat("pierce"), 1.2)
		p.knockback = 30.0
		p.scale = Vector2.ONE * sqrt(player.area)
		spawn_projectile(p)
