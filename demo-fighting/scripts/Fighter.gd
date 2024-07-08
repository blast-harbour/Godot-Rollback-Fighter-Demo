extends SGCharacterBody2D
class_name Fighter

var input_prefix := "player1_"
var spawn_parent : Node
@onready var anim_player : AnimationPlayer = $Visuals/AnimationPlayer
@onready var sprite : Sprite2D = $Visuals/Sprite2D
@onready var pushbox : SGArea2D = $Collision/Pushbox
@export var health_bar : ProgressBar
var default_pos_x : int
var default_pos_y : int
@onready var default_state : FighterState = $States/Idle


#Variables related to state machine flow and input

@onready var current_state : FighterState = $States/Idle
var current_state_tick = 0
var input_dict : Dictionary
var input_history : Array[int]
var available_moves : Array[Move]
var can_do_moves : bool = true
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

#Variables related to movement of the fighter

var speed_x : int = 0
var speed_y : int = 0
var accel_x : int = 0
var accel_y : int = 0

var start_of_frame_pos_x : int #Used in pushbox calculation

#Variables related to other character behaviors

@export var facing_right : bool = true
@export var target_fighter : Fighter
var can_block = false
var can_flip = true
var push_enabled : bool = true
var grounded : bool = true
var move_has_hit : bool = false
var health : int = 1000
var invul : bool = false
var hitstop : int = 0

#Variables related to hitbox/hurtbox interaction

"""
We keep track of which hitboxes/hurtboxes are active by adding them to the active_hitboxes and
active_hurtboxes arrays and then calling process methods only on members of these arrays. We do not
use save/load methods to keep track of the state of the individual hitboxes/hurtboxes because it
very quickly becomes a performance burden when using the rollback addon on large amounts of 
nodes within your scene!!!

Although SGPhysics officially does not fully support non-uniform scaling. I have not had issues
with scaling box colliders and collision polygons, but it is possible stuff could get wonky when
using different collision shapes for your hitboxes. I flip my characters by scaling them on the x axis!
"""

var active_hitboxes : Array[Hitbox]
var active_hurtboxes : Array[Hurtbox]
var hit_tracker : Array[bool] #Each bool in this array corresponds to an index of the hitbox array

var hitboxes_collided : Array[Hitbox] #List of enemy hitboxes made contact with on one tick
var hitboxes_hit : Array[Hitbox] #List of enemy hitboxes which passed all checks to hit

enum BlockType {NONE, HIGH, LOW}

#Variables related to visuals that do not get saved/loaded into state
var current_anim_tick : int = 0
@onready var current_anim : String = current_state.anim_name

func _ready():
	add_to_group("network_sync")
	add_to_group("fighter")
	anim_player.speed_scale = 0.0
	$Collision/Hurtboxes/StandHurtbox.activate_hurtbox()
	default_pos_x = fixed_position_x
	default_pos_y = fixed_position_y

func _get_local_input() -> Dictionary:
	
	var input := {}

	if Input.is_action_just_pressed(input_prefix + "punch"):
		input["punch"] = true
	if Input.is_action_just_pressed(input_prefix + "kick"):
		input["kick"] = true
		
	var x_axis : int = 0
	if Input.is_action_pressed(input_prefix + "left"):
		x_axis -= 1
	if Input.is_action_pressed(input_prefix + "right"):
		x_axis += 1
	input['x_axis'] = x_axis
	
	var y_axis : int = 0
	if Input.is_action_pressed(input_prefix + "down"):
		y_axis -= 1
	if Input.is_action_pressed(input_prefix + "up"):
		y_axis += 1
	input['y_axis'] = y_axis
	
	return input
	
