class_name ActorSimpleImpulseBehavior
extends ActorBehavior

func think(visible_data: VisibleData, rand: RandomNumberGenerator) -> Action:
	var action := Action.new()
	action.impulse = Vector2(rand.randf()-0.5, rand.randf()-0.5).normalized()
	for fire in visible_data.fire:
		action.impulse += fire.global_position.direction_to(visible_data.global_position)
	for exit in visible_data.exits:
		action.impulse += visible_data.global_position.direction_to(exit.global_position)
	for arrow in visible_data.arrows:
		action.impulse += arrow.direction
	return action
