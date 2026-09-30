class_name FireSimulation
extends TileMapLayerIndexed

@export var walls: TileBoundaryWalls
@export var fire_spawn_audio: AudioStream
@export var speed := 0.5
@export var random_seed: int:
	get():
		return _random.seed
	set(value):
		_random.seed = value

var _random := RandomNumberGenerator.new()

@export var playing := false

func play():
	playing = true

func stop():
	playing = false

func _init() -> void:
	super._init()

func _physics_process(delta: float) -> void:
	if not playing:
		return
	var probability := speed * delta
	for cell in get_used_cells():
		for neighbor in get_surrounding_cells(cell):
			var neighbor_data := get_cell_source_id(neighbor)
			if neighbor_data != -1:
				continue
			if _random.randf() > probability:
				continue
			var is_horizontal_wall := cell.x == neighbor.x
			if is_horizontal_wall:
				var start := Vector2i(cell.x, maxi(cell.y, neighbor.y))
				var end := Vector2i(cell.x+1, maxi(cell.y, neighbor.y))
				if walls.has_wall(start, end):
					continue
			else:
				var start := Vector2i(maxi(cell.x, neighbor.x), cell.y)
				var end := Vector2i(maxi(cell.x, neighbor.x), cell.y+1)
				if walls.has_wall(start, end):
					continue
			spawn_fire(neighbor)
	
func spawn_fire(cell: Vector2i):
	var fire_tile := get_tile_data(&"fire")
	set_cell(cell, fire_tile.source_id, fire_tile.atlas_coordinates, fire_tile.alternative_id)
	play_audio(cell, fire_spawn_audio)
