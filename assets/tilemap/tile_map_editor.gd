class_name TileMapEditor
extends Node2D

@export var tile_map_layers: Array[TileMapLayerIndexed]
@export var walls_layers: Array[TileBoundaryWalls]
@export var grid_overlay: TileGridOverlay
@export var preview_layer: TileEditorOverlay
@export var tile_palette: TilePalette
@export var walls_overlay: TileWallOverlay
@export var map: Map

var undo_redo = UndoRedo.new()

func _ready() -> void:
	_build_palette()
	tile_palette.selection_cleared.connect(func():
		preview_layer.visible = false
		grid_overlay.tile_map_layer = null
		walls_overlay.visible = false
	)
	tile_palette.tile_selected.connect(func(tile_map_layer: TileMapLayerIndexed, tile_name: StringName):
		preview_layer.tile = tile_name
		preview_layer.target_layer = tile_map_layer
		preview_layer.visible = true
		grid_overlay.tile_map_layer = tile_map_layer
		walls_overlay.visible = false
	)
	tile_palette.wall_selected.connect(func(wall_layer: TileBoundaryWalls):
		preview_layer.visible = false
		
		grid_overlay.tile_map_layer = wall_layer.tile_map_layer
		walls_overlay.on_draw_at_point = tile_palette.selection.draw_preview
		walls_overlay.visible = true
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_paint_at_mouse()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_erase_at_mouse()

	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_paint_at_mouse()

		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_erase_at_mouse()
	elif event.is_action_pressed("ui_undo"):
		undo_redo.undo()
	elif event.is_action_pressed("ui_redo"):
		undo_redo.redo()

func _build_palette() -> void:
	for tile_map_layer in tile_map_layers:
		for tile_name in tile_map_layer.tiles_index:
			tile_palette.add_tile(tile_map_layer, tile_name, tile_map_layer.tiles_index[tile_name])
	for wall_layer in walls_layers:
		tile_palette.add_wall(wall_layer)
		tile_palette.add_wall_rect(wall_layer)


func _paint_at_mouse() -> void:
	var selection := tile_palette.selection
	if selection == null:
		return
	selection.paint_at(undo_redo, get_global_mouse_position())

func _erase_at_mouse() -> void:
	var selection := tile_palette.selection
	if selection == null:
		return
	selection.erase_at(undo_redo, get_global_mouse_position())


@warning_ignore("shadowed_variable_base_class")
func show_editor(visible: bool) -> void:
	if visible:
		tile_palette.visible = true
	else:
		tile_palette.clear_selection()
		tile_palette.visible = false

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
	undo_redo.create_action("Spawn random actors")
	for cell in map.actors_layer.get_used_cells():
		undo_redo.add_do_method(map.actors_layer.set_cell_by_name.bind(cell, &""))
		undo_redo.add_undo_method(map.actors_layer.set_cell_by_name.bind(cell, map.actors_layer.get_cell_name(cell)))
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
				undo_redo.add_do_method(map.actors_layer.set_cell_by_name.bind(actor_coord, &"actor"))
				undo_redo.add_undo_method(map.actors_layer.set_cell_by_name.bind(actor_coord, &""))
	undo_redo.commit_action()

func _is_good_actor_place(graph: MapGraph, cell: Vector2i, actor_cell: Vector2i):
	return map.actors_layer.get_cell_name(actor_cell) == &"" and \
		graph.vertexes[cell].closest_fire > 2 and \
		graph.vertexes[cell].closest_exit > 2
