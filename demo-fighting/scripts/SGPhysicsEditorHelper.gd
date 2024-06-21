@tool
extends Node
class_name SGPhysicsEditorHelper

@export var node : SGFixedNode2D

"""
This script has no in game use! It is a simple editor tool to make working with
SGPhysics easier by converting an object's position to its fixed position.
"""

func _process(delta) -> void:
	if node != null:
		var new_pos_x = node.position.x * 65536
		var new_pos_y = node.position.y * 65536
		node.fixed_position_x = new_pos_x
		node.fixed_position_y = new_pos_y
