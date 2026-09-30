class_name MapUI
extends CanvasLayer

@onready var tile_palette: TilePalette = %TilePalette
@onready var _exit: Button = %Exit

signal exiting()

func _ready() -> void:
	_exit.pressed.connect(exiting.emit)
