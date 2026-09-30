@warning_ignore("missing_tool")
class_name TileEditorOverlay
extends TileMapLayerIndexed


var target_layer: TileMapLayerIndexed:
	get():
		return _target_layer
	set(value):
		_target_layer = value
		_last_preview_cell = Vector2i(999999, 999999)
		if value != null:
			visible = true
			tile_set = _target_layer.tile_set
			z_index = _target_layer.z_index + 1
			_update_preview.call_deferred(get_global_mouse_position())
		else:
			visible = false

var tile: String:
	get():
		return _tile
	set(value):
		if value == null:
			visible = false
		_last_preview_cell = Vector2i(999999, 999999)
		_update_preview.call_deferred(get_global_mouse_position())
		_tile = value


@export_category("Preview")

@export var preview_modulate := Color(1.0, 1.0, 1.0, 0.55)

@export_category("Input")

@export var paint_with_left_mouse := true
@export var erase_with_right_mouse := true


var _tile: String
var _target_layer: TileMapLayerIndexed
var _last_preview_cell := Vector2i(999999, 999999)
var _last_mouse_position := Vector2.INF


func _ready() -> void:
	# Превью должно быть полупрозрачным.
	modulate = preview_modulate

	# Не создаём физику, навигацию и occlusion для превью.
	collision_enabled = false
	navigation_enabled = false
	occlusion_enabled = false

	visible = false
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if target_layer == null:
		return

	if event is InputEventMouseMotion:
		var mouse_position := get_global_mouse_position()
		if mouse_position == _last_mouse_position:
			return
		_last_mouse_position = mouse_position
		_update_preview(mouse_position)

# --------------------------------------------------------------------
# Preview
# --------------------------------------------------------------------

func _update_preview(mouse_position: Vector2) -> void:
	var cell := _get_cell_from_global_position(mouse_position)

	if cell == _last_preview_cell:
		return

	_last_preview_cell = cell

	clear()

	set_cell_by_name(cell, tile)


@warning_ignore("shadowed_variable_base_class")
func _get_cell_from_global_position(
	global_position: Vector2
) -> Vector2i:
	var local_position := target_layer.to_local(
		global_position
	)

	return target_layer.local_to_map(
		local_position
	)
