extends Activity

@onready var play_button: Button = %Play
@onready var designer_button: Button = %Designer
@onready var settings_button: Button = %Settings
@onready var exit_button: Button = %Exit

func _activity_enabled(_camera: Camera2D, _options: Dictionary):
	pass

func _activity_disabled():
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	designer_button.pressed.connect(func(): activity_manager.enter_activity(&"Designer", {}))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
