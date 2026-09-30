class_name ActivityManager
extends Node

@export var camera: Camera2D
@export var first_activity: StringName
var activities: Dictionary[StringName, Activity] = {}


func _ready() -> void:
	for child in find_children("*", "Activity"):
		@warning_ignore("shadowed_variable_base_class")
		var name := StringName(child.name)
		activities[name] = child
		if name == first_activity:
			stack.push_back(child)
			(child as Activity).enable_activity(camera)
		else:
			(child as Activity).disable_activity()
	print(activities)
var stack: Array[Activity] = []

func enter_activity(activity_name: StringName, options: Dictionary) -> void:
	if stack.size() > 0:
		stack[stack.size()-1].disable_activity()
	var activity := activities[activity_name]
	activity.enable_activity(camera, options)
	stack.push_back(activity)
	activity.exit_requested.connect(func(_a): 
		activity.disable_activity()
		stack.pop_back()
		stack[stack.size()-1].enable_activity(camera),
		CONNECT_ONE_SHOT)
