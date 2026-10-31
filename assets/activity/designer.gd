class_name Designer
extends Activity

var map_data: MapData = MapData.new()
@onready var editor: TileMapEditor = $Map/Editor
@onready var map: Map = %Map

@onready var new: Button = %New
@onready var open: Button = %Open
@onready var open_map_dialog: FileDialog = $OpenMapDialog

@onready var save: Button = %Save
@onready var save_as: Button = %SaveAs
@onready var save_as_map_dialog: FileDialog = $SaveAsMapDialog

@onready var play: Button = %Play

@onready var import_json: Button = %ImportJSON
@onready var import_json_map_dialog: FileDialog = $ImportJSONMapDialog

@onready var generate_map_button: Button = %GenerateMap
@onready var random_seed_input: LineEdit = %RandomSeed
@onready var map_width_input: LineEdit = %MapWidth
@onready var map_height_input: LineEdit = %MapHeight

var _camera: Camera2D
func _activity_enabled(camera: Camera2D, _options: Dictionary):
	camera.position = map.get_boundaries().get_center()
	_camera = camera
	map.ui.visible = true

func _activity_disabled():
	map.ui.visible = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map.ui.exiting.connect(_emit_exit_request)
	new.pressed.connect(func():	set_map_data(MapData.new()))
	open.pressed.connect(open_map_dialog.popup_file_dialog)
	open_map_dialog.file_selected.connect(_on_open_file_selected)
	
	import_json.pressed.connect(import_json_map_dialog.popup_file_dialog)
	import_json_map_dialog.file_selected.connect(_on_import_json_file_selected)
	
	save.pressed.connect(_on_save)
	save_as.pressed.connect(save_as_map_dialog.popup_file_dialog)
	save_as_map_dialog.file_selected.connect(_on_save_as_file_selected)
	
	play.pressed.connect(
		func(): 
			_update_map()
			activity_manager.enter_activity("Simulation", {&"map_data": map_data})
	)
	
	generate_map_button.pressed.connect(generate_map)
	_update_buttons_state()

func generate_map() -> void:
	generate_walls()
	generate_exits()
	generate_fires()
	spawn_random_actors()

func _on_open_file_selected(path: String) -> void:
	var new_map = load(path)
	if new_map is not MapData:
		return # TODO: show error
	set_map_data(new_map)

func set_map_data(new_map: MapData) -> void:
	map_data = new_map
	map.draw_map(map_data)
	if _camera:
		_camera.position = map.get_boundaries().get_center()
	_update_buttons_state()

func _on_import_json_file_selected(path: String) -> void:
	var json = load(path)
	if json is not JSON:
		return # TODO: show error
	set_map_data(LegacyMap.new(json).to_map_data()) # TODO: process errors

func _on_save_as_file_selected(path: String) -> void:
	map_data.resource_path = path
	_on_save()
	_update_buttons_state()

func _update_map() -> void:
	map_data.actors = map.get_actors()
	map_data.exits = map.get_exits()
	map_data.fire = map.get_fire()
	map_data.walls = map.get_walls()
func _on_save() -> void:
	_update_map()
	map_data.set_path_cache(map_data.resource_path)
	ResourceSaver.save(map_data)

func _update_buttons_state() -> void:
	save.disabled = map_data.resource_path.is_empty()

func generate_exits() -> void:
	editor.undo_redo.create_action("Generate exits")
	var count := 3
	editor.do_clear_layer(map.base_layer)

	var graph := map.build_inner_cell_graph()
	var candidates : Array[MapGraph.VertexData] = graph.vertexes.values().filter(func (v: MapGraph.VertexData): 
			return v.is_border and v.walls != MapGraph.VertexWalls.NONE and v.type == MapGraph.VertexType.EMPTY
	)
	for i in range(min(count, candidates.size())):
		candidates.sort_custom(func (a: MapGraph.VertexData, b: MapGraph.VertexData): return a.closest_exit > b.closest_exit)
		editor.set_cell(map.base_layer, candidates[0].coordinates, &"exit")
		candidates[0].type = MapGraph.VertexType.EXIT
		graph.bake_closest_exit()
		
	editor.undo_clear_layer(map.base_layer)
	editor.undo_redo.commit_action()


