extends Node2D

@export var template:PackedScene
var particle_queue:Array[GPUParticles2D]
var queue_size:int = 5
var current:int = 0

func _ready() -> void:
	for i in queue_size:
		var inst = template.instantiate()
		get_tree().root.call_deferred("add_child",inst)
		inst.local_coords = false
		particle_queue.append(inst)

#func spawn():
	#var trg = particle_queue[current]
	#trg.global_position = $RayCast2D.get_collision_point()
	#trg.rotation = 0
	#await get_tree().process_frame
	#trg.emitting = true
	#current = (current+1)%queue_size
#
#func spawn_right():
	#var trg = particle_queue[current]
	#trg.global_position = $RayCast2DRight.get_collision_point()
	#trg.rotation = -PI/2
	#await get_tree().process_frame
	#trg.emitting = true
	#current = (current+1)%queue_size
	
func spawn_normal(dir:Vector2):
	var trg = particle_queue[current]
	$RayCast2D.target_position = dir.normalized() * 50
	trg.global_position = global_position # $RayCast2D.get_collision_point()
	trg.rotation = dir.angle()
	await get_tree().process_frame
	trg.emitting = true
	current = (current+1)%queue_size
