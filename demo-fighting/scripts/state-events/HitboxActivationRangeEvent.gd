extends StateEvent
class_name HitboxActivationRangeEvent

@export var hitbox : Hitbox

func activate_state_event():
	if fighter.current_state_tick == tick_range.x:
		hitbox.activate_hitbox()
	elif fighter.current_state_tick == tick_range.y:
		hitbox.deactivate_hitbox()
