extends Node2D
## A run: spawns enemies over time, handles drops, level-ups, pause and the
## end of the game (death or surviving Game.WIN_TIME).

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const PICKUP_SCENE := preload("res://scenes/pickup.tscn")
const POOF_SHEET := "poof"

const MAX_ENEMIES := 300
const MAX_PICKUPS := 350
const MAX_DAMAGE_NUMBERS := 60
const SPAWN_DISTANCE := Vector2(360, 420)
const BOSS_TIMES := [300.0, 480.0]
const HORDE_INTERVAL := 60.0

var time := 0.0
var kills := 0
var running := true
var pending_level_ups := 0

var _spawn_budget := 0.0
var _next_horde := HORDE_INTERVAL
var _bosses_spawned := 0
var _damage_numbers := 0
var _boss: Enemy

@onready var map: ArenaMap = $Map
@onready var pickups: Node2D = $Pickups
@onready var entities: Node2D = $Entities
@onready var projectiles: Node2D = $Projectiles
@onready var fx: Node2D = $Fx
@onready var player: Player = $Entities/Player
@onready var hud = $HUD
@onready var level_up_menu = $LevelUp
@onready var pause_menu = $PauseMenu
@onready var game_over = $GameOver


func _ready() -> void:
	projectiles.add_to_group("projectile_layer")
	map.build_walls(self)
	var area := map.arena_rect()
	player.position = area.get_center() + Vector2(0, 40)
	var limits := map.map_rect()
	player.camera.limit_left = int(limits.position.x)
	player.camera.limit_top = int(limits.position.y)
	player.camera.limit_right = int(limits.end.x)
	player.camera.limit_bottom = int(limits.end.y)
	player.camera.reset_smoothing()

	player.hp_changed.connect(hud.set_hp)
	player.xp_changed.connect(hud.set_xp)
	player.loadout_changed.connect(func(): hud.set_loadout(player))
	player.leveled_up.connect(_on_player_leveled_up)
	player.died.connect(_on_player_died)
	level_up_menu.chosen.connect(_on_upgrade_chosen)
	pause_menu.resume_requested.connect(_set_paused.bind(false))
	hud.set_hp(player.hp, player.max_hp)
	hud.set_xp(player.xp, player.xp_next, player.level)
	hud.set_loadout(player)
	hud.set_kills(0)
	# A few enemies right away so the arena never starts empty.
	for i in 6:
		spawn_enemy("bat" if i % 2 else "slime")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and running and not level_up_menu.visible:
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not running:
		return
	time += delta
	hud.set_time(time)
	if time >= Game.WIN_TIME:
		_end_run(true)
		return
	_spawn_budget += delta * _spawn_rate()
	while _spawn_budget >= 1.0:
		_spawn_budget -= 1.0
		if get_tree().get_node_count_in_group("enemies") < MAX_ENEMIES:
			spawn_enemy(_pick_enemy_type())
	if time >= _next_horde:
		_next_horde += HORDE_INTERVAL
		_spawn_horde()
	if _bosses_spawned < BOSS_TIMES.size() and time >= BOSS_TIMES[_bosses_spawned]:
		_bosses_spawned += 1
		_spawn_boss()
	if is_instance_valid(_boss):
		hud.set_boss(_boss.hp, _boss.max_hp)


# --- spawning ---------------------------------------------------------------

func _spawn_rate() -> float:
	# enemies per second: ~1.3 at the start, ~12 at minute 10
	var minutes := time / 60.0
	return 1.3 + minutes * 0.9 + minutes * minutes * 0.02


func _hp_multiplier() -> float:
	return 1.0 + time / 60.0 * 0.25


func _pick_enemy_type() -> String:
	var total := 0.0
	var options := []
	for id in DB.ENEMIES:
		var data: Dictionary = DB.ENEMIES[id]
		if time >= data["from"]:
			var weight: float = data["weight"]
			if id == "bat" and time > 180.0:
				weight *= 0.6
			options.append([id, weight])
			total += weight
	var roll := randf() * total
	for o in options:
		roll -= o[1]
		if roll <= 0.0:
			return o[0]
	return options[-1][0]


func spawn_enemy(id: String, pos = null, boss := false) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(id, _hp_multiplier(), boss)
	enemy.position = pos if pos != null else _spawn_position()
	enemy.target = player
	enemy.world = self
	enemy.killed.connect(_on_enemy_killed)
	entities.add_child(enemy)
	return enemy


func relocate_enemy(enemy: Enemy) -> void:
	enemy.position = _spawn_position()


