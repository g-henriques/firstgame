extends Weapon
## Holy Aura: a damaging circle that follows the player.

const KNOCKBACK := 70.0

var _area: Area2D
var _shape: CollisionShape2D
var _sprite: AnimatedSprite2D


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = Assets.sprite_frames("aura")
	_sprite.play("pulse")
	_sprite.z_index = -1
	add_child(_sprite)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 4  # enemies
	_area.monitorable = false
	_shape = CollisionShape2D.new()
	_shape.shape = CircleShape2D.new()
	_area.add_child(_shape)
	add_child(_area)
	# The aura is centred on the player's feet rather than the weapon anchor.
	position = -get_parent().position
	_timer = 0.2
	_update_radius()


func _process(_delta: float) -> void:
	_update_radius()


func fire() -> void:
	for body in _area.get_overlapping_bodies():
		if body is Enemy:
			var push: Vector2 = (body.global_position - global_position).normalized() * KNOCKBACK
			body.take_damage(damage(), push)


func _update_radius() -> void:
	var radius: float = stat("radius") * player.area
	(_shape.shape as CircleShape2D).radius = radius
	var art_radius := Assets.frame_size("aura").x / 2.0 - 1.0
	_sprite.scale = Vector2.ONE * (radius / art_radius)
