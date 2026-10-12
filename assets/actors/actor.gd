class_name Actor
extends RigidBody2D


@export var behavior: ActorBehavior
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label
## Setted by layer
var id: Vector2i = Vector2i.ZERO
var map: Map
var _rand := RandomNumberGenerator.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

enum State {
	PREVIEW,
	ALIVE,
	FINISHED
}

enum FinalState {
	DIED,
	SAVED
}
signal actor_finished(actor: Actor, state: FinalState)
var state := State.PREVIEW

@warning_ignore("shadowed_variable")
func on_simulation_started(map: Map):
	self.map = map
	self.state = State.ALIVE
	self.process_mode = Node.PROCESS_MODE_INHERIT
	self.animated_sprite_2d.play(&"default")
	self._rand.seed = id.x * 32415 ^ id.y * 94023

@warning_ignore("shadowed_variable")
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if self.state != State.ALIVE:
		return

	@warning_ignore("shadowed_variable_base_class")
	var visible := map.get_visible_data(global_position, 2)
	for fire in visible.fire:
		if fire.map_distance <= 0.5:
			finish(FinalState.DIED)
			return
	for exit in visible.exits:
		if exit.map_distance <= 0.5:
			finish(FinalState.SAVED)
			return
	label.visible = visible.fire.size() > 0
	var action := behavior.think(visible, _rand)
	state.apply_central_impulse(action.impulse)
	state.apply_central_force(action.force)



func _dissapear_animation():
	process_mode = Node.PROCESS_MODE_DISABLED
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(), 1.0).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_callback(queue_free)

func finish(final_state: FinalState):
	state = State.FINISHED
	actor_finished.emit(self, final_state)
	_dissapear_animation.call_deferred()
