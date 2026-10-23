class_name MapGraph
extends RefCounted

enum VertexType { EMPTY, EXIT, FIRE }

class VertexData:
	var edges: Array[Vector2i] = []
	var type: VertexType = VertexType.EMPTY
	var closest_exit := INT32_MAX
	var closest_fire := INT32_MAX
	var room := -1
	var bridges: Array[Vector2i] = []

class Room:
	var vertexes: Array[Vector2i] = []

var vertexes: Dictionary[Vector2i, VertexData] = {}
var rooms: Array[Room] = [Room.new()]


func add_edge(from: Vector2i, to: Vector2i):
	if not vertexes[from]:
		vertexes[from] = VertexData.new()
	if not vertexes[to]:
		vertexes[to] = VertexData.new()
	vertexes[from].edges.push_back(to)
	vertexes[to].edges.push_back(from)
	
func add_vertex(coords: Vector2i, type: VertexType):
	var v := VertexData.new()
	v.type = type
	vertexes[coords] = v
	
func bake() -> void:
	bake_closest_exit()
	bake_closest_fire()
	search_bridges()

func bake_closest_exit() -> void:
	_bake_closest(VertexType.EXIT, &"closest_exit")
func bake_closest_fire() -> void:
	_bake_closest(VertexType.FIRE, &"closest_fire")
	
func _bake_closest(type: VertexType, field: StringName) -> void:
	for coords in vertexes:
		var data := vertexes[coords]
		if data.type != type:
			continue
		data[field] = 0
		var visited: Dictionary[Vector2i, int] = { coords: 0 }
		var queue: Array[Vector2i] = [coords]
		var i := 0
		while queue.size() != i:
			var top: Vector2i = queue[i]
			i += 1
			for neighbour in vertexes[top].edges:
				if visited.has(neighbour):
					continue
				queue.push_back(neighbour)
				visited[neighbour] = visited[top] + 1
				vertexes[neighbour][field] = min(visited[neighbour], vertexes[neighbour][field])

func _bridge_dfs(
	timer: Array[int],
	visited: Dictionary[Vector2i, bool],
	time_in: Dictionary[Vector2i, int],
	time_up: Dictionary[Vector2i, int],
	v: Vector2i,
	parent: Vector2i,
):
	visited[v] = true
	time_in[v] = timer[0]
	time_up[v] = timer[0]
	timer[0] += 1
	
	for to in vertexes[v].edges:
		if to == parent:
			continue
		if visited.has(to):
			time_up[v] = mini(time_up[v], time_in[to])
		else:
			_bridge_dfs(timer, visited, time_in, time_up, to, v)
			time_up[v] = mini(time_up[v], time_up[to])
			if time_up[to] > time_in[v]:
				vertexes[v].bridges.push_back(to)
				vertexes[to].bridges.push_back(v)


## http://e-maxx.ru/algo/bridge_searching
func search_bridges():
	var visited: Dictionary[Vector2i, bool] = {}
	var time_in: Dictionary[Vector2i, int] = {}
	var time_up: Dictionary[Vector2i, int] = {}
	var timer: Array[int] = [0]
	var root: Vector2i = vertexes.keys()[0]
	_bridge_dfs(timer, visited, time_in, time_up, root, root)
	visited.clear()
	_rooms_dfs(visited, root, root, 0)

func _rooms_dfs(
	visited: Dictionary[Vector2i, bool],
	v: Vector2i,
	parent: Vector2i,
	current_room: int
):
	visited[v] = true
	var data := vertexes[v]
	if data.bridges.has(parent) and data.bridges.size() == 1:
		rooms.push_back(Room.new())
		current_room = rooms.size() - 1
	data.room = current_room
	rooms[data.room].vertexes.push_back(v)
	for to in data.edges:
		if visited.has(to):
			continue
		_rooms_dfs(visited, to, v, current_room)
