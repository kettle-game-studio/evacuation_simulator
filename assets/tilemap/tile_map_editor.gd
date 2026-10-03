class_name TileMapEditor
extends Node2D

@export var tile_map_layers: Array[TileMapLayerIndexed]
@export var walls_layers: Array[TileBoundaryWalls]
@export var grid_overlay: TileGridOverlay
@export var preview_layer: TileEditorOverlay
@export var tile_palette: TilePalette
@export var walls_overlay: TileWallOverlay

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
		walls_overlay.walls_layer = wall_layer
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


func _paint_at_mouse() -> void:
	var selection := tile_palette.selection
	if selection is TilePalette.TilePaletteTileLayerSelection:
		var cell := _get_mouse_cell()
		var layer := (selection as TilePalette.TilePaletteTileLayerSelection).layer
		var current_cell := layer.get_cell_name(cell)
		if current_cell == selection.name:
			return
		undo_redo.create_action("Set cell")
		undo_redo.add_do_method(layer.set_cell_by_name.bind(cell, selection.name))
		undo_redo.add_undo_method(layer.set_cell_by_name.bind(cell, current_cell))
		undo_redo.commit_action()
	elif selection is TilePalette.TilePaletteWallLayerSelection:
		var layer := (selection as TilePalette.TilePaletteWallLayerSelection).layer
		var wall := layer.local_to_grid_line(layer.get_local_mouse_position())
		if wall.is_empty():
			return
		if layer.has_wall(wall[0], wall[1]):
			return
		undo_redo.create_action("Set wall")
		undo_redo.add_do_method(layer.add_wall.bind(wall[0], wall[1]))
		undo_redo.add_undo_method(layer.remove_wall.bind(wall[0], wall[1]))
		undo_redo.commit_action()


func _erase_at_mouse() -> void:
	var selection := tile_palette.selection
	if selection is TilePalette.TilePaletteTileLayerSelection:
		var cell := _get_mouse_cell()
		var layer := (selection as TilePalette.TilePaletteTileLayerSelection).layer
		var current_cell := layer.get_cell_name(cell)
		if current_cell == "":
			return
		undo_redo.create_action("Erase cell")
		undo_redo.add_do_method(layer.set_cell_by_name.bind(cell, ""))
		undo_redo.add_undo_method(layer.set_cell_by_name.bind(cell, current_cell))
		undo_redo.commit_action()
	elif selection is TilePalette.TilePaletteWallLayerSelection:
		var layer := (selection as TilePalette.TilePaletteWallLayerSelection).layer
		var wall := layer.local_to_grid_line(layer.get_local_mouse_position())
		if wall.is_empty():
			return
		if not layer.has_wall(wall[0], wall[1]):
			return
		undo_redo.create_action("Erase wall")
		undo_redo.add_do_method(layer.remove_wall.bind(wall[0], wall[1]))
		undo_redo.add_undo_method(layer.add_wall.bind(wall[0], wall[1]))
		undo_redo.commit_action()


func _get_mouse_cell() -> Vector2i:
	return _get_cell_from_global_position(get_global_mouse_position())


@warning_ignore("shadowed_variable_base_class")
func _get_cell_from_global_position(
	global_position: Vector2
) -> Vector2i:
	var selection := tile_palette.selection
	if selection is TilePalette.TilePaletteTileLayerSelection:
		var layer := (selection as TilePalette.TilePaletteTileLayerSelection).layer
		var local_position := layer.to_local(global_position)
		return selection.layer.local_to_map(local_position)
	elif selection is TilePalette.TilePaletteWallLayerSelection:
		var layer := (selection as TilePalette.TilePaletteWallLayerSelection).layer.tile_map_layer
		var local_position := layer.to_local(global_position)
		return selection.layer.local_to_map(local_position)
	return Vector2i.ZERO

@warning_ignore("shadowed_variable_base_class")
func show_editor(visible: bool) -> void:
	if visible:
		tile_palette.visible = true
	else:
		tile_palette.clear_selection()
		tile_palette.visible = false
