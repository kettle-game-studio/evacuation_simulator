class_name ActorsLayer
extends TileMapLayerIndexed
var saved_actors: Dictionary[Vector2i, bool] = {}
var died_actors: Dictionary[Vector2i, bool] = {}
@export var exit_sound: AudioStream
@export var die_sound: AudioStream
signal actors_changed(saved: int, died: int, total: int, state: Actor.FinalState)

func on_simulation_started(_map: Map):
	saved_actors.clear()
	died_actors.clear()

func _init() -> void:
	super._init()
	child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(node: Node):
	if node is Actor:
		node.id = local_to_map(node.position)
		node.actor_finished.connect(_on_actor_finished)

func _on_actor_finished(actor: Actor, state: Actor.FinalState):
	var pos := local_to_map(actor.position)
	if state == Actor.FinalState.SAVED:
		saved_actors[actor.id] = true
		play_audio(pos, exit_sound)
	elif state == Actor.FinalState.DIED:
		died_actors[actor.id] = true
		play_audio(pos, die_sound)
	else:
		assert(false, "Unkown actor final state %d" % state)
	actors_changed.emit(
		saved_actors.size(),
		died_actors.size(),
		get_used_cells().size(),
		state,
	)
