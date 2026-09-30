class_name TileMapEditor
extends Node2D

@export var tile_map_layers: Array[TileMapLayerIndexed]
@export var walls_layers: Array[TileBoundaryWalls]
@export var grid_overlay: TileGridOverlay
@export var preview_layer: TileEditorOverlay
@export var tile_palette: TilePalette
@export var walls_overlay: TileWallOverlay


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
		layer.set_cell_by_name(cell, selection.name)
	elif selection is TilePalette.TilePaletteWallLayerSelection:
		var layer := (selection as TilePalette.TilePaletteWallLayerSelection).layer
		var wall := layer.local_to_grid_line(layer.get_local_mouse_position())
		if wall.is_empty():
			return
		layer.add_wall(wall[0], wall[1])


func _erase_at_mouse() -> void:
	var selection := tile_palette.selection
	if selection is TilePalette.TilePaletteTileLayerSelection:
		var cell := _get_mouse_cell()
		var layer := (selection as TilePalette.TilePaletteTileLayerSelection).layer
		layer.set_cell(cell, -1)
	elif selection is TilePalette.TilePaletteWallLayerSelection:
		var layer := (selection as TilePalette.TilePaletteWallLayerSelection).layer
		var wall := layer.local_to_grid_line(layer.get_local_mouse_position())
		if wall.is_empty():
			return
		layer.remove_wall(wall[0], wall[1])


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
