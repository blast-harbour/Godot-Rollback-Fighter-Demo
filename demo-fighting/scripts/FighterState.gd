extends Node
class_name FighterState

"""
The FighterState is part of a simple implementation of a node-based state machine. It acts as a data
container for fighter state-related information.
"""

@export var anim_name : String
@export var state_length : int
@export var state_loop : bool
@export var preserve_momentum : bool = false
var fighter : Fighter
var state_events : Array[StateEvent]
@export var state_enter_events : Array[StateEvent]
@export var state_exit_events : Array[StateEvent]

func _ready():
	if owner is Fighter:
		fighter = owner
	for child in get_children():
		if child is StateEvent:
			state_events.append(child)
			
	
