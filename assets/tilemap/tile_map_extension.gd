@abstract
class_name TileMapExtention
extends Node2D

@export var tile_map_layer: TileMapLayer

func get_tile_size() -> Vector2:
	if tile_map_layer == null:
		return Vector2.ZERO

	if tile_map_layer.tile_set == null:
		return Vector2.ZERO

	return Vector2(tile_map_layer.tile_set.tile_size)


# Преобразует индекс вершины сетки в локальные координаты компонента.
#
# Вершина Vector2i(0, 0) соответствует локальной позиции (0, 0)
# TileMapLayer. Далее учитывается трансформация TileMapLayer и самого
# TileBoundaryWalls.
func grid_to_local(grid_position: Vector2i) -> Vector2:
	var tile_size := get_tile_size()

	if tile_map_layer == null or tile_size == Vector2.ZERO:
		return Vector2.ZERO

	var position_in_tile_map := Vector2(grid_position) * tile_size
	var position_in_global := tile_map_layer.to_global(position_in_tile_map)

	return to_local(position_in_global)


# Преобразует локальную позицию компонента в ближайшую вершину сетки.
func local_to_grid(local_position: Vector2) -> Vector2i:
	var tile_size := get_tile_size()

	if tile_size == Vector2.ZERO:
		return Vector2i.ZERO

	if tile_map_layer == null:
		return Vector2i.ZERO

	@warning_ignore("shadowed_variable_base_class")
	var global_position := to_global(local_position)
	var tile_map_position := tile_map_layer.to_local(global_position)

	return Vector2i(
		roundi(tile_map_position.x / tile_size.x),
		roundi(tile_map_position.y / tile_size.y)
	)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			call_deferred("update_configuration_warnings")

		NOTIFICATION_UNPARENTED:
			call_deferred("update_configuration_warnings")


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if tile_map_layer == null:
		warnings.append(
			"TileBoundaryWalls must have a TileMapLayer assigned."
		)
		return warnings

	if tile_map_layer.tile_set == null:
		warnings.append(
			"The assigned TileMapLayer must have a TileSet assigned."
		)

	return warnings
