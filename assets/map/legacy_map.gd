@tool
class_name LegacyMap
extends RefCounted

func _init(data: JSON) -> void:
	json = data

var json: JSON:
	get():
		return _json
	set(value):
		_json = value

var _json: JSON = JSON.new()

func get_exits() -> Array[Vector2i]:
	return _parse_vectors2i("exits")

func _get_array(field_name: String) -> Array:
	var data: Variant = _json.data
	if data == null:
		return []
	return data.get(field_name, [])

func _parse_vectors2i(field_name: String) -> Array[Vector2i]:
	var array: Array[Vector2i] = []
	for cell in _get_array(field_name):
		array.push_back(Vector2i(cell["x"], cell["y"]))
	return array

func get_fire() -> Array[Vector2i]:
	return _parse_vectors2i("fires")

func get_walls() -> Array[Vector2i]:
	var walls: Array[Vector2i] = []
	for start in _parse_vectors2i("wallTops"):
		walls.push_back(start)
		walls.push_back(start + Vector2i(1, 0))
	for start in _parse_vectors2i("wallLefts"):
		walls.push_back(start)
		walls.push_back(start + Vector2i(0, 1))
	return walls

func get_actors() -> Array[ActorMapDescription]:
	var actors: Array[ActorMapDescription] = []
	for pos in _get_array("actors"):
		var n := ActorMapDescription.new()
		n.position = Vector2(pos["x"]/50, pos["y"]/50)
		n.type = "actor"
		actors.push_back(n)
	return actors

func to_map_data() -> MapData:
	var map := MapData.new()
	map.actors = get_actors()
	map.exits = get_exits()
	map.fire = get_fire()
	map.walls = get_walls()
	return map
