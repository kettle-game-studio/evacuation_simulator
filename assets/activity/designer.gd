class_name Designer
extends Activity

var map_data: MapData = MapData.new()

@onready var map: Map = %Map

@onready var new: Button = %New
@onready var open: Button = %Open
@onready var open_map_dialog: FileDialog = $OpenMapDialog

@onready var save: Button = %Save
@onready var save_as: Button = %SaveAs
@onready var save_as_map_dialog: FileDialog = $SaveAsMapDialog

@onready var play: Button = %Play

@onready var import_json: Button = %ImportJSON
@onready var import_json_map_dialog: FileDialog = $ImportJSONMapDialog

var _camera: Camera2D
func _activity_enabled(camera: Camera2D, _options: Dictionary):
	camera.position = map.get_boundaries().get_center()
	_camera = camera
	map.ui.visible = true

func _activity_disabled():
	map.ui.visible = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map.ui.exiting.connect(_emit_exit_request)
	new.pressed.connect(func():	set_map_data(MapData.new()))
	open.pressed.connect(open_map_dialog.popup_file_dialog)
	open_map_dialog.file_selected.connect(_on_open_file_selected)
	
	import_json.pressed.connect(import_json_map_dialog.popup_file_dialog)
	import_json_map_dialog.file_selected.connect(_on_import_json_file_selected)
	
	save.pressed.connect(_on_save)
	save_as.pressed.connect(save_as_map_dialog.popup_file_dialog)
	save_as_map_dialog.file_selected.connect(_on_save_as_file_selected)
	
	play.pressed.connect(
		func(): 
			_update_map()
			(get_parent() as ActivityManager).enter_activity("Simulation", {&"map_data": map_data})
	)
	
	_update_buttons_state()

func _on_open_file_selected(path: String) -> void:
	var new_map = load(path)
	if new_map is not MapData:
		return # TODO: show error
	set_map_data(new_map)

func set_map_data(new_map: MapData) -> void:
	map_data = new_map
	map.draw_map(map_data)
	if _camera:
		_camera.position = map.get_boundaries().get_center()
	_update_buttons_state()

func _on_import_json_file_selected(path: String) -> void:
	var json = load(path)
	if json is not JSON:
		return # TODO: show error
	set_map_data(LegacyMap.new(json).to_map_data()) # TODO: process errors

func _on_save_as_file_selected(path: String) -> void:
	map_data.resource_path = path
	_on_save()
	_update_buttons_state()

func _update_map() -> void:
	map_data.actors = map.get_actors()
	map_data.exits = map.get_exits()
	map_data.fire = map.get_fire()
	map_data.walls = map.get_walls()
func _on_save() -> void:
	_update_map()
	map_data.set_path_cache(map_data.resource_path)
	ResourceSaver.save(map_data)

func _update_buttons_state() -> void:
	save.disabled = map_data.resource_path.is_empty()
