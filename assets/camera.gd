extends Camera2D

@export var zoom_factor: float = 0.05


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom.x -= zoom_factor
			zoom.y -= zoom_factor
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom.x += zoom_factor
			zoom.y += zoom_factor
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			position-=event.relative/zoom


func _ready() -> void:
	make_current()
