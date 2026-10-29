extends Node2D
## Title screen: animated arena in the background, logo and main menu.

const WANDERERS := ["bat", "slime", "skeleton", "ghost", "slime", "bat", "skeleton", "ogre"]

@onready var map: ArenaMap = $Map
@onready var camera: Camera2D = $Camera
@onready var critters: Node2D = $Critters
@onready var play_button: Button = %PlayButton
@onready var how_button: Button = %HowButton
@onready var quit_button: Button = %QuitButton
@onready var how_panel: Control = %HowToPlay
@onready var close_how_button: Button = %CloseHowButton
@onready var record_label: Label = %RecordLabel
@onready var hero: AnimatedSprite2D = %Hero
@onready var foe: AnimatedSprite2D = %Foe
@onready var logo: TextureRect = %Logo

var _time := 0.0
var _wanderers := []


func _ready() -> void:
	get_tree().paused = false
	play_button.pressed.connect(Game.start_run)
	how_button.pressed.connect(_show_how.bind(true))
	close_how_button.pressed.connect(_show_how.bind(false))
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not OS.has_feature("web")
	how_panel.visible = false
	if Game.best_time > 0.0:
		record_label.text = "Best time %s   Best level %d   Wins %d" % [
			Game.format_time(Game.best_time), Game.best_level, Game.wins]
	else:
		record_label.text = "Survive for 10 minutes to win!"
	hero.sprite_frames = Assets.sprite_frames("player")
	hero.play("walk")
	foe.sprite_frames = Assets.sprite_frames("skeleton")
	foe.play("move")
	foe.flip_h = true
	_spawn_wanderers()
	var tween := create_tween().set_loops()
	tween.tween_property(logo, "position:y", logo.position.y - 3, 1.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(logo, "position:y", logo.position.y, 1.2).set_trans(Tween.TRANS_SINE)
	play_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	var center := map.map_rect().get_center()
	camera.position = center + Vector2(cos(_time * 0.08) * 220.0, sin(_time * 0.11) * 120.0)
	var area := map.arena_rect().grow(-16)
	for w in _wanderers:
		var sprite: AnimatedSprite2D = w["sprite"]
		sprite.position += w["velocity"] * delta
		if not area.has_point(sprite.position) or randf() < 0.004:
			w["velocity"] = (area.get_center() - sprite.position).normalized().rotated(
				randf_range(-1.2, 1.2)) * w["speed"]
		sprite.flip_h = w["velocity"].x < 0.0


func _unhandled_input(event: InputEvent) -> void:
	if how_panel.visible and event.is_action_pressed("ui_cancel"):
		_show_how(false)


func _spawn_wanderers() -> void:
	var area := map.arena_rect().grow(-60)
	for i in 28:
		var id: String = WANDERERS[i % WANDERERS.size()]
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = Assets.sprite_frames(DB.ENEMIES[id]["sheet"])
		sprite.play("move")
		sprite.position = Vector2(randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y))
		critters.add_child(sprite)
		var speed: float = DB.ENEMIES[id]["speed"] * 0.6
		_wanderers.append({"sprite": sprite, "speed": speed,
			"velocity": Vector2.from_angle(randf() * TAU) * speed})


func _show_how(show: bool) -> void:
	how_panel.visible = show
	if show:
		close_how_button.grab_focus()
	else:
		how_button.grab_focus()
