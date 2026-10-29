@tool
class_name UiBar
extends NinePatchRect
## Progress bar made of the Aseprite bar frame plus a stretched fill texture.

const FRAME := preload("res://assets/ui/bar_bg.png")

@export var fill: Texture2D:
	set(v):
		fill = v
		if _bar:
			_bar.texture_progress = v
@export var max_value := 100.0:
	set(v):
		max_value = v
		if _bar:
			_bar.max_value = v
@export var value := 100.0:
	set(v):
		value = v
		if _bar:
			_bar.value = v

var _bar: TextureProgressBar


func _ready() -> void:
	texture = FRAME
	patch_margin_left = 2
	patch_margin_right = 2
	patch_margin_top = 2
	patch_margin_bottom = 3
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar = TextureProgressBar.new()
	_bar.nine_patch_stretch = true
	_bar.step = 0.0
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar.offset_left = 1
	_bar.offset_top = 1
	_bar.offset_right = -1
	_bar.offset_bottom = -2
	_bar.texture_progress = fill
	_bar.max_value = max_value
	_bar.value = value
	add_child(_bar, false, Node.INTERNAL_MODE_FRONT)
