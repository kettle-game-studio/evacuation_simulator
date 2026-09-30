class_name VisibleData
extends RefCounted

class ArrowData:
	extends RefCounted

	var position: PositionAndDistance
	var direction: Vector2
	
	func _init(pos: PositionAndDistance, dir: Vector2):
		position = pos
		direction = dir

class PositionAndDistance:
	extends RefCounted

	var map_position: Vector2i
	var global_position: Vector2
	var map_distance: float
	
	@warning_ignore("shadowed_variable")
	func  _init(map_position: Vector2i, global_position: Vector2, map_distance: float) -> void:
		self.map_position = map_position
		self.global_position = global_position
		self.map_distance = map_distance

var fire: Array[PositionAndDistance] = []
var exits: Array[PositionAndDistance] = []
var arrows: Array[ArrowData] = []
var tile_size: Vector2i = Vector2i.ZERO
var global_position: Vector2
var map_position: Vector2i

func _init(tsize: Vector2i, global_pos: Vector2, map_pos: Vector2i) -> void:
	tile_size = tsize
	global_position = global_pos
	map_position = map_pos
