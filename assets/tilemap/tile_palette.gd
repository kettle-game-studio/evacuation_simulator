class_name TilePalette
extends Container


signal tile_selected(tile_map_layer: TileMapLayerIndexed, tile_name: StringName)
signal wall_selected(wall_layer: TileBoundaryWalls)
signal selection_cleared


@export_category("Tile palette")
@export var tool_factories: Array[Script]
@export var wall_preview: Texture2D

@export var button_size := Vector2(48.0, 48.0)

@export var scene_preview_size := Vector2i(48, 48)

@export var scene_preview_scale := 1.0

@export var disable_scene_processing := true

var selection: TilePaletteSelection

func _clear_palette() -> void:
	for child in get_children():
		child.queue_free()


# --------------------------------------------------------------------
# Atlas tiles
# --------------------------------------------------------------------
@warning_ignore("shadowed_variable_base_class")
func add_tile(tile_map_layer: TileMapLayerIndexed,
				name: StringName, 
				tile_data: TileMapLayerIndexed.IndexedTileData):
	var source := tile_map_layer.tile_set.get_source(tile_data.source_id)
	var button: Button
	if source is TileSetAtlasSource:
		button = _add_atlas_tile_button(
			tile_map_layer.tile_set, 
			tile_data.source_id,
			tile_data.atlas_coordinates,
			tile_data.alternative_id,
		)
	else:
		button = _add_scene_tile_button(
			tile_map_layer.tile_set, 
			tile_data.source_id, 
			tile_data.alternative_id, 
			)
	button.tooltip_text = name
	button.pressed.connect(
		_on_tile_button_pressed.bind(
			tile_map_layer,
			name
		)
	)
func add_wall(wall_layer: TileBoundaryWalls):
	var button: Button
	button = _add_sprite_tile_button(wall_preview, wall_layer.wall_color)
	button.tooltip_text = name
	button.pressed.connect(_on_wall_button_pressed.bind(wall_layer))

func add_wall_rect(wall_layer: TileBoundaryWalls):
	var button: Button
	button = _add_sprite_tile_button(wall_preview, wall_layer.wall_color)
	button.tooltip_text = name
	button.pressed.connect(_on_wall_rect_button_pressed.bind(wall_layer))

func _add_atlas_tile_button(
	tile_set: TileSet,
	source_id: int,
	atlas_coords: Vector2i,
	alternative_id: int
) -> Button:
	var button := _create_tile_button()

	var preview := _create_tile_preview(
		tile_set,
		source_id,
		atlas_coords,
		alternative_id
	)

	button.add_child(preview)
	add_child(button)

	return button
func _create_tile_preview(
	tile_set: TileSet,
	source_id: int,
	atlas_coords: Vector2i,
	alternative_id: int
) -> SubViewportContainer:
	var container := SubViewportContainer.new()

	container.custom_minimum_size = button_size
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.stretch = true

	var viewport := SubViewport.new()

	viewport.size = scene_preview_size
	viewport.transparent_bg = true
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS
	)

	container.add_child(viewport)

	var preview_layer := TileMapLayer.new()

	preview_layer.tile_set = tile_set

	viewport.add_child(preview_layer)

	var tile_size := Vector2(tile_set.tile_size)
	var viewport_size := Vector2(scene_preview_size)

	var available_size := viewport_size - Vector2.ONE * 2.0

	var scale_x := available_size.x / tile_size.x
	var scale_y := available_size.y / tile_size.y

	var preview_scale := minf(scale_x, scale_y)

	preview_layer.scale = Vector2.ONE * preview_scale

	preview_layer.position = (
		viewport_size
		- tile_size * preview_scale
	) / 2.0

	preview_layer.set_cell(
		Vector2i.ZERO,
		source_id,
		atlas_coords,
		alternative_id
	)

	return container

# --------------------------------------------------------------------
# Scene tiles
# --------------------------------------------------------------------