func _save_state() -> Dictionary:
	var active_hitboxes_paths : Array[NodePath]
	for hitbox : Hitbox in active_hitboxes:
		active_hitboxes_paths.append(hitbox.get_path())
	var active_hurtboxes_paths : Array[NodePath]
	for hurtbox : Hurtbox in active_hurtboxes:
		active_hurtboxes_paths.append(hurtbox.get_path()) 
		
	var save_state := {
		fixed_position_x = fixed_position_x,
		fixed_position_y = fixed_position_y,
		fixed_scale_x = fixed_scale_x,
		current_state = current_state.get_path(),
		current_state_tick = current_state_tick,
		input_history = input_history.duplicate(true),
		can_do_moves = can_do_moves,
		speed_x = speed_x,
		speed_y = speed_y,
		accel_x = accel_x,
		accel_y = accel_y,
		start_of_frame_pos_x = start_of_frame_pos_x,
		push_enabled = push_enabled,
		can_block = can_block,
		can_flip = can_flip,
		facing_right = facing_right,
		grounded = grounded,
		move_has_hit = move_has_hit,
		health = health,
		invul = invul,
		hitstop = hitstop,
		active_hitboxes = active_hitboxes_paths.duplicate(),
		active_hurtboxes = active_hurtboxes_paths.duplicate(),
		hit_tracker = hit_tracker.duplicate(true)
	}
	
	return save_state

func _load_state(state : Dictionary) -> void:
	fixed_position_x = state['fixed_position_x']
	fixed_position_y = state['fixed_position_y']
	fixed_scale_x = state['fixed_scale_x']
	current_state = get_node(state['current_state'])
	current_state_tick = state['current_state_tick']
	input_history = state['input_history'].duplicate(true)
	can_do_moves = state['can_do_moves']
	speed_x = state['speed_x']
	speed_y = state['speed_y']
	accel_x = state['accel_x']
	accel_y = state['accel_y']
	start_of_frame_pos_x = state['start_of_frame_pos_x']
	push_enabled = state['push_enabled']
	can_block = state['can_block']
	can_flip = state['can_flip']
	facing_right = state['facing_right']
	grounded = state['grounded']
	move_has_hit = state['move_has_hit']
	health = state['health']
	invul = state['invul']
	hitstop = state['hitstop']
	
	active_hitboxes.clear()
	for path : NodePath in state['active_hitboxes']:
		active_hitboxes.append(get_node(path))
		
	active_hurtboxes.clear()
	for path : NodePath in state['active_hurtboxes']:
		active_hurtboxes.append(get_node(path))
	
	hit_tracker = state['hit_tracker'].duplicate(true)
	sync_to_physics_engine()
	pushbox.sync_to_physics_engine()
	$Collision/GroundChecker.sync_to_physics_engine()
	for hitbox : Hitbox in active_hitboxes:
		hitbox.sync_to_physics_engine()
	for hurtbox : Hurtbox in active_hurtboxes:
		hurtbox.sync_to_physics_engine()

#Before the FighterManager executes anything input data is gathered on each player and stored in the game state.
func _network_preprocess(input : Dictionary) -> void:
	input_dict = input
	input_process()
	available_moves.clear()
	hitboxes_collided.clear()
	hitboxes_hit.clear()
	sync_colliders()
	
func input_process():
	var current_input_int : int = 0
	#Using bit shifting to keep track of input history for our command buffer
	var y_axis = input_dict.get("y_axis", 0)
	var x_axis = input_dict.get("x_axis", 0)
	if y_axis == -1:
		current_input_int = current_input_int ^ Directions.DOWN
	elif y_axis == 1:
		current_input_int = current_input_int ^ Directions.UP
	if x_axis == -1:
		current_input_int = current_input_int ^ Directions.LEFT
	elif x_axis == 1:
		current_input_int = current_input_int ^ Directions.RIGHT
	if y_axis == 0 and x_axis == 0:
		current_input_int = Directions.NONE
	input_history.append(current_input_int)
	if input_history.size() > 15:
		input_history.remove_at(0)
	
func state_process():
	if hitstop <= 0:
		for state_event : StateEvent in current_state.state_events:
			if current_state_tick >= state_event.tick_range.x and current_state_tick <= state_event.tick_range.y:
				state_event.activate_state_event()
		"""
		We do not update the animation player directly yet! We update values that decide what the animation
		player does in the _process() method after all rollback logic is finished, so as to not run the
		animation player methods each rollback frame. This can be very costly if you have a lot of data
		in your animations, so we only want to do this once.
		"""
		current_anim_tick = current_state_tick
		current_anim = current_state.anim_name
		
		current_state_tick += 1
		if current_state.state_loop == true and current_state_tick > current_state.state_length:
			current_state_tick = 0
		elif current_state.state_loop == false and current_state_tick > current_state.state_length:
			current_state_tick = current_state.state_length
		
