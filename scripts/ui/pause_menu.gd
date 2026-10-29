extends CanvasLayer
## Pause screen with the current build.

signal resume_requested

@onready var resume_button: Button = %ResumeButton
@onready var menu_button: Button = %MenuButton
@onready var loadout: HBoxContainer = %Loadout


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(func(): resume_requested.emit())
	menu_button.pressed.connect(Game.go_to_title)


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		resume_requested.emit()
		get_viewport().set_input_as_handled()


func open(player: Player) -> void:
	for child in loadout.get_children():
		child.queue_free()
	for id in DB.WEAPON_ORDER + DB.PASSIVE_ORDER:
		var level := player.upgrade_level(id)
		if level > 0:
			loadout.add_child(preload("res://scripts/ui/hud.gd").make_slot(id, level))
	visible = true
	resume_button.grab_focus()


func close() -> void:
	visible = false
