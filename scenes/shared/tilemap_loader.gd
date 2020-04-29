extends Node2D

export var back_tilemap: NodePath
export var middle_tilemap: NodePath
export var front_tilemap: NodePath

onready var back_tilemap_node = get_node(back_tilemap)
onready var middle_tilemap_node = get_node(middle_tilemap)
onready var front_tilemap_node = get_node(front_tilemap)

var level_data : LevelData
var level_area : LevelArea

var tileset_cache := []

var noise := OpenSimplexNoise.new()

func _ready():
	var level_tilesets := preload("res://assets/tiles/ids.tres")
	for tileset_id in level_tilesets.ids:
		var tileset : LevelTileset = load("res://assets/tiles/" + tileset_id + "/resource.tres")
		tileset_cache.append(tileset)
	
func get_tile(tileset_id, tile_id):
	var tileset = tileset_cache[tileset_id]
	if tile_id == 0:
		return tileset.block_tile_id
	elif tile_id == 1:
		return tileset.slab_tile_id
	elif tile_id == 2:
		return tileset.left_slope_tile_id
	else:
		return tileset.right_slope_tile_id

func place_edges(pos, placing_tile, bounds, tilemap_node):
	if pos.x == 0:
		tilemap_node.set_cell(-1, pos.y, placing_tile)
	if pos.y == 0:
		tilemap_node.set_cell(pos.x, -1, placing_tile)
	if pos.x == 0 and pos.y == 0:
		tilemap_node.set_cell(-1, -1, placing_tile)
	if pos.x == 0 and pos.y == bounds.y - 1:
		tilemap_node.set_cell(-1, bounds.y, placing_tile)
		
	if pos.x == bounds.x - 1:
		tilemap_node.set_cell(bounds.x, pos.y, placing_tile)
	if pos.y == bounds.y - 1:
		tilemap_node.set_cell(pos.x, bounds.y, placing_tile)
	if pos.x == bounds.x - 1 and pos.y == bounds.y - 1:
		tilemap_node.set_cell(bounds.x, bounds.y, placing_tile)
	if pos.x == bounds.x - 1 and pos.y == 0:
		tilemap_node.set_cell(bounds.x, -1, placing_tile)
		
func set_tile(index: int, layer: int, tileset_id: int, tile_id: int):
	var tiles_array
	if layer == 0:
		tiles_array = level_area.background_tiles
	elif layer == 1:
		tiles_array = level_area.foreground_tiles
	elif layer == 2:
		tiles_array = level_area.very_foreground_tiles
		
	if index + 1 >= tiles_array.size():
		for _new_index in range(tiles_array.size(), index + 1):
			tiles_array.append([0, 0])
	var size = level_area.settings.size
	if position.x > size.x or position.y > size.y:
		level_area.settings.size = position
	tiles_array[index] = [tileset_id, tile_id]
	
	set_tile_visual(index, layer, tileset_id, tile_id)
		
func set_tile_visual(index: int, layer: int, tileset_id: int, tile_id: int):
	var position = tile_util.get_position_from_tile_index(index, level_area.settings.size)
	var cache_tile = get_tile(tileset_id, tile_id)
	var layer_tilemap_node = back_tilemap_node
	if layer == 0:
		layer_tilemap_node = back_tilemap_node	
	elif layer == 1:
		layer_tilemap_node = middle_tilemap_node	
	elif layer == 2:
		layer_tilemap_node = front_tilemap_node	
	if layer_tilemap_node.get_cell(position.x, position.y) != cache_tile:
		layer_tilemap_node.set_cell(position.x, position.y, cache_tile)
		place_edges(Vector2(position.x, position.y), cache_tile, level_area.settings.size, layer_tilemap_node)
		layer_tilemap_node.update_bitmask_area(Vector2(position.x, position.y))

func load_in(loaded_level_data : LevelData, loaded_level_area : LevelArea):
	
	level_data = loaded_level_data
	level_area = loaded_level_area
	
	update_tilemaps()
	
	# comments: small brain
	# if false: big brain
	if false:
		noise.seed = randi()
		noise.octaves = 8
		noise.period = 20
		noise.persistence = 0.2
		
		var set = false
		var set2 = false
		for x in range(level_area.settings.size.x):
			for y in range(level_area.settings.size.y):
				
				var tile = 0
				if noise.get_noise_2d(x, y) > 0:
					tile = 2
				set_tile((y * level_area.settings.size.x) + x, 1, tile, 0)
				
				if rand_range(0.01, 1) > 0.75:
					if tile == 2 and noise.get_noise_2d(x, y - 1) <= 0 and noise.get_noise_2d(x, y - 2) <= 0:
						var object = LevelObject.new()
						object.type_id = 4
						object.properties = []
						object.properties.append(Vector2((x * 32) + 16, (y * 32) + 3))
						object.properties.append(Vector2(1, 1))
						object.properties.append(0)
						object.properties.append(true)
						object.properties.append(true)
						get_parent().create_object(object, false)
						
				if rand_range(0.01, 1) > 0.95 and y > 3 and !set:
					if tile == 2 and noise.get_noise_2d(x, y - 1) <= 0 and noise.get_noise_2d(x, y - 2) <= 0:
						set = true
						level_area.objects[0].properties[0] = Vector2((x * 32) + 16, (y * 32) + 3)
				elif rand_range(0.01, 1) > 0.75 and y > 3 and !set2:
					if tile == 2 and noise.get_noise_2d(x, y - 1) <= 0 and noise.get_noise_2d(x, y - 2) <= 0:
						set2 = true
						level_area.objects[1].properties[0] = Vector2((x * 32) + 16, (y * 32) + 3)
						
		noise.seed = randi()
		noise.octaves = 8
		noise.period = 20
		noise.persistence = 0.2
		for x in range(level_area.settings.size.x):
			for y in range(level_area.settings.size.y):
				var tile = 0
				if noise.get_noise_2d(x, y) > 0:
					tile = 2
				set_tile((y * level_area.settings.size.x) + x, 0, tile, 0)

func update_tilemaps():
	var settings = level_area.settings
	
	back_tilemap_node.clear()
	middle_tilemap_node.clear()
	front_tilemap_node.clear()
	
	for index in range(level_area.background_tiles.size()):
		var tile = level_area.background_tiles[index]
		if tile[0] != 0:
			set_tile_visual(index, 0, tile[0], tile[1])
			
	for index in range(level_area.foreground_tiles.size()):
		var tile = level_area.foreground_tiles[index]
		if tile[0] != 0:
			set_tile_visual(index, 1, tile[0], tile[1])
			
	for index in range(level_area.very_foreground_tiles.size()):
		var tile = level_area.very_foreground_tiles[index]
		if tile[0] != 0:
			set_tile_visual(index, 2, tile[0], tile[1])
	
	back_tilemap_node.update_bitmask_region(Vector2(0, 0), Vector2(settings.size.x, settings.size.y))
	middle_tilemap_node.update_bitmask_region(Vector2(0, 0), Vector2(settings.size.x, settings.size.y))
	front_tilemap_node.update_bitmask_region(Vector2(0, 0), Vector2(settings.size.x, settings.size.y))
