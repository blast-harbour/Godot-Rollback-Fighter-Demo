extends StateEvent
class_name CallMethodEvent

@export var node : Node
@export var method : String

func _ready():
	if node == null:
		node = fighter

func activate_state_event():
	if node.has_method(method):
		node.call(method)
