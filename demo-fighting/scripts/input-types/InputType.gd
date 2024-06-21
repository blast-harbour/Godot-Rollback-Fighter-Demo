extends Node
class_name InputType

#A base class for all command inputs

@onready var fighter : Fighter = owner
@export var auto_valid : bool = false
@export var auto_reject : bool = false

func check_valid(input_dict : Dictionary) -> bool:
	return true
