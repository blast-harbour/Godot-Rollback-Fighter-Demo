extends StateEvent
class_name ConditionEvent

@export var node : Node
@export var variable_to_check : String
@export var value : bool
@export var success_event : StateEvent

func activate_state_event():
	var condition_true : bool = false
	if node.get(variable_to_check) == value:
		condition_true = true
	if condition_true:
		success_event.activate_state_event()
