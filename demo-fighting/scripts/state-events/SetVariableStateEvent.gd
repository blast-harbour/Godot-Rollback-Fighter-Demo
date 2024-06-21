extends StateEvent
class_name SetVariableStateEvent

@export var variables_to_change : Dictionary

func activate_state_event():
	for variable in variables_to_change.keys():
		if fighter.get(variable) != null:
			fighter.set(variable, variables_to_change[variable])