func _spawn_position() -> Vector2:
	var area := map.arena_rect().grow(-12)
	var best := area.get_center()
	for attempt in 10:
		var angle := randf() * TAU
		var distance := randf_range(SPAWN_DISTANCE.x, SPAWN_DISTANCE.y)
		var pos := player.global_position + Vector2.from_angle(angle) * distance
		pos = pos.clamp(area.position, area.end)
		best = pos
		if pos.distance_to(player.global_position) > 230.0:
			return pos
	return best


func _spawn_horde() -> void:
	var id := "bat" if time < 240.0 else ("skeleton" if time < 420.0 else "ghost")
	var count := 14 + int(time / 60.0) * 2
	var area := map.arena_rect().grow(-12)
	for i in count:
		var pos := player.global_position + Vector2.from_angle(TAU * i / count) * 300.0
		spawn_enemy(id, pos.clamp(area.position, area.end))
	hud.announce("A horde approaches!")


func _spawn_boss() -> void:
	_boss = spawn_enemy("ogre", null, true)
	hud.announce("The Ogre King has arrived!")
	hud.set_boss(_boss.hp, _boss.max_hp)


# --- events -----------------------------------------------------------------

func _on_enemy_killed(enemy: Enemy) -> void:
	# Called from physics callbacks: spawn things deferred.
	_handle_kill.call_deferred(enemy == _boss, enemy.global_position, enemy.sprite.position.y, enemy.xp)


func _handle_kill(was_boss: bool, pos: Vector2, sprite_y: float, xp: int) -> void:
	kills += 1
	hud.set_kills(kills)
	spawn_poof(pos + Vector2(0, sprite_y))
	if was_boss:
		_boss = null
		hud.set_boss(0, 1)
		_drop(Pickup.Kind.CHEST, 1, pos)
		_drop(Pickup.Kind.XP, xp, pos + Vector2(12, 0))
		return
	if randf() < 0.012:
		_drop(Pickup.Kind.HEAL, 25, pos)
	else:
		_drop(Pickup.Kind.XP, xp, pos)


func _drop(kind: Pickup.Kind, value: float, pos: Vector2) -> void:
	if kind == Pickup.Kind.XP and pickups.get_child_count() >= MAX_PICKUPS:
		# too many gems on the floor: merge into a random one
		var other: Pickup = pickups.get_child(randi() % pickups.get_child_count())
		if other.kind == Pickup.Kind.XP:
			other.add_value(value)
			return
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickups.add_child(pickup.setup(kind, value, pos))


func spawn_poof(pos: Vector2) -> void:
	var poof := AnimatedSprite2D.new()
	poof.sprite_frames = Assets.sprite_frames(POOF_SHEET)
	poof.position = pos
	fx.add_child(poof)
	poof.play("burst")
	poof.animation_looped.connect(poof.queue_free)


func spawn_damage_number(pos: Vector2, amount: float) -> void:
	if _damage_numbers >= MAX_DAMAGE_NUMBERS:
		return
	_damage_numbers += 1
	var label := Label.new()
	label.text = str(roundi(amount))
	label.add_theme_color_override("font_color", Color("fee761") if amount >= 15 else Color.WHITE)
	label.position = pos + Vector2(randf_range(-6, 2), -6)
	label.z_index = 10
	fx.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 12, 0.45).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.3)
	tween.finished.connect(func():
		_damage_numbers -= 1
		label.queue_free())


func _on_player_leveled_up() -> void:
	pending_level_ups += 1
	if not level_up_menu.visible and running:
		_show_level_up()


func _show_level_up() -> void:
	get_tree().paused = true
	level_up_menu.open(player, _roll_options(3))


func _on_upgrade_chosen(id: String) -> void:
	player.apply_upgrade(id)
	pending_level_ups -= 1
	if pending_level_ups > 0:
		_show_level_up()
	else:
		level_up_menu.close()
		get_tree().paused = false


func _roll_options(count: int) -> Array:
	var pool := []
	for id in DB.WEAPON_ORDER:
		if player.can_upgrade(id):
			pool.append(id)
	for id in DB.PASSIVE_ORDER:
		if player.can_upgrade(id):
			pool.append(id)
	pool.shuffle()
	var options := pool.slice(0, count)
	if options.is_empty():
		options = ["heal"]
	return options


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if paused:
		pause_menu.open(player)
	else:
		pause_menu.close()


func _on_player_died() -> void:
	running = false
	await get_tree().create_timer(1.0).timeout
	_end_run(false)


func _end_run(won: bool) -> void:
	running = false
	var new_best := Game.record_run(time, kills, player.level, won)
	get_tree().paused = true
	game_over.open(won, time, player.level, kills, new_best)
