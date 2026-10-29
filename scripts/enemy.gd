class_name Enemy
extends CharacterBody2D
## Generic enemy configured from DB.ENEMIES. Walks towards the player.

signal killed(enemy: Enemy)

const RECYCLE_DISTANCE := 620.0

var type_id := "bat"
var hp := 10.0
var max_hp := 10.0
var speed := 40.0
var damage := 5.0
var xp := 1
var is_boss := false
var target: Player
var world: Node

var _hp_mult := 1.0
var _knockback := Vector2.ZERO
var _flash := 0.0
var _dead := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shadow: Sprite2D = $Shadow
@onready var shape: CollisionShape2D = $Shape


## Call before adding to the tree.
func setup(id: String, hp_mult: float, boss := false) -> void:
	type_id = id
	_hp_mult = hp_mult
	is_boss = boss


func _ready() -> void:
	var data: Dictionary = DB.ENEMIES[type_id]
	max_hp = data["hp"] * _hp_mult
	speed = data["speed"] * randf_range(0.9, 1.1)
	damage = data["damage"]
	xp = data["xp"]
	var scale_factor := 1.0
	if is_boss:
		max_hp *= 25.0
		damage *= 1.5
		xp *= 10
		scale_factor = 1.8
	hp = max_hp
	sprite.sprite_frames = Assets.sprite_frames(data["sheet"])
	sprite.play("move")
	sprite.frame = randi() % sprite.sprite_frames.get_frame_count("move")
	var size := Assets.frame_size(data["sheet"]) * scale_factor
	sprite.scale = Vector2.ONE * scale_factor
	sprite.position = Vector2(0, -size.y / 2.0)
	shadow.texture = Assets.texture("shadow")
	shadow.scale = Vector2.ONE * (size.x / 16.0)
	var box := Assets.hitbox(data["sheet"])
	var circle := CircleShape2D.new()
	circle.radius = maxf(3.0, minf(box.size.x, box.size.y) / 2.0 * scale_factor)
	shape.shape = circle
	shape.position = Vector2(0, box.get_center().y * scale_factor)
	if data.get("ghost", false):
		collision_mask = 1  # floats through other enemies
		sprite.self_modulate.a = 0.8
	if is_boss:
		sprite.self_modulate = Color(1.0, 0.75, 0.9)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if is_instance_valid(target) and not target.dead:
		var to_player := target.global_position - global_position
		if to_player.length() > RECYCLE_DISTANCE and not is_boss and world:
			world.relocate_enemy(self)
			return
		var dir := to_player.normalized()
		velocity = dir * speed + _knockback
		if absf(dir.x) > 0.2:
			sprite.flip_h = dir.x < 0.0
	else:
		velocity = _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()

	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			sprite.modulate = Color.WHITE


func take_damage(amount: float, push := Vector2.ZERO) -> void:
	if _dead:
		return
	hp -= amount
	_flash = 0.08
	sprite.modulate = Color(12, 12, 12)
	_knockback += push * (0.15 if is_boss else 1.0)
	if world:
		world.spawn_damage_number(global_position + Vector2(0, sprite.position.y * 2.0), amount)
	if hp <= 0.0:
		_die()


func _die() -> void:
	_dead = true
	killed.emit(self)
	queue_free()
