extends SGCharacterBody2D
class_name Projectile

var fighter : Fighter
var active_hitboxes : Array[Hitbox]
var hit_tracker : Array[bool]
var facing_right : bool
var move_has_hit : bool = false
var queue_destroy : bool = false
@export var speed_x : int
@export var speed_y : int
@export var lifetime : int = 60
@export var destroy_effect : PackedScene = preload("res://demo-fighting/projectile_destroy_effect.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group('network_sync')
	add_to_group('projectile')

func _save_state() -> Dictionary:
	var active_hitboxes_paths : Array[NodePath]
	for hitbox : Hitbox in active_hitboxes:
		active_hitboxes_paths.append(hitbox.get_path())
	
	var save_state := {
		fixed_position_x = fixed_position_x,
		fixed_position_y = fixed_position_y,
		active_hitboxes = active_hitboxes_paths.duplicate(),
		hit_tracker = hit_tracker.duplicate(true),
		facing_right = facing_right,
		lifetime = lifetime,
		move_has_hit = move_has_hit,
		queue_destroy = queue_destroy
	}
	return save_state

func _load_state(state : Dictionary) -> void:
	fixed_position_x = state['fixed_position_x']
	fixed_position_y = state['fixed_position_y']
	hit_tracker = state['hit_tracker'].duplicate(true)
	facing_right = state['facing_right']
	lifetime = state['lifetime']
	move_has_hit = state['move_has_hit']
	queue_destroy = state['queue_destroy']
	sync_to_physics_engine()
	
	active_hitboxes.clear()
	for path : NodePath in state['active_hitboxes']:
		active_hitboxes.append(get_node(path))
	for hitbox : Hitbox in active_hitboxes:
		hitbox.sync_to_physics_engine()

func _network_spawn(spawn_data : Dictionary):
	fixed_position_x = spawn_data['pos_x']
	fixed_position_y = spawn_data['pos_y']
	fighter = spawn_data['fighter']
	facing_right = spawn_data['facing_right']
	$Hitbox.fighter = fighter
	$Hitbox.activate_hitbox()
	sync_to_physics_engine()

func _movement_process():
	var side_multiplier : int = 1
	if !facing_right:
		side_multiplier = -1
	velocity.x = speed_x * side_multiplier
	velocity.y = speed_y
	move_and_slide()
	sync_to_physics_engine()

func _lifetime_process():
	lifetime -= 1
	if lifetime <= 0:
		_destroy_projectile()

func _hitbox_process():
	for index : int in active_hitboxes.size():
		active_hitboxes[index].hitbox_process()

func projectile_process():
	_lifetime_process()
	_movement_process()
	_hitbox_process()
	
func projectile_destroy_check_process():
	for body in $Hitbox.get_overlapping_bodies():
		if body is Projectile and body != self:
			queue_destroy = true
	if move_has_hit:
		queue_destroy = true
	
func projectile_destroy_process():
	if queue_destroy:
		_destroy_projectile()
	
func _destroy_projectile():
	SyncManager.spawn("DestroyEffect", fighter.spawn_parent, destroy_effect, {position = global_position})
	SyncManager.despawn(self)
