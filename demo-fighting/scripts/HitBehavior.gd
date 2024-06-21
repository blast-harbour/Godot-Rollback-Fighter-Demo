extends Resource
class_name HitBehavior

@export var damage : int = 50
@export var hit_state : String = "Hitstun"
@export var new_variables : Dictionary
@export var self_knockback : int = 655360 * 2
@export var hitstop : int = 5
@export var sound : AudioStream = preload("res://demo-fighting/assets/ht02.wav")
@export var hit_effect : PackedScene = preload("res://demo-fighting/hit_effect.tscn")