func _add_scene_tile_button(
	tile_set: TileSet,
	source_id: int,
	scene_id: int,
) -> Button:
	var button := _create_tile_button()

	var preview := _create_tile_preview(
		tile_set,
		source_id,
		Vector2i.ZERO,
		scene_id
	)

	button.add_child(preview)
	add_child(button)

	return button

# Wall
func _add_sprite_tile_button(
	texture: Texture2D,
	color: Color
) -> Button:
	var button := _create_tile_button()

	var preview := TextureRect.new()
	preview.texture = texture
	preview.modulate = color
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	button.add_child(preview)
	add_child(button)

	return button
# --------------------------------------------------------------------
# Selection
# --------------------------------------------------------------------

func _create_tile_button() -> Button:
	var button := Button.new()

	button.custom_minimum_size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.flat = false

	return button

func _on_tile_button_pressed(
	tile_map_layer: TileMapLayerIndexed,
	tile_name: StringName
) -> void:
	selection = TilePaletteTileLayerSelection.new(tile_map_layer, tile_name)
	tile_selected.emit(tile_map_layer, tile_name)


func _on_wall_button_pressed(
	wall_layer: TileBoundaryWalls
) -> void:
	selection = TilePaletteWallLayerSelection.new(wall_layer)
	wall_selected.emit(wall_layer)

func _on_wall_rect_button_pressed(
	wall_layer: TileBoundaryWalls
) -> void:
	selection = TilePaletteWallRectSelection.new(wall_layer)
	wall_selected.emit(wall_layer)

func clear_selection() -> void:
	selection = null
	selection_cleared.emit()


func has_selection() -> bool:
	return selection != null


@abstract
class TilePaletteSelection:
	@abstract
	func paint_at(undo_redo: UndoRedo, position: Vector2) -> void
	@abstract
	func erase_at(undo_redo: UndoRedo, position: Vector2) -> void
	@abstract
	func draw_preview(node: Node2D, position: Vector2) -> void

class TilePaletteTileLayerSelection:
	extends TilePaletteSelection
	var layer: TileMapLayerIndexed
	var name: StringName
	
	func _init(tile_map_layer: TileMapLayerIndexed, tile_name: StringName):
		layer = tile_map_layer
		name = tile_name
	
	func paint_at(undo_redo: UndoRedo, position: Vector2) -> void:
		var local_position := layer.to_local(position)
		var cell := layer.local_to_map(local_position)
		var current_cell := layer.get_cell_name(cell)
		if current_cell == name:
			return
		undo_redo.create_action("Set cell")
		undo_redo.add_do_method(layer.set_cell_by_name.bind(cell, name))
		undo_redo.add_undo_method(layer.set_cell_by_name.bind(cell, current_cell))
		undo_redo.commit_action()
	
	func erase_at(undo_redo: UndoRedo, position: Vector2) -> void:
		var local_position := layer.to_local(position)
		var cell := layer.local_to_map(local_position)
		var current_cell := layer.get_cell_name(cell)
		if current_cell == "":
			return
		undo_redo.create_action("Erase cell")
		undo_redo.add_do_method(layer.set_cell_by_name.bind(cell, ""))
		undo_redo.add_undo_method(layer.set_cell_by_name.bind(cell, current_cell))
		undo_redo.commit_action()
	
	func draw_preview(_node: Node2D, _position: Vector2) -> void:
		pass # Отдельный костыль есть

