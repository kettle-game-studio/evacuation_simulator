class_name TileBoundaryWalls
extends TileMapExtention

@export var wall_vertices: Array[Vector2i] = []:
	get():
		return _wall_vertices
	set(value):
		_wall_vertices = value
		queue_redraw()

var _wall_vertices: Array[Vector2i] = []
@export_range(1.0, 64.0)
var wall_width: int = 10:
	set(value):
		wall_width = maxi(value, 1)
		queue_redraw()

@export var wall_color := Color(0.1, 0.75, 1.0, 1.0):
	set(value):
		wall_color = value
		queue_redraw()


@export_flags_2d_physics var collision_layer: int = 1

func clear() -> void:
	wall_vertices.clear()
	for child in get_children():
		remove_child(child)
	
func add_wall(start: Vector2i, end: Vector2i) -> void:
	if start == end:
		return

	if start.x != end.x and start.y != end.y:
		return
	if start.x > end.x or start.x == end.x and start.y > end.y:
		var tmp := start
		start = end
		end = tmp
	if has_wall(start, end):
		return
	wall_vertices.append(start)
	wall_vertices.append(end)
	queue_redraw()
	notify_property_list_changed()

func has_wall(start: Vector2i, end: Vector2i) -> bool:
	if start.x > end.x or start.x == end.x and start.y > end.y:
		var tmp := start
		start = end
		end = tmp
	for index in range(0, wall_vertices.size() - 1, 2):
		var start_existed := wall_vertices[index]
		var end_existed := wall_vertices[index + 1]
		if start == start_existed and end == end_existed:
			return true
	return false

func remove_wall(start: Vector2i, end: Vector2i) -> bool:
	for index in range(0, wall_vertices.size() - 1, 2):
		var start_existed := wall_vertices[index]
		var end_existed := wall_vertices[index + 1]
		if start == start_existed and end == end_existed:
			wall_vertices.remove_at(index+1)
			wall_vertices.remove_at(index)
			queue_redraw()
			notify_property_list_changed()
			return true
	return false

func get_boundaries_global() -> Rect2:
	var top_left := Vector2i(INF, INF)
	var bottom_right := Vector2i(-INF, -INF)
	
	for point in wall_vertices:
		top_left.x = min(top_left.x, point.x)
		top_left.y = min(top_left.y, point.y)
		bottom_right.x = max(bottom_right.x, point.x)
		bottom_right.y = max(bottom_right.y, point.y)
	@warning_ignore("shadowed_variable_base_class")
	var position := to_global(grid_to_local(top_left))
	var opposite := to_global(grid_to_local(bottom_right+Vector2i(1, 1)))
	var size := Vector2(opposite.x - position.x, opposite.y - position.y)
	return Rect2(position, size)

func _draw() -> void:
	if get_tile_size() == Vector2.ZERO:
		return
	
	if wall_vertices.size() < 2:
		return
	draw_multiline(_local_walls(), wall_color, wall_width)

func generate_physics():
	var tile_size := get_tile_size()
	if get_tile_size() == Vector2.ZERO:
		return
	for child in get_children():
		remove_child(child)
	var vertical_shape := RectangleShape2D.new()
	vertical_shape.size.x = tile_size.x + wall_width
	vertical_shape.size.y = wall_width
	var horizontal_shape := RectangleShape2D.new()
	horizontal_shape.size.x = wall_width
	horizontal_shape.size.y = tile_size.y + wall_width
	
	var body := StaticBody2D.new()
	body.collision_layer = collision_layer
	add_child(body)
	for index in range(0, wall_vertices.size() - 1, 2):
		var start := wall_vertices[index]
		var end := wall_vertices[index+1]
		var is_vertical := start.y == end.y
		var collider := CollisionShape2D.new()
		body.add_child(collider)
		if is_vertical:
			collider.shape = vertical_shape
			collider.position.x = (start.x + end.x)/2.0 * tile_size.x
			collider.position.y = start.y * tile_size.y
		else:
			collider.shape = horizontal_shape
			collider.position.x = start.x * tile_size.x
			collider.position.y = (start.y + end.y)/2.0 * tile_size.y

func _local_walls() -> PackedVector2Array:
	var batch := PackedVector2Array()
	for index in range(0, wall_vertices.size() - 1, 2):
		var start := grid_to_local(wall_vertices[index])
		var end := grid_to_local(wall_vertices[index + 1])
		var addition := (end - start).normalized() * (wall_width/2.0)
		start -= addition
		end += addition
		batch.append(start)
		batch.append(end)
	return batch

func local_to_grid_line(local: Vector2) -> Array[Vector2i]:
	var start := local_to_grid(local)
	@warning_ignore("shadowed_global_identifier")
	var snapped := grid_to_local(start)
	var dir := local - snapped
	if abs(dir.x) < wall_width and abs(dir.y) < wall_width:
		return []
	var end := start + (Vector2i(sign(dir.x), 0) if abs(dir.x) > abs(dir.y) else Vector2i(0, sign(dir.y)))
	if start.x > end.x or start.x == end.x and start.y > end.y:
		var tmp := start
		start = end
		end = tmp
	return [start, end]
