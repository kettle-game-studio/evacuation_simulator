@tool
class_name MapData
extends Resource

@export var actors: Array[ActorMapDescription] = []
@export var fire: Array[Vector2i] = []
@export var exits: Array[Vector2i] = []
@export var walls: Array[Vector2i] = []


func get_actors() -> Array[ActorMapDescription]:
	return actors


func get_fire() -> Array[Vector2i]:
	return fire


func get_exits() -> Array[Vector2i]:
	return exits

## Pairs: [start1, end1, start2, end2...]
func get_walls() -> Array[Vector2i]:
	return walls
