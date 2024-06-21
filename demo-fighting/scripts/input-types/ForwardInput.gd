extends InputType
class_name ForwardInput

func check_valid(input_dict : Dictionary) -> bool:
	var input_condition : bool = false
	if input_dict.has('x_axis'):
		if input_dict['x_axis'] == 1 and fighter.facing_right:
			input_condition = true
		elif input_dict['x_axis'] == -1 and !fighter.facing_right:
			input_condition = true
	if auto_valid:
		input_condition = true
	elif auto_reject:
		input_condition = false
	return input_condition
