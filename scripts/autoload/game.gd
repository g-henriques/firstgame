extends Node
## Global state: records, scene changes and small helpers.

const SAVE_PATH := "user://save.cfg"
const WIN_TIME := 600.0

const TITLE_SCENE := "res://scenes/title.tscn"
const WORLD_SCENE := "res://scenes/world.tscn"

var best_time := 0.0
var best_kills := 0
var best_level := 1
var wins := 0


func _ready() -> void:
	_load()


func start_run() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(WORLD_SCENE)


func go_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


## Stores the run and returns true when it beat the best time.
func record_run(time: float, kills: int, level: int, won: bool) -> bool:
	var new_best := time > best_time
	best_time = maxf(best_time, time)
	best_kills = maxi(best_kills, kills)
	best_level = maxi(best_level, level)
	if won:
		wins += 1
	_save()
	return new_best


static func format_time(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [s / 60, s % 60]


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best_time = cfg.get_value("records", "best_time", 0.0)
	best_kills = cfg.get_value("records", "best_kills", 0)
	best_level = cfg.get_value("records", "best_level", 1)
	wins = cfg.get_value("records", "wins", 0)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("records", "best_time", best_time)
	cfg.set_value("records", "best_kills", best_kills)
	cfg.set_value("records", "best_level", best_level)
	cfg.set_value("records", "wins", wins)
	cfg.save(SAVE_PATH)
