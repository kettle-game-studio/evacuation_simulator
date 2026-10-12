class_name LevelFinishedWindow
extends PanelContainer

@onready var saved_number: Label = %SavedNumber
@onready var died_number: Label = %DiedNumber
@onready var continue_button: Button = %ContinueButton
@onready var exit_button: Button = %ExitButton

signal continue_pressed
signal exit_pressed

func _ready() -> void:
	continue_button.pressed.connect(func():
		continue_pressed.emit()
		hide()
	)
	exit_button.pressed.connect(func():
		exit_pressed.emit()
		hide()
	)

func show_level_finished(saved: int, died: int) -> void:
	saved_number.text = "%d" % saved
	died_number.text = "%d" % died
	show()
