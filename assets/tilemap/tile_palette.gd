class_name TilePalette
extends Container


signal tile_selected(tile_map_layer: TileMapLayerIndexed, tile_name: StringName)
signal wall_selected(wall_layer: TileBoundaryWalls)
signal selection_cleared


@export_category("Tile palette")

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
	button = _add_wall_tile_button(wall_layer.wall_color)
	button.tooltip_text = name
	button.pressed.connect(_on_wall_button_pressed.bind(wall_layer))

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
func _add_wall_tile_button(
	color: Color
) -> Button:
	var button := _create_tile_button()

	var preview := TextureRect.new()
	preview.texture = wall_preview
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


func clear_selection() -> void:
	selection = null
	selection_cleared.emit()


func has_selection() -> bool:
	return selection != null


@abstract
class TilePaletteSelection:
	pass

class TilePaletteTileLayerSelection:
	extends TilePaletteSelection
	var layer: TileMapLayerIndexed
	var name: StringName
	
	func _init(tile_map_layer: TileMapLayerIndexed, tile_name: StringName):
		layer = tile_map_layer
		name = tile_name

class TilePaletteWallLayerSelection:
	extends TilePaletteSelection
	var layer: TileBoundaryWalls
	
	func _init(wall_layer: TileBoundaryWalls):
		layer = wall_layer
