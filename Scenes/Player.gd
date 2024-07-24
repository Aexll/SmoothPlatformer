extends CharacterBody2D


@export var apex_curve:Curve 
@export var img:Sprite2D

var SPEED	:float = 400	## Targeted speed
var ACC		:float = 240	## acceleration
var AIRC	:float = 2		## air control divider (the higher the value the less control you have)
var GRA		:float = 40		## gravity acceleration
var TRGGRA	:float = 700 	## Targeted gravity with air drag
var JMP		:float = -800	## Jump velocity
var JMPBUFT	:float = 0.15	## Activate the jump if jump key pressed to early
var APEXT	:float = 0.1	## Apex mode duration
var COYINT	:float = 0.1	## Coyote time interval


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#$Node2D.skew = velocity[0]/(SPEED*4)
	pass


## Coyote


var was_on_floor:bool = false
var last_was_on_floor_time:float = 0
var last_was_on_wall_time:float = 0

func in_coyote_interval():
	return time - last_was_on_floor_time < 0.1

func in_coyot_interval_wall():
	return wtime(last_was_on_wall_time,0.1)



## early_jump
var jump_press_time:float = -1


## early_end_jump
var jump_ended_early = false
var jump_ended_early_gravity_factor:float = 2


## apex
var apex_mode_time:float = APEXT
var apex_reached:bool = false
var apex_reached_time:float = 0
var in_apex_mode:bool:
	get: return apex_reached and wtime(apex_reached_time,apex_mode_time)
var apex_mode_factor:float:
	get: return ((time-apex_reached_time)/apex_mode_time)
var apex_mode_factor_curved:float:
	get: return apex_curve.sample(apex_mode_factor)


var speed:float:
	get:
		var final_speed = SPEED
		#if in_apex_mode: final_speed*=1+apex_mode_factor_curved*0.5
		return final_speed

var gravity:float:
	get:
		var final_gravity = GRA
		if jump_ended_early:
			final_gravity *= jump_ended_early_gravity_factor
		if in_apex_mode:final_gravity*=1-apex_mode_factor_curved
		return final_gravity



## Jump
var in_jump = false
func jump():
	jump_ended_early = false
	in_jump = true
	velocity[1] = JMP

## Wall
var on_wall:bool = false


## Time Comparaisons
var time:float:
	get: return Time.get_unix_time_from_system()
func wtime(t,interval):
	return time - t < interval


func on_wall_hit():
	on_wall = true
	
func on_wall_leave():
	on_wall = false
	last_was_on_wall_time = time

func when_wall_hit():
	var direction = Input.get_axis("move_left","move_right")
	if direction*get_wall_normal()[0] < 0:
		velocity[1] *= 0.5
	pass

func when_in_air():
	#velocity[1] = clamp(velocity[1]+gravity, -800, 800)
	velocity[1] = move_toward(velocity[1],TRGGRA,gravity)

func on_in_air():
	was_on_floor=false
	last_was_on_floor_time = time
	
func on_in_ground():
	was_on_floor=true
	apex_reached=false
	in_jump=false
	if wtime(jump_press_time,JMPBUFT):
		jump()
	$AnimationPlayer.play("hit_down")

func on_apex_reached():
	apex_reached=true
	apex_reached_time=time

func _physics_process(delta):
	if not is_on_floor():
		when_in_air()
		if was_on_floor: # when first leaving the floor
			on_in_air()
	elif !was_on_floor: # when hiting the ground for the first time
		on_in_ground()
	
	if not apex_reached and velocity[1] > 0:
		on_apex_reached()
	
	if is_on_wall():
		when_wall_hit()
		if not on_wall:
			on_wall_hit()
	elif on_wall:
		on_wall_leave()
	
	if Input.is_action_just_pressed("jump"):
		jump_press_time = time
		if is_on_floor() or in_coyote_interval():
			jump()
		if on_wall or in_coyot_interval_wall():
			jump()
			velocity[0] = get_wall_normal()[0]*JMP*-1
	
	if Input.is_action_just_released("jump"):
		if in_jump and velocity[1] < 0:
			jump_ended_early = true
	
	var direction = Input.get_axis("move_left","move_right")
	if direction:
		if is_on_floor():
			velocity[0] = move_toward(velocity[0], direction*speed, ACC)
		else:
			velocity[0] = move_toward(velocity[0], direction*speed, ACC/AIRC)
	else:
		if is_on_floor():
			velocity[0] = move_toward(velocity[0], direction*speed, ACC)
		else:
			velocity[0] = move_toward(velocity[0], 0, ACC/8)
	
	if is_on_floor():
		$Node2D.rotation = move_toward($Node2D.rotation, (get_floor_normal().rotated(deg_to_rad(90))).angle(),0.1)
	#elif is_on_wall():
		#$Node2D.rotation = move_toward($Node2D.rotation, (get_wall_normal().rotated(deg_to_rad(180))).angle(),0.1)
	else:
		$Node2D.rotation = move_toward($Node2D.rotation, 0,0.1)
	#$Node2D.skew = velocity[0]
	#linear_velocity = Vector2(Input.get_axis("move_left","move_right")*1000,linear_velocity[1])
	
	#$Node2D/Sprite2D.material.get_shader_parameter("r")
	$Node2D/Sprite2D.material.set_shader_parameter("r", (velocity).angle()*-2);
	$Node2D/Sprite2D.material.set_shader_parameter("size", abs(clamp(velocity.length()/5000,0,0.5)));
	#$Node2D/Sprite2D.get_material().set_shader_parameter("size", 0.0);
	
	move_and_slide()
