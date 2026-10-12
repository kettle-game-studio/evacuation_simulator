class_name Simulation
extends Activity

@export var map_data: MapData = MapData.new()
@onready var map: Map = %Map
@onready var editor: TileMapEditor = $Map/Editor
@onready var level_finished_window: LevelFinishedWindow = %LevelFinishedWindow

@onready var run_simulation_button: Button = %RunSimulation
@onready var stop_simulation_button: Button = %StopSimulation
@onready var saved_number: Label = %SavedNumber
@onready var died_number: Label = %DiedNumber
@onready var counters: HBoxContainer = %Counters

var _camera: Camera2D

func _update_ui_counters(saved: int, died: int, total: int) -> void:
	saved_number.text = "%d/%d" % [saved, total]
	died_number.text = "%d/%d" % [died, total]
	if saved + died == total:
		map.pause_simulation()
		level_finished_window.show_level_finished(saved, died)

func _activity_enabled(camera: Camera2D, options: Dictionary):
	map.ui.visible = true
	if &"map_data" in options:
		map_data = options[&"map_data"]
		map.draw_map(map_data)
	if &"clear_gameplay" in options:
		map.gameplay_layer.clear()
	_camera = camera
	_camera.position = map.get_boundaries().get_center()

func _activity_disabled():
	map.ui.visible = false
	_stop()


func _ready() -> void:
	run_simulation_button.pressed.connect(run_simulation)
	stop_simulation_button.pressed.connect(_stop)
	map.ui.exiting.connect(_emit_exit_request)
	map.actors_count_changed.connect(_update_ui_counters)
	
	level_finished_window.continue_pressed.connect(func():
		_stop()
	)
	level_finished_window.exit_pressed.connect(func():
		_emit_exit_request()
	)
	_stop()


func _stop() -> void:
	run_simulation_button.visible = true
	stop_simulation_button.visible = false
	counters.visible = false
	map.pause_simulation()
	map.draw_map(map_data, false)
	map.show_actors(false)
	map.show_fire(false)
	editor.show_editor(true)


func run_simulation():
	run_simulation_button.visible = false
	stop_simulation_button.visible = true
	counters.visible = true
	map.show_actors(true)
	map.show_fire(true)
	map.start_simulation()
	editor.show_editor(false)
