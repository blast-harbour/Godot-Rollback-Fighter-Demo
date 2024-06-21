extends Node
class_name FightManager

"""
Calling all functions in our fighters via the FightManager gives us greater control of the order that
events occur in. This becomes important for eliminating problems like port priority i.e., two players
attacking each other on the same game tick and only one character gets hit.
"""

var round_active : bool = true

func _save_state() -> Dictionary:
	var savestate := {
		round_active = round_active,
		winner_text_visible = $"../GameUI/WinnerText".visible
		}
	return savestate
	
func _load_state(state : Dictionary):
	round_active = state['round_active']
	$"../GameUI/WinnerText".visible = state['winner_text_visible']

func _ready():
	add_to_group("network_sync")

func _network_process(input : Dictionary) -> void:
	for fighter in get_tree().get_nodes_in_group("fighter"):
		if fighter is Fighter:
			fighter.sync_to_physics_engine()
			fighter.grounded_check()
			fighter.start_of_frame_pos_x = fighter.fixed_position_x
			fighter.state_process()
			fighter.face_toward_target_check()
			fighter.cancel_process()
			fighter.movement_process()
			if fighter.hitstop > 0:
				fighter.hitstop -= 1
			
	#We want to make sure the previous block of code has processed on every fighter before continuing!
			
	for fighter in get_tree().get_nodes_in_group("fighter"):
		if fighter is Fighter:
			fighter.pushbox_process()
	for fighter in get_tree().get_nodes_in_group("fighter"):
		if fighter is Fighter:
			fighter.hurtbox_process()
	for projectile in get_tree().get_nodes_in_group("projectile"):
		if projectile is Projectile:
			projectile.projectile_process()
	for fighter in get_tree().get_nodes_in_group("fighter"):
		if fighter is Fighter:
			fighter.hitbox_process()
	for fighter in get_tree().get_nodes_in_group("fighter"):
		if fighter is Fighter:
			fighter.check_hits()
	for fighter in get_tree().get_nodes_in_group("fighter"):
		if fighter is Fighter:
			if fighter.hitboxes_hit.size() > 0:
				fighter.get_hit()
	for projectile in get_tree().get_nodes_in_group("projectile"):
		if projectile is Projectile:
			projectile.projectile_destroy_check_process()
	for projectile in get_tree().get_nodes_in_group("projectile"):
		if projectile is Projectile:
			projectile.projectile_destroy_process()
	if round_active:
		_check_winner()

func _check_winner():
	var number_alive : int = 0
	var guy_alive : Fighter
	for fighter in get_tree().get_nodes_in_group("fighter"):
		if fighter is Fighter:
			if fighter.health > 0:
				guy_alive = fighter
				number_alive += 1
	if number_alive == 1:
		_win(guy_alive)
	if number_alive == 0:
		_draw()
		
func _win(guy_alive : Fighter) -> void:
	$"../GameUI/WinnerText".text = guy_alive.name + " Wins!!!"
	$"../GameUI/WinnerText".visible = true
	round_active = false
	$RestartRoundTimer.start()
	
func _draw() -> void:
	$"../GameUI/WinnerText".text = "Draw......"
	$"../GameUI/WinnerText".visible = true
	round_active = false
	$RestartRoundTimer.start()

func _restart_round() -> void:
	for fighter in get_tree().get_nodes_in_group("fighter"):
		if fighter is Fighter:
			fighter.fixed_position_x = fighter.default_pos_x
			fighter.fixed_position_y = fighter.default_pos_y
			fighter.health = 1000
			fighter.state_transition(fighter.default_state)
			fighter.sync_colliders()
	for child : Node in $"../SpawnParent".get_children():
		SyncManager.despawn(child)
	$"../GameUI/WinnerText".visible = false
	round_active = true

func _on_restart_round_timer_timeout():
	_restart_round()
