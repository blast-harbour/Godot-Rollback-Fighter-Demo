extends SGArea2D
class_name Hurtbox

var fighter : Fighter

func _ready():
	if owner is Fighter:
		fighter = owner

func hurtbox_process():
	visible = true
	sync_to_physics_engine()

func activate_hurtbox():
	if !owner.active_hurtboxes.has(self):
		owner.active_hurtboxes.append(self)
		visible = true

func deactivate_hurtbox():
	if owner.active_hurtboxes.has(self):
		var index : int = fighter.active_hurtboxes.find(self, 0)
		if index != -1:
			fighter.active_hurtboxes.remove_at(index)
			visible = false
