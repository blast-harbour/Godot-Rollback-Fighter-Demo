extends Node
class_name StateEvent

@export var tick_range : Vector2i
var fighter : Fighter

func _ready():
	if owner is Fighter:
		fighter = owner

func activate_state_event():
	pass