class TilePaletteWallLayerSelection:
	extends TilePaletteSelection
	var layer: TileBoundaryWalls
	
	func _init(wall_layer: TileBoundaryWalls):
		layer = wall_layer
	
	func paint_at(undo_redo: UndoRedo, position: Vector2) -> void:
		var wall := layer.local_to_grid_line(layer.to_local(position))
		if wall.is_empty():
			return
		if layer.has_wall(wall[0], wall[1]):
			return
		undo_redo.create_action("Set wall")
		undo_redo.add_do_method(layer.add_wall.bind(wall[0], wall[1]))
		undo_redo.add_undo_method(layer.remove_wall.bind(wall[0], wall[1]))
		undo_redo.commit_action()

	func erase_at(undo_redo: UndoRedo, position: Vector2) -> void:
		var wall := layer.local_to_grid_line(layer.to_local(position))
		if wall.is_empty():
			return
		if not layer.has_wall(wall[0], wall[1]):
			return
		undo_redo.create_action("Erase wall")
		undo_redo.add_do_method(layer.remove_wall.bind(wall[0], wall[1]))
		undo_redo.add_undo_method(layer.add_wall.bind(wall[0], wall[1]))
		undo_redo.commit_action()
	
	func draw_preview(node: Node2D, position: Vector2) -> void:
		var grid_color := Color(1.0, 0.5, 0.0, 0.85)
		var new_line := layer.local_to_grid_line(layer.to_local(position))
		if not new_line.is_empty():
			grid_color.a = 0.6
			node.draw_line(
				layer.grid_to_local(new_line[0]), 
				layer.grid_to_local(new_line[1]), 
				grid_color, 
				layer.wall_width+2
			)

class TilePaletteWallRectSelection:
	extends TilePaletteSelection
	var layer: TileBoundaryWalls
	# nullable crutch
	var first_point: Array[Vector2]
	func _init(wall_layer: TileBoundaryWalls):
		layer = wall_layer

	func paint_at(undo_redo: UndoRedo, position: Vector2) -> void:
		position = layer.to_local(position)
		if first_point.size() == 0:
			first_point = [layer.local_to_snapped(position)]
			return
		var second_point = layer.local_to_snapped(position)
		var p1 := layer.local_to_grid(first_point[0])
		var p2 := layer.local_to_grid(second_point)
		var x_min := mini(p1.x, p2.x)
		var x_max := maxi(p1.x, p2.x)
		var y_min := mini(p1.y, p2.y)
		var y_max := maxi(p1.y, p2.y)
		undo_redo.create_action("Set wall rect")
		for x in range(x_min, x_max):
			var w0 := Vector2i(x, y_min)
			var w1 := Vector2i(x+1, y_min)
			undo_redo.add_do_method(layer.add_wall.bind(w0, w1))
			undo_redo.add_undo_method(layer.remove_wall.bind(w0, w1))
			var w2 := Vector2i(x, y_max)
			var w3 := Vector2i(x+1, y_max)
			undo_redo.add_do_method(layer.add_wall.bind(w2, w3))
			undo_redo.add_undo_method(layer.remove_wall.bind(w2, w3))
		for y in range(y_min, y_max):
			var w0 := Vector2i(x_min, y)
			var w1 := Vector2i(x_min, y+1)
			undo_redo.add_do_method(layer.add_wall.bind(w0, w1))
			undo_redo.add_undo_method(layer.remove_wall.bind(w0, w1))
			var w2 := Vector2i(x_max, y)
			var w3 := Vector2i(x_max, y+1)
			undo_redo.add_do_method(layer.add_wall.bind(w2, w3))
			undo_redo.add_undo_method(layer.remove_wall.bind(w2, w3))
		undo_redo.commit_action()
		first_point = []
		
	func erase_at(_undo_redo: UndoRedo, _position: Vector2) -> void:
		first_point = []
	
	func draw_preview(node: Node2D, position: Vector2) -> void:
		position = layer.to_local(position)
		if first_point.size() == 0:
			var p := layer.local_to_snapped(position)
			node.draw_rect(Rect2(p.x-8, p.y-8, 16, 16), Color.DIM_GRAY)
			return
		var p1 := first_point[0]
		var p2 := layer.local_to_snapped(position)
		var x_min := mini(p1.x, p2.x)
		var x_max := maxi(p1.x, p2.x)
		var y_min := mini(p1.y, p2.y)
		var y_max := maxi(p1.y, p2.y)
		node.draw_rect(Rect2(x_min, y_min, x_max-x_min, y_max-y_min), Color.DIM_GRAY, false, 4)
		
		
