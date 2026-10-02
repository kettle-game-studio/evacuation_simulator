class_name Simulation
extends Activity

@export var map_data: MapData = MapData.new()
@onready var map: Map = %Map
@onready var editor: TileMapEditor = $Map/Editor

@onready var run_simulation_button: Button = %RunSimulation
@onready var stop_simulation_button: Button = %StopSimulation

var _camera: Camera2D

func _activity_enabled(camera: Camera2D, options: Dictionary):
	map.ui.visible = true
	if &"map_data" in options:
		map_data = options[&"map_data"]
		map.draw_map(map_data)
	_camera = camera
	_camera.position = map.get_boundaries().get_center()

func _activity_disabled():
	map.ui.visible = false
	_stop()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	run_simulation_button.pressed.connect(run_simulation)
	stop_simulation_button.pressed.connect(_stop)
	map.ui.exiting.connect(_emit_exit_request)
	_stop()

func _stop() -> void:
	run_simulation_button.visible = true
	stop_simulation_button.visible = false
	map.pause_simulation()
	map.draw_map(map_data, false)
	map.show_actors(false)
	map.show_fire(false)
	editor.show_editor(true)

func run_simulation():
	run_simulation_button.visible = false
	stop_simulation_button.visible = true
	map.show_actors(true)
	map.show_fire(true)
	map.start_simulation()
	editor.show_editor(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