func generate_fires() -> void:
	editor.undo_redo.create_action("Generate fires")
	var count := 3
	editor.do_clear_layer(map.fire_layer)

	var graph := map.build_inner_cell_graph()
	var candidates : Array[MapGraph.VertexData] = graph.vertexes.values().filter(func (v: MapGraph.VertexData): 
			return v.walls != MapGraph.VertexWalls.NONE and v.type == MapGraph.VertexType.EMPTY
	)
	for i in range(min(count, candidates.size())):
		candidates.sort_custom(func (a: MapGraph.VertexData, b: MapGraph.VertexData): return a.closest_exit > b.closest_exit or a.closest_fire > b.closest_fire)
		editor.set_cell(map.fire_layer, candidates[0].coordinates, &"fire")
		candidates[0].type = MapGraph.VertexType.FIRE
		graph.bake_closest_fire()
		
	editor.undo_clear_layer(map.fire_layer)
	editor.undo_redo.commit_action()


func generate_walls() -> void:
	editor.undo_redo.create_action("Generate walls")
	editor.do_clear_map()
	
	var width := map_width_input.text.to_int()
	var height := map_height_input.text.to_int()
	
	for b in range(0, height):
		editor.add_wall(map.walls_layer, Vector2i(0, b), Vector2i(0, b+1))
		editor.add_wall(map.walls_layer, Vector2i(width, b), Vector2i(width, b+1))
	for b in range(0, width):
		editor.add_wall(map.walls_layer, Vector2i(b, 0), Vector2i(b+1, 0))
		editor.add_wall(map.walls_layer, Vector2i(b, height), Vector2i(b+1, height))
	
	var rnd_seed := random_seed_input.text.to_int()
	var rnd := RandomNumberGenerator.new()
	rnd.seed = rnd_seed
	_generate_walls(rnd, 0, 0, width, height)
	
	editor.undo_clear_map()
	editor.undo_redo.commit_action()

func _generate_walls(rnd: RandomNumberGenerator, x: int, y: int, width: int, height: int) -> void:
	const min_size = 3
	if rnd.randf() < float(min_size) / (width*height):
		return
	if width > height:
		if width <= 2*min_size:
			return
		var left_width = rnd.randi_range(min_size, width-min_size)
		_generate_walls(rnd, x, y, left_width, height)
		_generate_walls(rnd, x+left_width, y, width-left_width, height)
		var skip = rnd.randi_range(y, y+height-1)
		for b in range(y, y+height):
			if b == skip or ((b != skip-1 and b != skip+1) and rnd.randf() < 0.01):
				continue
			var begin := Vector2i(x+left_width, b)
			var end := Vector2i(x+left_width, b+1)
			editor.add_wall(map.walls_layer, begin, end)
	else:
		if height <= 2*min_size:
			return
		var upper_height = rnd.randi_range(min_size, height-min_size)
		_generate_walls(rnd, x, y, width, upper_height)
		_generate_walls(rnd, x, y+upper_height, width, height-upper_height)
		var skip = rnd.randi_range(x, x+width-1)
		for b in range(x, x+width):
			if b == skip or ((b != skip-1 and b != skip+1) and rnd.randf() < 0.01):
				continue
			var begin := Vector2i(b, y+upper_height)
			var end := Vector2i(b+1, y+upper_height)
			editor.add_wall(map.walls_layer, begin, end)

func spawn_random_actors() -> void:
	var graph := map.build_inner_cell_graph()
	if graph == null:
		return
	var shifts: Array[Vector2i] = [
		Vector2i.ZERO,
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1),
	]
	var total_actors := graph.vertexes.size() * 0.5
	var total_vertexes := graph.vertexes.size()
	editor.undo_redo.create_action("Spawn random actors")
	editor.do_clear_layer(map.actors_layer)
	for room in graph.rooms:
		for try in range(total_actors * room.vertexes.size() /total_vertexes):
			var v: Vector2i = room.vertexes.pick_random()
			var pos := map.base_layer.map_to_local(v)
			var actor_coord: Vector2i = map.actors_layer.local_to_map(pos) + shifts.pick_random()
			var tries := room.vertexes.size() * shifts.size()
			while not _is_good_actor_place(graph, v, actor_coord) and tries > 0:
				v = room.vertexes.pick_random()
				pos = map.base_layer.map_to_local(v)
				actor_coord = map.actors_layer.local_to_map(pos)
				tries -= 1
			if tries > 0:
				editor.set_cell(map.actors_layer, actor_coord, &"actor")
	editor.undo_clear_layer(map.actors_layer)
	editor.undo_redo.commit_action()

func _is_good_actor_place(graph: MapGraph, cell: Vector2i, actor_cell: Vector2i):
	return map.actors_layer.get_cell_name(actor_cell) == &"" and \
		graph.vertexes[cell].closest_fire > 2 and \
		graph.vertexes[cell].closest_exit > 2
