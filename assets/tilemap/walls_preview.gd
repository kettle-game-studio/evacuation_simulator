class_name TileWallOverlay
extends Node2D


var on_draw_at_point: Callable


func _process(_delta: float) -> void:
	if on_draw_at_point:
		queue_redraw()

func _draw() -> void:
	if on_draw_at_point:
		var mouse_pos := get_global_mouse_position()
		on_draw_at_point.call(self, mouse_pos)
