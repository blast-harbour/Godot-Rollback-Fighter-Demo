extends Sprite2D


func _network_spawn(spawn_data : Dictionary):
	global_position = spawn_data['position']
	$DestroyTimer.start()


func _on_destroy_timer_timeout():
	SyncManager.despawn(self)
