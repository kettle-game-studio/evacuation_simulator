@abstract
class_name Activity
extends CanvasLayer

signal exit_requested(activity: Activity)

var activity_manager: ActivityManager:
	get():
		return get_parent() as ActivityManager

func disable_activity():
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	_activity_disabled()


func enable_activity(camera: Camera2D, options: Dictionary = {}):
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	_activity_enabled(camera, options)

@abstract
func _activity_enabled(camera: Camera2D, options: Dictionary)
@abstract
func _activity_disabled()

func _emit_exit_request():
	exit_requested.emit(self)
