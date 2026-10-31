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


func do_clear_layer(layer: TileMapLayerIndexed) -> void:
	for cell in layer.get_used_cells():
		undo_redo.add_do_method(layer.set_cell_by_name.bind(cell, &""))


func undo_clear_layer(layer: TileMapLayerIndexed) -> void:
	for cell in layer.get_used_cells():
		var cell_name := layer.get_cell_name(cell)
		undo_redo.add_undo_method(layer.set_cell_by_name.bind(cell, cell_name))


func do_clear_map() -> void:
	for layer in tile_map_layers:
		do_clear_layer(layer)
	for layer in walls_layers:
		for i in range(0, layer.wall_vertices.size(), 2):
			var s := layer.wall_vertices[i]
			var e := layer.wall_vertices[i+1]
			undo_redo.add_do_method(layer.remove_wall.bind(s, e))


func undo_clear_map() -> void:
	for layer in tile_map_layers:
		undo_clear_layer(layer)
	for layer in walls_layers:
		for i in range(0, layer.wall_vertices.size(), 2):
			var s := layer.wall_vertices[i]
			var e := layer.wall_vertices[i+1]
			undo_redo.add_undo_method(layer.add_wall.bind(s, e))


func set_cell(layer: TileMapLayerIndexed, cell: Vector2i, cell_name: StringName):
	var old_name := layer.get_cell_name(cell)
	undo_redo.add_do_method(layer.set_cell_by_name.bind(cell, cell_name))
	undo_redo.add_undo_method(layer.set_cell_by_name.bind(cell, old_name))

	
func add_wall(layer: TileBoundaryWalls, b: Vector2i, e: Vector2i) -> void:
	undo_redo.add_do_method(layer.add_wall.bind(b, e))
	undo_redo.add_undo_method(layer.remove_wall.bind(b, e))
