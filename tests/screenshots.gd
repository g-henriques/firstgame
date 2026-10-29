extends SceneTree
## Renders screenshots of every screen into the folder given by SHOTS_DIR.
##   xvfb-run godot --path . --script res://tests/screenshots.gd

var out := ""
var step := 0
var frames := 0
var scene: Node


func _initialize() -> void:
	out = OS.get_environment("SHOTS_DIR")
	_load("res://scenes/title.tscn")


func _load(path: String) -> void:
	if scene:
		scene.queue_free()
	scene = load(path).instantiate()
	root.add_child(scene)
	frames = 0


func _shot(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(out + "/" + name + ".png")
	print("saved ", name)


func _process(_delta: float) -> bool:
	frames += 1
	match step:
		0:
			if frames == 90:
				_shot("01_title")
				scene.how_panel.visible = true
			elif frames == 95:
				_shot("02_how_to_play")
				_load("res://scenes/world.tscn")
				step = 1
		1:
			Input.action_press("move_right")
			scene.player.hp = scene.player.max_hp
			if frames == 600:
				Input.action_release("move_right")
				scene.player.apply_upgrade("aura")
				scene.player.apply_upgrade("knife")
				scene.player.apply_upgrade("might")
				scene.player.apply_upgrade("magnet")
				scene.player.take_damage(30)
				scene.time = 299.0
			elif frames == 760:
				_shot("03_gameplay")
				scene._on_player_leveled_up()
			elif frames == 770:
				_shot("04_level_up")
				scene._on_upgrade_chosen(scene.level_up_menu.cards.get_child(0).upgrade_id)
				scene._set_paused(true)
			elif frames == 775:
				_shot("05_pause")
				scene._set_paused(false)
				scene._end_run(false)
			elif frames == 780:
				_shot("06_game_over")
				scene.game_over.open(true, 600.0, 31, 2400, true)
			elif frames == 785:
				_shot("07_victory")
				return true
	return false
