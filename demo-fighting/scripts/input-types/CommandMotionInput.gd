extends InputType
class_name CommandMotionInput

"""
The way commmand motions are processed
1. Check which direction the player is facing and choose the appropriate input sequence
2. Duplicate and reverse this sequence, as we will be iterating through our input history in reverse
	to see if it matches the input sequence. All command motions have a 15 frame window to be performed
	since that is the size of our input buffer.
3. While iterating through our input history we look for a matching direction of the next step of the
	input sequence. We ignore duplicate inputs, so holding down multiple frames will not break the loop,
	but the loop will break if an input that is not part of the sequence is read.
4. Once the loop is complete, if all steps of the input sequence were found in order, the command motion
	returns true!
"""

@export var input_sequence_right : Array[Directions]
@export var input_sequence_left : Array[Directions]

enum Directions {
	NONE = 1 << 0,
	UP = 1 << 1,
	DOWN = 1 << 2,
	LEFT = 1 << 3,
	RIGHT = 1 << 4,
	UPLEFT = UP | LEFT,
	UPRIGHT = UP | RIGHT,
	DOWNLEFT = DOWN | LEFT,
	DOWNRIGHT = DOWN | RIGHT
}

func check_valid(input_dict : Dictionary) -> bool:
	var input_condition : bool = false
	var input_sequence : Array[Directions] = input_sequence_right
	if !fighter.facing_right:
		input_sequence = input_sequence_left
	input_sequence = input_sequence.duplicate()
	input_sequence.reverse()
	var history_step : int = fighter.input_history.size() - 1
	var steps_complete : int = 0
	
	while history_step > 0:
		if fighter.input_history.size() >= input_sequence.size():
			if input_sequence[steps_complete] == fighter.input_history[history_step]:
				steps_complete += 1
				if steps_complete == input_sequence.size():
					input_condition = true
					break
			elif steps_complete > 0:
				if fighter.input_history[history_step] != input_sequence[steps_complete - 1]:
					break
			history_step -= 1
		else:
			break
	
	return input_condition
