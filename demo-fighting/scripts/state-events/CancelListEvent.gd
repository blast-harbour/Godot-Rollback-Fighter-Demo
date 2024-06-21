extends StateEvent
class_name CancelListEvent

@export var available_moves : Array[Move]
@export var cancel_on_hit : bool = false

func activate_state_event():
	if cancel_on_hit and fighter.move_has_hit:
		fighter.available_moves.append_array(available_moves)
	elif !cancel_on_hit:
		fighter.available_moves.append_array(available_moves)

