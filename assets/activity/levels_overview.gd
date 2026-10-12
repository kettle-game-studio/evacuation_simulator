class_name LevelsOverview
extends Activity

@onready var levels_conatiner: GridContainer = %LevelsConatiner

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var root := "res://assets/levels/campain/"
	var levels := DirAccess.get_files_at(root)
	var num := 1
	for level in levels:
		var level_data = load(root+level)
		if level_data is not MapData:
			continue
		var button := Button.new()
		button.text = "%d" % num
		num += 1
		button.custom_minimum_size = Vector2(64, 64)
		button.pressed.connect(func(): activity_manager.enter_activity("Simulation", {
			&"map_data": level_data, &"clear_gameplay": true
		}))
		levels_conatiner.add_child(button)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _activity_enabled(_camera: Camera2D, _options: Dictionary):
	pass
func _activity_disabled():
	pass
