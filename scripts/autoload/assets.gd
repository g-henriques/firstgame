extends Node
## Loads the sprite sheets exported from Aseprite (png + json-array data with
## frameTags) and turns them into SpriteFrames / AtlasTextures.
## Every animation is an Aseprite tag; frame durations come from the json.

const SPRITES := "res://assets/sprites/"

var _meta := {}
var _frames := {}
var _tag_textures := {}


func meta(sheet: String) -> Dictionary:
	if not _meta.has(sheet):
		var text := FileAccess.get_file_as_string(SPRITES + sheet + ".json")
		var data = JSON.parse_string(text)
		assert(data is Dictionary, "Missing or invalid sprite data: " + sheet)
		_meta[sheet] = data
	return _meta[sheet]


func texture(sheet: String) -> Texture2D:
	return load(SPRITES + sheet + ".png")


func frame_size(sheet: String) -> Vector2:
	var size: Dictionary = meta(sheet)["frames"][0]["sourceSize"]
	return Vector2(size["w"], size["h"])


## The "hitbox" slice drawn in Aseprite, relative to the feet (bottom
## centre of the frame), which is where every character's origin sits.
## Sheets without the slice fall back to a box around the lower middle.
func hitbox(sheet: String) -> Rect2:
	var size := frame_size(sheet)
	var feet := Vector2(size.x / 2.0, size.y)
	for slice in meta(sheet)["meta"].get("slices", []):
		if slice["name"] == "hitbox":
			var b: Dictionary = slice["keys"][0]["bounds"]
			return Rect2(Vector2(b["x"], b["y"]) - feet, Vector2(b["w"], b["h"]))
	var side := size.x * 0.56
	return Rect2(Vector2(-side / 2.0, -size.y * 0.35 - side / 2.0), Vector2(side, side))


func sprite_frames(sheet: String) -> SpriteFrames:
	if _frames.has(sheet):
		return _frames[sheet]
	var data := meta(sheet)
	var frames: Array = data["frames"]
	var tags: Array = data["meta"]["frameTags"]
	if tags.is_empty():
		tags = [{"name": "default", "from": 0, "to": frames.size() - 1}]
	var tex := texture(sheet)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for tag in tags:
		var anim: String = tag["name"]
		sf.add_animation(anim)
		sf.set_animation_loop(anim, true)
		# 1000 "fps" means a relative frame duration of 1.0 lasts 1 ms,
		# so the Aseprite durations (ms) can be used as-is.
		sf.set_animation_speed(anim, 1000.0)
		for i in range(int(tag["from"]), int(tag["to"]) + 1):
			sf.add_frame(anim, _atlas(tex, frames[i]), float(frames[i]["duration"]))
	_frames[sheet] = sf
	return sf


## First frame of an Aseprite tag as a texture (icons, pickups...).
func tag_texture(sheet: String, tag: String) -> Texture2D:
	var key := sheet + ":" + tag
	if _tag_textures.has(key):
		return _tag_textures[key]
	var data := meta(sheet)
	var index := 0
	for t in data["meta"]["frameTags"]:
		if t["name"] == tag:
			index = int(t["from"])
			break
	var tex := _atlas(texture(sheet), data["frames"][index])
	_tag_textures[key] = tex
	return tex


func icon(id: String) -> Texture2D:
	return tag_texture("icons", id)


func _atlas(tex: Texture2D, frame: Dictionary) -> AtlasTexture:
	var r: Dictionary = frame["frame"]
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(r["x"], r["y"], r["w"], r["h"])
	return at
