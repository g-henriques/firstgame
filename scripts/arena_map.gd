class_name ArenaMap
extends TileMapLayer
## Builds the arena from the Aseprite tileset: grass, dirt patches, a stone
## plaza in the middle and walls around the edge.

const TILE := 16
const WIDTH := 96
const HEIGHT := 64
const WALL := 2

enum T {
	GRASS, GRASS_B, FLOWERS, TUFT, DARK, DIRT, MIX, STONE,
	STONE_CRACKED, WALL_TOP, WALL_FACE, WALL_TORCH, BUSH, ROCK, BONES, MUSHROOM,
	RUNE, DARK_B,
}

@export var map_seed := 0

var _columns := 8


func _ready() -> void:
	tile_set = _make_tileset()
	generate(map_seed if map_seed != 0 else randi())


func _make_tileset() -> TileSet:
	var tex := Assets.texture("tileset")
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE, TILE)
	_columns = int(tex.get_width() / TILE)
	for y in int(tex.get_height() / TILE):
		for x in _columns:
			source.create_tile(Vector2i(x, y))
	ts.add_source(source, 0)
	return ts


func _put(cell: Vector2i, tile: int) -> void:
	set_cell(cell, 0, Vector2i(tile % _columns, tile / _columns))


func generate(seed_value: int) -> void:
	clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.07
	var detail := FastNoiseLite.new()
	detail.seed = seed_value + 1
	detail.frequency = 0.2
	var center := Vector2(WIDTH / 2.0, HEIGHT / 2.0)
	for y in HEIGHT:
		for x in WIDTH:
			var cell := Vector2i(x, y)
			var n := noise.get_noise_2d(x, y)
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var tile := T.GRASS
			if d < 1.0:
				tile = T.RUNE
			elif d < 6.5:
				tile = T.STONE_CRACKED if rng.randf() < 0.15 else T.STONE
			elif d < 7.5:
				tile = T.MIX
			elif n > 0.38:
				tile = T.DIRT
			elif n > 0.3:
				tile = T.MIX
			elif n < -0.35:
				tile = T.DARK if rng.randf() < 0.6 else T.DARK_B
			else:
				var r := rng.randf()
				if r < 0.012:
					tile = [T.BUSH, T.ROCK, T.BONES, T.MUSHROOM][rng.randi() % 4]
				elif r < 0.05:
					tile = T.FLOWERS
				elif r < 0.09:
					tile = T.TUFT
				elif detail.get_noise_2d(x, y) > 0.1:
					tile = T.GRASS_B
			_put(cell, tile)
	# walls
	for y in HEIGHT:
		for x in WIDTH:
			var cell := Vector2i(x, y)
			var inside_x := x >= WALL and x < WIDTH - WALL
			if y < WALL or y >= HEIGHT - WALL or not inside_x:
				_put(cell, T.WALL_TOP)
			elif y == WALL:
				_put(cell, T.WALL_TORCH if x % 8 == 4 else T.WALL_FACE)


## Walkable area in pixels (inside the walls, below the wall faces).
func arena_rect() -> Rect2:
	return Rect2(WALL * TILE, (WALL + 1) * TILE, (WIDTH - 2 * WALL) * TILE,
		(HEIGHT - 2 * WALL - 1) * TILE)


func map_rect() -> Rect2:
	return Rect2(0, 0, WIDTH * TILE, HEIGHT * TILE)


## Static collision around the walkable area.
func build_walls(parent: Node) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	var inner := arena_rect()
	var outer := map_rect().grow(64)
	var rects := [
		Rect2(outer.position, Vector2(outer.size.x, inner.position.y - outer.position.y)),
		Rect2(Vector2(outer.position.x, inner.end.y), Vector2(outer.size.x, outer.end.y - inner.end.y)),
		Rect2(Vector2(outer.position.x, inner.position.y), Vector2(inner.position.x - outer.position.x, inner.size.y)),
		Rect2(Vector2(inner.end.x, inner.position.y), Vector2(outer.end.x - inner.end.x, inner.size.y)),
	]
	for r in rects:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.get_center()
		body.add_child(cs)
	parent.add_child(body)
	return body
