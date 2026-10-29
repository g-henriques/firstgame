extends CanvasLayer
## In-game HUD: experience, health, timer, kills, owned upgrades, boss bar.

const SLOT := preload("res://assets/ui/slot.png")

@onready var xp_bar: UiBar = %XpBar
@onready var level_label: Label = %LevelLabel
@onready var hp_bar: UiBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var time_label: Label = %TimeLabel
@onready var kills_label: Label = %KillsLabel
@onready var weapon_slots: HBoxContainer = %WeaponSlots
@onready var passive_slots: HBoxContainer = %PassiveSlots
@onready var announce_label: Label = %Announce
@onready var boss_box: Control = %BossBox
@onready var boss_bar: UiBar = %BossBar
@onready var hp_icon: TextureRect = %HpIcon
@onready var kills_icon: TextureRect = %KillsIcon
@onready var time_icon: TextureRect = %TimeIcon


func _ready() -> void:
	hp_icon.texture = Assets.tag_texture("pickups", "heart")
	kills_icon.texture = Assets.tag_texture("pickups", "skull")
	time_icon.texture = Assets.tag_texture("pickups", "clock")
	announce_label.visible = false
	boss_box.visible = false


func set_hp(hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "%d/%d" % [ceili(hp), roundi(max_hp)]


func set_xp(xp: float, xp_next: float, level: int) -> void:
	xp_bar.max_value = xp_next
	xp_bar.value = xp
	level_label.text = "LV %d" % level


func set_time(t: float) -> void:
	time_label.text = Game.format_time(t)


func set_kills(kills: int) -> void:
	kills_label.text = str(kills)


func set_boss(hp: float, max_hp: float) -> void:
	boss_box.visible = hp > 0.0
	boss_bar.max_value = max_hp
	boss_bar.value = hp


func set_loadout(player: Player) -> void:
	_fill_slots(weapon_slots, DB.WEAPON_ORDER.filter(func(id): return player.weapons.has(id)),
		player)
	_fill_slots(passive_slots, DB.PASSIVE_ORDER.filter(func(id): return player.passives.has(id)),
		player)


func announce(text: String) -> void:
	announce_label.text = text
	announce_label.visible = true
	announce_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(announce_label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): announce_label.visible = false)


func _fill_slots(container: HBoxContainer, ids: Array, player: Player) -> void:
	for child in container.get_children():
		child.queue_free()
	for id in ids:
		container.add_child(make_slot(id, player.upgrade_level(id)))


static func make_slot(id: String, level: int) -> Control:
	var slot := NinePatchRect.new()
	slot.texture = SLOT
	slot.patch_margin_left = 3
	slot.patch_margin_top = 3
	slot.patch_margin_right = 3
	slot.patch_margin_bottom = 3
	slot.custom_minimum_size = Vector2(20, 20)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	var icon_id: String = DB.WEAPONS[id]["icon"] if DB.is_weapon(id) else DB.PASSIVES[id]["icon"]
	icon.texture = Assets.icon(icon_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(2, 2)
	icon.size = Vector2(16, 16)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)
	var label := Label.new()
	label.text = str(level)
	label.position = Vector2(14, 9)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)
	return slot
