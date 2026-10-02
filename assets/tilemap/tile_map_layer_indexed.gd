class_name TileMapLayerIndexed
extends TileMapLayer

class IndexedTileData:
	extends RefCounted

	var source_id: int
	var atlas_coordinates: Vector2i
	var alternative_id: int
	
	@warning_ignore("shadowed_variable")
	func _init(source_id: int, atlas_coordinates: Vector2i, alternative_id: int) -> void:
		self.source_id = source_id
		self.atlas_coordinates = atlas_coordinates
		self.alternative_id = alternative_id
	
	@warning_ignore("shadowed_variable")
	func equals(source_id: int, atlas_coordinates: Vector2i, alternative_id: int) -> bool:
		return self.source_id == source_id and \
			self.atlas_coordinates == atlas_coordinates and \
			self.alternative_id == alternative_id
var tiles_index: Dictionary[StringName, IndexedTileData]:
	get():
		return _index
var _index: Dictionary[StringName, IndexedTileData] = {}
var _indexed_tile_set: TileSet

func _init() -> void:
	changed.connect(build_index)
	build_index()

func build_index():
	if _indexed_tile_set == tile_set:
		return
	_index.clear()
	_indexed_tile_set = tile_set
	for i in tile_set.get_source_count():
		var source_id := tile_set.get_source_id(i)
		var source := tile_set.get_source(source_id)
		if source is TileSetAtlasSource:
			var atlas := source as TileSetAtlasSource
			for j in atlas.get_tiles_count():
				var atlas_coords := atlas.get_tile_id(j)
				for k in atlas.get_alternative_tiles_count(atlas_coords):
					var alternative_id := atlas.get_alternative_tile_id(atlas_coords, k)
					var data := atlas.get_tile_data(atlas_coords, alternative_id)
					var tile_name = data.get_custom_data("tile_name")
					if tile_name != null:
						_index[tile_name] = IndexedTileData.new(source_id, atlas_coords, alternative_id)
		elif source is TileSetScenesCollectionSource:
			var scenes := source as TileSetScenesCollectionSource
			for j in scenes.get_scene_tiles_count():
				var alternative_id := scenes.get_scene_tile_id(j)
				var scene := scenes.get_scene_tile_scene(alternative_id)
				var tile_name = _scene_tile_name(scene)
				_index[tile_name] = IndexedTileData.new(source_id, Vector2i(0, 0), alternative_id)

func _scene_tile_name(scene: PackedScene) -> StringName:
	var path := scene.resource_path
	if path.is_empty():
		push_warning("Scene tile has no resource_path")
		return &""

	return StringName(path.get_file().get_basename())

## name == &"" -> erase
@warning_ignore("shadowed_variable_base_class")
func set_cell_by_name(coords: Vector2i, name: StringName) -> void:
	if name == &"":
		set_cell(coords, -1)
		return
	var tile := _index[name]
	set_cell(coords, tile.source_id, tile.atlas_coordinates, tile.alternative_id)

func get_cell_name(coords: Vector2i) -> StringName:
	var source_id := get_cell_source_id(coords)
	if source_id == -1:
		return &""
	var atlas_coords := get_cell_atlas_coords(coords)
	var alternative_id := get_cell_alternative_tile(coords)
	for key in _index:
		if _index[key].equals(source_id, atlas_coords, alternative_id):
			return key
	return &""

@warning_ignore("shadowed_variable_base_class")
func get_tile_data(name: StringName) -> IndexedTileData:
	return _index[name]

func play_audio(cell: Vector2i, stream: AudioStream) -> void:
	var audio := AudioStreamPlayer2D.new()
	add_child(audio)
	audio.position = map_to_local(cell)
	audio.stream = stream
	audio.play()
	await audio.finished
	audio.queue_free()
