class_name TileGridOverlay
extends TileMapExtention

@export var grid_color := Color(1.0, 1.0, 1.0, 0.18)
@export var grid_line_width := 1.0
@export var grid_enabled := true


func _ready() -> void:
	z_index = 90
	queue_redraw()

func _process(_delta: float) -> void:
	if not grid_enabled:
		return

	queue_redraw()
func _draw() -> void:
	if not grid_enabled:
		return

	var tile_size := get_tile_size()
	if tile_size == Vector2.ZERO:
		return

	var mouse_pos := get_local_mouse_position()
	var grid_center := local_to_grid(mouse_pos)
	var grid_size := 3
	for i in range(-grid_size, grid_size+1):
		grid_color.a = max(1.0 - float(abs(i))/grid_size, 0.1)
		draw_line(
			grid_to_local(grid_center - Vector2i(i, grid_size)),
			grid_to_local(grid_center - Vector2i(i, -grid_size)),
			grid_color)
		draw_line(
			grid_to_local(grid_center - Vector2i(grid_size, i)),
			grid_to_local(grid_center - Vector2i(-grid_size, i)),
			grid_color)
