extends InputType
class_name MultiInputType

#This input type returns true if any input type in the array returns true. We use this to
#create lenient alternative inputs

@export var input_types : Array[InputType]

func _ready():
	for child in get_children():
		if child is InputType:
			input_types.append(child)

func check_valid(input_dict : Dictionary) -> bool:
	var any_valid : bool = false
	for input_type in input_types:
		if input_type.check_valid(input_dict):
			any_valid = true
	return any_valid
