extends StateEvent
class_name ProjectileSpawnEvent

@export var spawn_point : SGFixedNode2D
@export var projectile : PackedScene = preload("res://demo-fighting/Projectile.tscn")

func activate_state_event():
	var spawn_data := {
		pos_x = spawn_point.get_global_fixed_position().x,
		pos_y = spawn_point.get_global_fixed_position().y,
		fighter = fighter,
		facing_right = fighter.facing_right
	}
	SyncManager.spawn("Projectile", fighter.spawn_parent, projectile, spawn_data)
