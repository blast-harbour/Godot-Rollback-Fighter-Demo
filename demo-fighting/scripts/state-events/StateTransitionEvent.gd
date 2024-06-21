extends StateEvent
class_name StateTransitionEvent

@export var new_state : FighterState

func activate_state_event():
	fighter.state_transition(new_state)
