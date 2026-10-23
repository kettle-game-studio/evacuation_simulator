class_name Map
extends Node2D

@onready var ui: MapUI = %UI
@onready var base_layer: TileMapLayerIndexed = %BaseLayer
@onready var gameplay_layer: TileMapLayerIndexed = %GameplayLayer
@onready var fire_layer: FireSimulation = %FireLayer
@onready var walls_layer: TileBoundaryWalls = %WallsLayer
@onready var actors_layer: ActorsLayer = %ActorsLayer
@onready var editor: TileMapEditor = %Editor

signal actors_count_changed(saved: int, died: int, total: int)

func _ready() -> void:
	actors_layer.actors_changed.connect(_on_actors_changed)


func _debug():
	var graph := build_inner_cell_graph()

	
	#queue_redraw()
	#await draw
	for n in get_tree().get_nodes_in_group(&"debug"):
		n.queue_free()
	#for vertex in graph.vertexes:
		#var data := graph.vertexes[vertex]
		#var label := Label.new()
		#label.add_to_group(&"debug")
		##label.text = "{%d,%d}" % [vertex.x, vertex.y]
		##label.text += "\n{%d}" % [data.edges.size()]
		##label.text += "{%d|%d}" % [data.closest_exit, data.closest_fire]
		#label.text += "{%d}" % [data.room]
		#var pos := base_layer.map_to_local(vertex)
		#label.position = pos - Vector2(base_layer.tile_set.tile_size) / 4
		#label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		#add_child(label)

func clear_map() -> void:
	base_layer.clear()
	fire_layer.clear()
	walls_layer.clear()
	actors_layer.clear()

func clear_solution() -> void:
	gameplay_layer.clear()


func _on_actors_changed(saved: int, died: int, total: int, _state: Actor.FinalState):
	actors_count_changed.emit(saved, died, total)

func start_simulation():
	propagate_call("on_simulation_started", [self])
	walls_layer.generate_physics()
	resume_simulation()

func pause_simulation():
	fire_layer.playing = false
	actors_layer.process_mode = Node.PROCESS_MODE_DISABLED

func resume_simulation():
	fire_layer.playing = true
	actors_layer.process_mode = Node.PROCESS_MODE_INHERIT

func draw_map(map_data: MapData, new_map: bool = true) -> void:
	clear_map()
	if new_map:
		editor.undo_redo.clear_history()
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

				
	
const DIRS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP,
]


func _wall_key(a: Vector2i, b: Vector2i) -> Vector4i:
	# Канонический ключ единичного отрезка, независимо от направления.
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		var tmp := a
		a = b
		b = tmp

	return Vector4i(a.x, a.y, b.x, b.y)


func _boundary_key(cell: Vector2i, direction: Vector2i) -> Vector4i:
	# Отрезок общей границы между cell и cell + direction.
	if direction == Vector2i.RIGHT:
		return _wall_key(
			Vector2i(cell.x + 1, cell.y),
			Vector2i(cell.x + 1, cell.y + 1)
		)
	if direction == Vector2i.LEFT:
		return _wall_key(
			Vector2i(cell.x, cell.y),
			Vector2i(cell.x, cell.y + 1)
		)
	if direction == Vector2i.DOWN:
		return _wall_key(
			Vector2i(cell.x, cell.y + 1),
			Vector2i(cell.x + 1, cell.y + 1)
		)

	# UP
	return _wall_key(
		Vector2i(cell.x, cell.y),
		Vector2i(cell.x + 1, cell.y)
	)


func build_inner_cell_graph() -> MapGraph:
	var wall_vertices := walls_layer.wall_vertices
	if wall_vertices.size() < 2 or wall_vertices.size() % 2 != 0:
		push_error("Некорректный массив wall_vertices.")
		return MapGraph.new()

	var walls: Dictionary = {} # Vector4i -> true
	var min_x := wall_vertices[0].x
	var max_x := wall_vertices[0].x
	var min_y := wall_vertices[0].y
	var max_y := wall_vertices[0].y

	for i in range(0, wall_vertices.size(), 2):
		var start := wall_vertices[i]
		var end := wall_vertices[i + 1]

		if start.x != end.x and start.y != end.y:
			push_error("Стена должна быть горизонтальной или вертикальной.")
			return MapGraph.new()

		min_x = mini(min_x, mini(start.x, end.x))
		max_x = maxi(max_x, maxi(start.x, end.x))
		min_y = mini(min_y, mini(start.y, end.y))
		max_y = maxi(max_y, maxi(start.y, end.y))

		var delta := end - start
		var length := absi(delta.x) + absi(delta.y)
		if length == 0:
			continue

		var step := Vector2i(signi(delta.x), signi(delta.y))
		for part in range(length):
			var a := start + step * part
			var b := a + step
			walls[_wall_key(a, b)] = true

	# Клеточный прямоугольник с внешним слоем вокруг стен.
	var min_cell := Vector2i(min_x - 1, min_y - 1)
	var max_cell := Vector2i(max_x, max_y)

	# Flood fill с внешнего слоя: эти клетки лежат снаружи стен.
	var outside: Dictionary[Vector2i, bool] = {}
	var queue: Array[Vector2i] = []

	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			if x == min_cell.x or x == max_cell.x \
			or y == min_cell.y or y == max_cell.y:
				var cell := Vector2i(x, y)
				if not outside.has(cell):
					outside[cell] = true
					queue.append(cell)

	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1

		for direction in DIRS:
			var neighbor := cell + direction

			if neighbor.x < min_cell.x or neighbor.x > max_cell.x \
			or neighbor.y < min_cell.y or neighbor.y > max_cell.y:
				continue
			if outside.has(neighbor):
				continue

			# Стена на общей границе не даёт flood fill пройти дальше.
			if walls.has(_boundary_key(cell, direction)):
				continue

			outside[neighbor] = true
			queue.append(neighbor)

	# Создаём граф только из не связанных снаружи ячеек.
	var graph := MapGraph.new()

	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell := Vector2i(x, y)
			if not outside.has(cell):
				if base_layer.get_cell_name(cell) == &"exit":
					graph.add_vertex(cell, MapGraph.VertexType.EXIT)
				elif fire_layer.get_cell_name(cell) == &"fire":
					graph.add_vertex(cell, MapGraph.VertexType.FIRE)
				else:
					graph.add_vertex(cell, MapGraph.VertexType.EMPTY)

	# Добавляем связи между внутренними соседями без стены между ними.
	for cell in graph.vertexes.keys():
		for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + direction
			if graph.vertexes.has(neighbor) \
			and not walls.has(_boundary_key(cell, direction)):
				graph.add_edge(cell, neighbor)
	graph.bake()
	return graph
