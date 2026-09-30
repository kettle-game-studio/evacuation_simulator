class_name Map
extends Node2D

@onready var ui: MapUI = %UI
@onready var base_layer: TileMapLayerIndexed = %BaseLayer
@onready var gameplay_layer: TileMapLayerIndexed = %GameplayLayer
@onready var fire_layer: FireSimulation = %FireLayer
@onready var walls_layer: TileBoundaryWalls = %WallsLayer
@onready var actors_layer: TileMapLayerIndexed = %ActorsLayer
@export var exit_sound: AudioStream
@export var die_sound: AudioStream

func clear_map() -> void:
	base_layer.clear()
	fire_layer.clear()
	walls_layer.clear()
	actors_layer.clear()

func clear_solution() -> void:
	gameplay_layer.clear()

var saved_actors: Dictionary[Vector2i, bool] = {}
var died_actors: Dictionary[Vector2i, bool] = {}

func add_died_actor(actor: Actor) -> void:
	died_actors[actor.id] = true
	actors_layer.play_audio(actors_layer.local_to_map(actor.position), die_sound)
func add_exited_actor(actor: Actor) -> void:
	saved_actors[actor.id] = true
	actors_layer.play_audio(actors_layer.local_to_map(actor.position), exit_sound)

func start_simulation():
	propagate_call("on_simulation_started", [self])
	walls_layer.generate_physics()
	saved_actors.clear()
	died_actors.clear()
	resume_simulation()

func pause_simulation():
	fire_layer.playing = false
	actors_layer.process_mode = Node.PROCESS_MODE_DISABLED

func resume_simulation():
	fire_layer.playing = true
	actors_layer.process_mode = Node.PROCESS_MODE_INHERIT

func draw_map(map_data: MapData) -> void:
	clear_map()
	for exit in map_data.get_exits():
		base_layer.set_cell_by_name(exit, &"exit")
	for fire in map_data.get_fire():
		fire_layer.set_cell_by_name(fire, &"fire")
	
	var walls := map_data.get_walls()
	walls_layer.wall_vertices = walls.duplicate()
	for actor in map_data.get_actors():
		var pos := actor.position*Vector2(fire_layer.tile_set.tile_size)
		actors_layer.set_cell_by_name(actors_layer.local_to_map(pos), actor.type)

func get_exits() -> Array[Vector2i]:
	return base_layer.get_used_cells().duplicate()
func get_fire() -> Array[Vector2i]:
	return fire_layer.get_used_cells().duplicate()
func get_walls() -> Array[Vector2i]:
	return walls_layer.wall_vertices.duplicate()
func get_actors() -> Array[ActorMapDescription]:
	var actors: Array[ActorMapDescription] = []
	for actor_coords in actors_layer.get_used_cells():
		var pos := actors_layer.map_to_local(actor_coords)/Vector2(fire_layer.tile_set.tile_size)
		var actor := ActorMapDescription.new()
		actor.position = pos
		actor.type = actors_layer.get_cell_name(actor_coords)
		actors.push_back(actor)
	return actors

func get_boundaries() -> Rect2:
	return walls_layer.get_boundaries_global()

func get_visible_data(from: Vector2, radius: float) -> VisibleData:
	var data := VisibleData.new(
		base_layer.tile_set.tile_size, 
		from, 
		base_layer.local_to_map(base_layer.to_local(from))
	)
	for exit in get_visible_tiles(base_layer, from, radius):
		data.exits.push_back(VisibleData.PositionAndDistance.new(exit.map_pos, exit.global_pos, exit.distance))
	for fire in get_visible_tiles(fire_layer, from, radius):
		data.fire.push_back(VisibleData.PositionAndDistance.new(fire.map_pos, fire.global_pos, fire.distance))
	for arrow in get_visible_tiles(gameplay_layer, from, radius):
		data.arrows.push_back(VisibleData.ArrowData.new(
			VisibleData.PositionAndDistance.new(arrow.map_pos, arrow.global_pos, arrow.distance),
			arrow.data.get_custom_data("direction")))
	return data

class TileInfo:
	var map_pos: Vector2i
	var global_pos: Vector2
	var data: TileData
	var distance: float
	
	@warning_ignore("shadowed_variable")
	func _init(mpos: Vector2i, gpos: Vector2, tile_data: TileData, distance: float) -> void:
		self.map_pos = mpos
		self.global_pos = gpos
		self.data = tile_data
		self.distance = distance

func get_visible_tiles(layer: TileMapLayer, from: Vector2, radius: float) -> Array[TileInfo]:
	var tiles: Array[TileInfo] = []
	var radius_in_tiles_x := ceili(radius)
	var radius_in_tiles_y := ceili(radius)
	var center := layer.local_to_map(layer.to_local(from))
	var space_state = get_world_2d().direct_space_state
	for i in range(center.x-radius_in_tiles_x, center.x+radius_in_tiles_x+1):
		for j in range(center.y-radius_in_tiles_y, center.y+radius_in_tiles_y+1):
			var layer_pos := Vector2i(i, j)
			var pos := layer.to_global(layer.map_to_local(layer_pos))
			var distance := center.distance_to(layer_pos)
			if distance > radius:
				continue
			var tile := layer.get_cell_source_id(layer_pos)
			if tile == -1:
				continue
			var data := layer.get_cell_tile_data(layer_pos)
			var query = PhysicsRayQueryParameters2D.create(from, pos, 1)
			var result = space_state.intersect_ray(query)
			if not result.is_empty():
				continue
			tiles.push_back(TileInfo.new(layer_pos, pos, data, distance))
	@warning_ignore("standalone_expression")
	tiles.sort_custom(func(a, b): a.distance < b.distance)
	return tiles

func show_exits(show_layer: bool) -> void:
	base_layer.visible = show_layer
func show_fire(show_layer: bool) -> void:
	fire_layer.visible = show_layer
func show_walls(show_layer: bool) -> void:
	walls_layer.visible = show_layer
func show_actors(show_layer: bool) -> void:
	actors_layer.visible = show_layer
