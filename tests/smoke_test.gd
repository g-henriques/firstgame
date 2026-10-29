extends SceneTree
## Headless smoke test: plays a run with a bot that walks in circles,
## always picks the first upgrade and reports what happened.
##   godot --headless --path . --script res://tests/smoke_test.gd

var world: Node
var frames := 0
var picks := 0


func _initialize() -> void:
	world = load("res://scenes/world.tscn").instantiate()
	root.add_child(world)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		world.level_up_menu.chosen.connect(func(_id): picks += 1)
	if world.game_over.visible:
		print("GAME OVER visible: ", world.game_over.title_label.text, " t=", world.time)
		print("SMOKE OK")
		return true
	if world.level_up_menu.visible and world.level_up_menu.cards.get_child_count() > 0:
		world.level_up_menu._ready_time = 0.0
		var card = world.level_up_menu.cards.get_child(frames % world.level_up_menu.cards.get_child_count())
		world.level_up_menu._on_picked(card.upgrade_id)
	var t := frames / 60.0
	var dir := Vector2(cos(t * 0.7), sin(t * 0.9))
	Input.action_release("move_left"); Input.action_release("move_right")
	Input.action_release("move_up"); Input.action_release("move_down")
	if dir.x < -0.3: Input.action_press("move_left")
	if dir.x > 0.3: Input.action_press("move_right")
	if dir.y < -0.3: Input.action_press("move_up")
	if dir.y > 0.3: Input.action_press("move_down")
	world.player.hp = world.player.max_hp  # keep the bot alive
	if frames % 600 == 0:
		print("t=%5.1fs enemies=%d pickups=%d kills=%d level=%d picks=%d weapons=%s passives=%s fps=%d" % [
			world.time, get_node_count_in_group("enemies"), world.pickups.get_child_count(),
			world.kills, world.player.level, picks, world.player.weapons.keys(), world.player.passives,
			Engine.get_frames_per_second()])
	if frames >= int(OS.get_environment("SMOKE_FRAMES") if OS.get_environment("SMOKE_FRAMES") != "" else "3600"):
		print("SMOKE OK")
		return true
	return false
