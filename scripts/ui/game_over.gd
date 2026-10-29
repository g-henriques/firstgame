extends CanvasLayer
## End of run screen (defeat or victory) with the run statistics.

@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var stats: GridContainer = %Stats
@onready var best_label: Label = %BestLabel
@onready var again_button: Button = %AgainButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	visible = false
	again_button.pressed.connect(Game.start_run)
	menu_button.pressed.connect(Game.go_to_title)


func open(won: bool, time: float, level: int, kills: int, new_best: bool) -> void:
	title_label.text = "VICTORY!" if won else "YOU DIED"
	title_label.add_theme_color_override("font_color", Color("fee761") if won else Color("e43b44"))
	subtitle_label.text = ("You survived the arena!" if won
		else "The arena claims another soul...")
	for child in stats.get_children():
		child.queue_free()
	_add_stat("Time survived", Game.format_time(time))
	_add_stat("Level reached", str(level))
	_add_stat("Enemies slain", str(kills))
	_add_stat("Best time", Game.format_time(Game.best_time))
	best_label.visible = new_best
	visible = true
	again_button.grab_focus()


func _add_stat(label_text: String, value: String) -> void:
	var name_label := Label.new()
	name_label.text = label_text
	name_label.theme_type_variation = "DimLabel"
	stats.add_child(name_label)
	var value_label := Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(value_label)
