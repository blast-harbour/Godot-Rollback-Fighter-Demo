extends StateEvent
class_name HurtboxActivationRangeEvent

@export var hurtbox : Hurtbox

func activate_state_event():
	if fighter.current_state_tick == tick_range.x:
		hurtbox.activate_hurtbox()
	elif fighter.current_state_tick == tick_range.y:
		hurtbox.deactivate_hurtbox()
