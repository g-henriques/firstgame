extends Button
## One option in the level-up menu.

signal picked(id: String)

var upgrade_id := ""

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %Name
@onready var level_label: Label = %Level
@onready var desc_label: Label = %Desc


func setup(id: String, player: Player, index: int) -> void:
	upgrade_id = id
	var next_level := player.upgrade_level(id) + 1
	var title := ""
	var desc := ""
	var icon_id := ""
	if id == "heal":
		title = DB.HEAL_OPTION["name"]
		desc = DB.HEAL_OPTION["desc"]
		icon_id = DB.HEAL_OPTION["icon"]
		level_label.text = ""
	elif DB.is_weapon(id):
		var w: Dictionary = DB.WEAPONS[id]
		title = w["name"]
		desc = w["levels"][next_level - 1]["desc"]
		icon_id = w["icon"]
	else:
		var p: Dictionary = DB.PASSIVES[id]
		title = p["name"]
		desc = p["desc"]
		icon_id = p["icon"]
	if id != "heal":
		level_label.text = "NEW!" if next_level == 1 else "LV %d" % next_level
	name_label.text = "%d. %s" % [index + 1, title]
	desc_label.text = desc
	icon_rect.texture = Assets.icon(icon_id)


func _pressed() -> void:
	picked.emit(upgrade_id)
