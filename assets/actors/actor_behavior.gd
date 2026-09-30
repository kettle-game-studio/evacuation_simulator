@abstract
class_name ActorBehavior
extends Resource

class Action:
	extends RefCounted
	var impulse := Vector2.ZERO
	var force := Vector2.ZERO


@abstract func think(visible_data: VisibleData, rand: RandomNumberGenerator) -> Action
