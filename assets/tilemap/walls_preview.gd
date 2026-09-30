class_name TileWallOverlay
extends Node2D


@export var preview_color := Color(1.0, 0.5, 0.0, 0.85)
@export var walls_layer: TileBoundaryWalls


func _process(_delta: float) -> void:
	if walls_layer:
		queue_redraw()

func _draw() -> void:
	if walls_layer == null:
		return
	var mouse_pos := get_local_mouse_position()
	var grid_color := preview_color
	var new_line := walls_layer.local_to_grid_line(mouse_pos)
	if not new_line.is_empty():
		grid_color.a = 0.6
		draw_line(
			walls_layer.grid_to_local(new_line[0]), 
			walls_layer.grid_to_local(new_line[1]), 
			grid_color, 
			walls_layer.wall_width+2
		)
