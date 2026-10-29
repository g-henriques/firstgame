extends CanvasLayer
## Level-up screen: pick one of three upgrades (mouse, arrows + Enter, or 1-3).

signal chosen(id: String)

const CARD_SCENE := preload("res://scenes/ui/upgrade_card.tscn")
const INPUT_DELAY := 0.35

@onready var cards: VBoxContainer = %Cards
@onready var panel: Control = %Panel

var _ready_time := 0.0


func _ready() -> void:
	visible = false


func open(player: Player, options: Array) -> void:
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	for i in options.size():
		var card = CARD_SCENE.instantiate()
		cards.add_child(card)
		card.setup(options[i], player, i)
		card.picked.connect(_on_picked)
	visible = true
	_ready_time = Time.get_ticks_msec() / 1000.0 + INPUT_DELAY
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size / 2.0
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	await get_tree().process_frame
	if cards.get_child_count() > 0:
		cards.get_child(0).grab_focus()


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed:
		return
	var index: int = event.keycode - KEY_1
	if index >= 0 and index < cards.get_child_count():
		_on_picked(cards.get_child(index).upgrade_id)
		get_viewport().set_input_as_handled()


func _on_picked(id: String) -> void:
	if Time.get_ticks_msec() / 1000.0 < _ready_time or not visible:
		return
	chosen.emit(id)
