class_name Pickup
extends Area2D
## Experience gems, hearts and chests. Fly to the player once inside the
## magnet range.

enum Kind { XP, HEAL, CHEST }

const COLLECT_DISTANCE := 8.0

var kind := Kind.XP
var value := 1.0

var _target: Player
var _speed := 0.0

@onready var sprite: Sprite2D = $Sprite


func setup(p_kind: Kind, p_value: float, pos: Vector2) -> Pickup:
	kind = p_kind
	value = p_value
	position = pos
	return self


func _ready() -> void:
	_refresh_texture()
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -2.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


func add_value(extra: float) -> void:
	value += extra
	_refresh_texture()


func attract(player: Player) -> void:
	if _target == null:
		_target = player
		_speed = -60.0  # small hop away before flying in


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	_speed += 500.0 * delta
	var to := _target.global_position + Vector2(0, -6) - global_position
	if to.length() < COLLECT_DISTANCE:
		_collect()
		return
	global_position += to.normalized() * _speed * delta


func _collect() -> void:
	match kind:
		Kind.XP:
			_target.add_xp(value)
		Kind.HEAL:
			_target.heal(value)
		Kind.CHEST:
			_target.leveled_up.emit()
	queue_free()


func _refresh_texture() -> void:
	var tag := "gem_blue"
	match kind:
		Kind.HEAL:
			tag = "heart"
		Kind.CHEST:
			tag = "chest"
		Kind.XP:
			if value >= 25:
				tag = "gem_purple"
			elif value >= 5:
				tag = "gem_red"
			elif value >= 2:
				tag = "gem_green"
	sprite.texture = Assets.tag_texture("pickups", tag)