func state_transition(new_state : FighterState):
	for state_event : StateEvent in current_state.state_exit_events:
		state_event.activate_state_event()
	current_state_tick = 0
	reset_vars()
	current_state = new_state
	if !current_state.preserve_momentum:
		speed_x = 0
		speed_y = 0
		accel_x = 0
		accel_y = 0
	for state_event : StateEvent in current_state.state_enter_events:
		state_event.activate_state_event()
	state_process()

func reset_vars():
	#When a state transition occurs this method resets several variables to their default state
	anim_player.play("RESET")
	anim_player.advance(0.0)
	available_moves.clear()
	can_block = false
	can_flip = true
	push_enabled = true
	move_has_hit = false
	deactivate_hitboxes()
	deactivate_hurtboxes()
	$Collision/Hurtboxes/StandHurtbox.activate_hurtbox()

func deactivate_hitboxes():
	var past_active_hitboxes : Array[Hitbox] = active_hitboxes.duplicate()
	for hitbox : Hitbox in past_active_hitboxes:
		hitbox.deactivate_hitbox()
		
func deactivate_hurtboxes():
	var past_active_hurtboxes : Array[Hurtbox] = active_hurtboxes.duplicate()
	for hurtbox : Hurtbox in past_active_hurtboxes:
		hurtbox.deactivate_hurtbox()

func movement_process():
	if hitstop <= 0:
		speed_x += accel_x
		speed_y += accel_y
		var side_multiplier : int = 1
		if facing_right == false:
			side_multiplier = -1
		velocity = SGFixed.vector2(speed_x * side_multiplier, speed_y)
		move_and_slide()

func pushbox_process():
	#Pushbox process checks if any players are overlapped, checks which player was on which side
	#at the beginning of the tick, averages their positions, and then moves them to their correct side
	pushbox.sync_to_physics_engine()
	if push_enabled:
		for area : SGArea2D in pushbox.get_overlapping_areas():
			if area.is_in_group("pushbox"):
				var enemy = area.owner
				if enemy is Fighter:
					if enemy.push_enabled:
						var left_side_fighter : Fighter
						var right_side_fighter : Fighter
						if start_of_frame_pos_x < enemy.start_of_frame_pos_x:
							left_side_fighter = self
							right_side_fighter = enemy
						else:
							left_side_fighter = enemy
							right_side_fighter = self
						var average_pos_x = SGFixed.div((fixed_position_x + enemy.fixed_position_x), 131072) #Average position gotten by adding the two fighter positions and dividing by two
						left_side_fighter.fixed_position_x = average_pos_x - 1141752 #This number is based on the extents of the character pushbox
						right_side_fighter.fixed_position_x = average_pos_x + 1141752
						left_side_fighter.sync_to_physics_engine()
						right_side_fighter.sync_to_physics_engine()
	else:
		sync_to_physics_engine()

func _render_on_top():
	for fighter : Fighter in get_tree().get_nodes_in_group('fighter'):
		fighter.sprite.z_index = -1
	sprite.z_index = 0

func face_toward_target_check():
	if can_flip:
		if target_fighter.fixed_position_x < fixed_position_x and facing_right:
			flip()
		elif target_fighter.fixed_position_x >= fixed_position_x and !facing_right:
			flip()
	sync_to_physics_engine()

func flip():
	facing_right = !facing_right
	fixed_scale_x *= -1

func grounded_check():
	$Collision/GroundChecker.sync_to_physics_engine()
	if $Collision/GroundChecker.get_overlapping_body_count() > 0 and speed_y >= 0:
		grounded = true
	else:
		grounded = false

func cancel_process():
	for move : Move in available_moves:
		var all_inputs_valid = true
		for input_type : InputType in move.input_conditions:
			if !input_type.check_valid(input_dict):
				all_inputs_valid = false
		if all_inputs_valid:
			state_transition(move.fighter_state)
			_render_on_top()
			if move.breaks:
				#Moves like attacks are marked to break this loop so as to not transition into another move which also has its input requirements met.
				#This means that moves with a lower index have input priority as they are processed in the cancel check before the other moves.
				break
				
func sync_colliders():
	sync_to_physics_engine()
	pushbox.sync_to_physics_engine()
	$Collision/GroundChecker.sync_to_physics_engine()
	for hitbox : Hitbox in active_hitboxes:
		hitbox.sync_to_physics_engine()
	for hurtbox : Hurtbox in active_hurtboxes:
		hurtbox.sync_to_physics_engine()
				
