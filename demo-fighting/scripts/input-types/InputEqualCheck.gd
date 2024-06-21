extends InputType
class_name InputEqualCheck

@export var input_name : String
@export var input_value : int

func check_valid(input_dict : Dictionary) -> bool:
	var input_condition : bool = false
	if input_dict.has(input_name):
		if int(input_dict[input_name]) == input_value:
			input_condition = true
	if auto_valid:
		input_condition = true
	elif auto_reject:
		input_condition = false
	return input_condition
