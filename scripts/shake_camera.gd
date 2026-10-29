class_name ShakeCamera
extends Camera2D
## Camera with a small screen shake.

var _strength := 0.0


func shake(amount: float) -> void:
	_strength = maxf(_strength, amount)


func _process(delta: float) -> void:
	if _strength <= 0.0:
		offset = Vector2.ZERO
		return
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _strength
	_strength = move_toward(_strength, 0.0, 20.0 * delta)