func hurtbox_process():
	for index : int in active_hurtboxes.size():
		active_hurtboxes[index].hurtbox_process()
		
func hitbox_process():
	for index : int in active_hitboxes.size():
		active_hitboxes[index].hitbox_process()

func check_hits():
	#After gathering each of the hitboxes collided with we check if we can count it as having hit
	for hitbox : Hitbox in hitboxes_collided:
		var hitbox_index : int = hitbox.owner.active_hitboxes.find(hitbox, 0)
		if hitbox.owner.active_hitboxes.has(hitbox) and !hitbox.owner.hit_tracker[hitbox_index] and !invul:
			hitboxes_hit.append(hitbox)
	hitboxes_collided.clear()

func get_hit():
	"""
	This method gets called on all fighters after every fighter in the scene has
	an up to date hitboxes_collided array. If you wanted to have more complex
	same-frame hit interactions like sword clashes, throw techs, or hitbox priority,
	do it here!
	"""
	#We check if the player is able to block, and if so, whether they were blocking high or low.
	var block_type : BlockType = BlockType.NONE
	if $Inputs/BackwardInput.check_valid(input_dict) and can_block:
		block_type = BlockType.HIGH
		if $Inputs/Y_Down.check_valid(input_dict):
			block_type = BlockType.LOW
			
	var blocked_all_hits : bool = true #INNOCENT UNTIL PROVEN GUILTY!!!!!
	
	#lets go gambling
	if block_type == BlockType.NONE:
			blocked_all_hits = false #aw dangit
	for hitbox : Hitbox in hitboxes_hit:
		if hitbox.hit_level == hitbox.HitLevel.UNBLOCKABLE:
			blocked_all_hits = false #aw dangit
		elif hitbox.hit_level == hitbox.HitLevel.LOW and block_type == BlockType.HIGH:
			blocked_all_hits = false #aw dangit
		elif hitbox.hit_level == hitbox.HitLevel.OVERHEAD and block_type == BlockType.LOW:
			blocked_all_hits = false #aw dangit
		
	var final_hit_behavior : HitBehavior #determining which hit behavior to apply after various checks
	var enemy : Fighter
	var final_hitbox : Hitbox
	for hitbox : Hitbox in hitboxes_hit:
		hitbox.owner.move_has_hit = true
		enemy = hitbox.fighter
		var hitbox_index : int = enemy.active_hitboxes.find(hitbox, 0)
		if hitbox_index != -1:
			hitbox.owner.hit_tracker[hitbox_index] = true
		if !blocked_all_hits:
			final_hit_behavior = hitbox.hit_behavior
			final_hitbox = hitbox
		else:
			final_hit_behavior = hitbox.block_behavior
			final_hitbox = hitbox
		if !grounded:
			final_hit_behavior = hitbox.air_hit_behavior
			final_hitbox = hitbox
		
	#After the final hit behavior has been determined, we apply changes to the fighter
			
	health -= final_hit_behavior.damage
	if health > 0:
		state_transition($States.find_child(final_hit_behavior.hit_state))
	else:
		state_transition($States/Knockout)
		
	for variable in final_hit_behavior.new_variables.keys():
		set(variable, final_hit_behavior.new_variables[variable])
		
	var side_multiplier : int = 1
	if facing_right == false:
		side_multiplier = -1
	enemy.fixed_position_x += final_hit_behavior.self_knockback * side_multiplier
	enemy.sync_to_physics_engine()
	if final_hitbox.owner == enemy:
		enemy.hitstop = final_hit_behavior.hitstop
	hitstop = final_hit_behavior.hitstop
	SyncManager.spawn("HitEffect", spawn_parent, final_hit_behavior.hit_effect, {position = final_hitbox.global_position})
	SyncManager.play_sound(name + "Sound", final_hit_behavior.sound)
	hitboxes_hit.clear()

#Changing visuals that aren't tied to any game state logic in the _process()
#method can be faster since it isn't being called multiple times per rollback tick

func _process(delta):
	anim_player.play(current_anim)
	anim_player.seek(float(current_anim_tick) / 60.0)
	anim_player.advance(0)
	if health_bar != null:
		if health > 0:
			health_bar.value = health
		else:
			health_bar.value = 0
