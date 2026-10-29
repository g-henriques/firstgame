class_name Projectile
extends Area2D
## A moving hitbox fired by a weapon. Damages enemies it touches.

var sheet := "bolt"
var direction := Vector2.RIGHT
var speed := 250.0
var damage := 10.0
var pierce := 1
var lifetime := 2.0
var knockback := 50.0
var spin := false

var _hit := {}

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shape: CollisionShape2D = $Shape


func setup(p_sheet: String, pos: Vector2, dir: Vector2, p_speed: float, p_damage: float,
		p_pierce: int, p_lifetime: float, p_spin := false) -> Projectile:
	sheet = p_sheet
	position = pos
	direction = dir.normalized()
	speed = p_speed
	damage = p_damage
	pierce = p_pierce
	lifetime = p_lifetime
	spin = p_spin
	return self


func _ready() -> void:
	sprite.sprite_frames = Assets.sprite_frames(sheet)
	sprite.play(sprite.sprite_frames.get_animation_names()[0])
	var size := Assets.frame_size(sheet)
	var circle := CircleShape2D.new()
	circle.radius = minf(size.x, size.y) * 0.4
	shape.shape = circle
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if spin:
		sprite.rotation += delta * 18.0
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if pierce <= 0 or not body is Enemy:
		return
	var key := body.get_instance_id()
	if _hit.has(key):
		return
	_hit[key] = true
	body.take_damage(damage, direction * knockback)
	pierce -= 1
	if pierce <= 0:
		queue_free()
