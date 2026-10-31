class_name MapGraph
extends RefCounted

enum VertexType { EMPTY, EXIT, FIRE }

enum VertexWalls {
	NONE = 0,
	TOP = 0b0001,
	RIGHT = 0b0010,
	BOTTOM = 0b0100,
	LEFT = 0b1000,
}

class VertexData:
	var coordinates: Vector2i
	var edges: Array[Vector2i] = []
	var type: VertexType = VertexType.EMPTY
	var closest_exit := INT32_MAX
	var closest_fire := INT32_MAX
	var room := -1
	var bridges: Array[Vector2i] = []
	var walls: VertexWalls = VertexWalls.NONE
	var is_border := false

class Room:
	var vertexes: Array[Vector2i] = []
	var is_outer: bool = false

var vertexes: Dictionary[Vector2i, VertexData] = {}
var rooms: Array[Room] = [Room.new()]


func add_edge(from: Vector2i, to: Vector2i):
	if not vertexes[from]:
		vertexes[from] = VertexData.new()
	if not vertexes[to]:
		vertexes[to] = VertexData.new()
	vertexes[from].edges.push_back(to)
	vertexes[to].edges.push_back(from)
	
func add_vertex(coords: Vector2i, type: VertexType, walls: VertexWalls):
	var v := VertexData.new()
	v.coordinates = coords
	v.type = type
	v.walls = walls
	vertexes[coords] = v
	
func bake() -> void:
	bake_closest_exit()
	bake_closest_fire()
	search_bridges()
	_assign_rooms()

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
	v: Vector2i,
	parent: Vector2i,
	timer: Array[int] = [0],
	time_in: Dictionary[Vector2i, int] = {},
	time_up: Dictionary[Vector2i, int] = {},
	visited: Dictionary[Vector2i, bool] = {},
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
			_bridge_dfs(to, v, timer, time_in, time_up, visited)
			time_up[v] = mini(time_up[v], time_up[to])
			if time_up[to] > time_in[v]:
				vertexes[v].bridges.push_back(to)
				vertexes[to].bridges.push_back(v)


## http://e-maxx.ru/algo/bridge_searching
func search_bridges():
	var root: Vector2i = vertexes.keys()[0]
	_bridge_dfs(root, root)

func _assign_rooms() -> void:
	rooms.clear()
	var visited: Dictionary[Vector2i, bool] = {}

	for start in vertexes.keys():
		if visited.has(start):
			continue

		var room := Room.new()
		var room_id := rooms.size()
		rooms.push_back(room)

		var stack: Array[Vector2i] = [start]
		visited[start] = true

		while not stack.is_empty():
			var v: Vector2i = stack.pop_back()
			var data: VertexData = vertexes[v]

			data.room = room_id
			room.vertexes.push_back(v)

			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if not vertexes.has(v + dir):
					room.is_outer = true
					data.is_border = true
					break

			for to in data.edges:
				if visited.has(to) or is_gate(v, to):
					continue

				visited[to] = true
				stack.push_back(to)

func _has_parallel_wall(v1: Vector2i, v2: Vector2i, side: Vector2i) -> bool:
	var a := v1 + side
	var b := v2 + side

	# Проверять можно только существующую пару соседних вершин.
	if not vertexes.has(a) or not vertexes.has(b):
		return false

	# Нет ребра между парой — стена продолжается параллельно проходу.
	return not vertexes[a].edges.has(b)


func is_gate(v1: Vector2i, v2: Vector2i) -> bool:
	var d1: VertexData = vertexes[v1]

	# Топологический критерий: ребро является мостом графа.
	if d1.bridges.has(v2):
		return true

	# Геометрический критерий: рядом с открытым проходом есть стена,
	# продолжающаяся параллельно ему.
	if v1.x == v2.x:
		return (
			_has_parallel_wall(v1, v2, Vector2i.LEFT)
			or _has_parallel_wall(v1, v2, Vector2i.RIGHT)
		)

	return (
		_has_parallel_wall(v1, v2, Vector2i.UP)
		or _has_parallel_wall(v1, v2, Vector2i.DOWN)
	)
