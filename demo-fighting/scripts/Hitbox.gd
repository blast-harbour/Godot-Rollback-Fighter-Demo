extends SGArea2D
class_name Hitbox

var fighter : Fighter

enum HitLevel {MID, LOW, OVERHEAD, UNBLOCKABLE}

@export var hit_level : HitLevel
@export var hit_behavior : HitBehavior
@export var air_hit_behavior : HitBehavior
@export var block_behavior : HitBehavior

func _ready():
	if owner is Fighter:
		fighter = owner

func hitbox_process():
	visible = true
	sync_to_physics_engine()
	for area : SGArea2D in get_overlapping_areas():
		if area is Hurtbox:
			var enemy = area.owner
			if enemy != fighter and enemy is Fighter and enemy.active_hurtboxes.has(area):
				var index : int = owner.active_hitboxes.find(self, 0)
				if !owner.hit_tracker[index]:
					enemy.hitboxes_collided.append(self)

func activate_hitbox():
	if !owner.active_hitboxes.has(self):
		owner.active_hitboxes.append(self)
		owner.hit_tracker.append(false)
		visible = true

func deactivate_hitbox():
	if owner.active_hitboxes.has(self):
		var index : int = fighter.active_hitboxes.find(self, 0)
		if index != -1:
			fighter.active_hitboxes.remove_at(index)
			fighter.hit_tracker.remove_at(index)
			visible = false
