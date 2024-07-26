extends CharacterBody2D


@export var apex_curve:Curve 
@export var img:Sprite2D

var SPEED		:float = 400	## Targeted speed
var ACC			:float = 240	## acceleration
var AIRC		:float = 2		## air control divider (the higher the value the less control you have)
var GRA			:float = 40		## gravity acceleration
var TRGGRA		:float = 700 	## Targeted gravity with air drag
var JMP			:float = 800	## Jump velocity
var JMPBUFT		:float = 0.15	## Activate the jump if jump key pressed to early
var JMPRLYGF	:float = 2 		## Jump ended early gravity factor
var APEXT		:float = 0.1	## Apex mode duration
var COYINT		:float = 0.1	## Coyote time interval
var WALLDRAG	:float = 0.5	## Wall Drag Factor
var DSHV		:float = 1500	## Dash velocity

## VISUALS

var SQSHT		:float = 0.2	## Squeeshing time
var SQSHI		:float = 0.8	## Squeeshing intensity




## Coyote
var last_was_on_floor_time:float = 0
var last_was_on_wall_time:float = 0

func in_coyote_interval_floor():
	return wtime(last_was_on_floor_time,COYINT)

func in_coyot_interval_wall():
	return wtime(last_was_on_wall_time,COYINT)

## early_jump
var jump_press_time:float = -1
var jump_ended_early = false

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
		#if in_apex_mode: final_speed*=1+apex_mode_factor_curved*0.1
		return final_speed

var gravity:float:
	get:
		var final_gravity = GRA
		if jump_ended_early:
			final_gravity *= JMPRLYGF # jump_ended_early_gravity_factor
		if in_apex_mode:final_gravity*=1-apex_mode_factor_curved
		return final_gravity



## Time Comparaisons
var time:float:
	get: return Time.get_unix_time_from_system()
func wtime(t,interval):
	return time - t < interval

## Jumps
var in_jump = false
func jump():
	if in_jump: return # avoiding jump buffering overflow
	jump_ended_early = false
	in_jump = true
	apex_reached_time = 0
	jump_press_time = -1
	velocity[1] = -1*JMP

func wall_jump():
	if in_jump: return # avoiding jump buffering overflow
	jump()
	velocity[0] = get_wall_normal()[0]*JMP



## States
# these variable are to know when leaving of entering
var on_floor:bool = false
var on_wall:bool = false
var on_celling:bool = false


var tween_squeesh_inst:Tween # only one instance so it can be retriggered with ease

func tween_squeesh(dir:Vector2,delay:float = 0.1,intensity:float = 0.5):
	var mp = Vector2(abs(cos(dir.angle())),abs(sin(dir.angle())))
	var midscale = Vector2(1+0.4*intensity,1+0.4*intensity) - (mp) * 0.8 * intensity
	var midpos = Vector2(cos(dir.angle()),sin(dir.angle()))*(10*(intensity))
	tween_squeesh_inst = get_tree().create_tween()
	tween_squeesh_inst.tween_property($Node2D/Node2D/Sprite2D, "position", midpos, delay/4)#.set_trans(SQSHT).set_ease(Tween.EASE_OUT)
	tween_squeesh_inst.parallel().tween_property($Node2D/Node2D, "scale", midscale, delay/4)#.set_trans(SQSHT).set_ease(Tween.EASE_OUT)
	tween_squeesh_inst.tween_property($Node2D/Node2D/Sprite2D, "position", Vector2(), delay/2)#.set_trans(SQSHT).set_ease(Tween.EASE_IN)
	tween_squeesh_inst.parallel().tween_property($Node2D/Node2D, "scale", Vector2(1,1), delay/2)#.set_trans(SQSHT).set_ease(Tween.EASE_IN)
	await tween_squeesh_inst.finished


func on_wall_hit():
	in_jump = false
	on_wall = true
	if wtime(jump_press_time,JMPBUFT):
		wall_jump()
	tween_squeesh(-1*get_wall_normal(),SQSHT,SQSHI)
	
func on_wall_leave():
	on_wall = false
	last_was_on_wall_time = time

func when_wall_hit():
	## Wall Drag
	var direction = Input.get_axis("move_left","move_right")
	if direction*get_wall_normal()[0] < 0: 
		velocity[1] *= WALLDRAG
	pass

func when_in_air():
	velocity[1] = move_toward(velocity[1],TRGGRA,gravity)

func on_in_air():
	on_floor=false
	last_was_on_floor_time = time
	
func on_in_ground():
	on_floor=true
	apex_reached=false
	in_jump=false
	if wtime(jump_press_time,JMPBUFT):
		jump()
	tween_squeesh(Vector2.DOWN,SQSHT,SQSHI)

func on_apex_reached():
	apex_reached=true
	apex_reached_time=time

func _physics_process(delta):
	if not is_on_floor():
		when_in_air()
		if on_floor: # when first leaving the floor
			on_in_air()
	elif !on_floor: # when hiting the ground for the first time
		on_in_ground()
	
	if not apex_reached and velocity[1] > 0:
		on_apex_reached()
	
	if is_on_wall():
		when_wall_hit()
		if not on_wall:
			on_wall_hit()
	elif on_wall:
		on_wall_leave()
	
	if is_on_ceiling():
		if not on_celling:
			on_celling = true
			tween_squeesh(Vector2.UP,SQSHT,SQSHI)
	elif on_celling:
		on_celling = false
	
	var direction_x = Input.get_axis("move_left","move_right")
	var direction_y = Input.get_axis("move_up","move_down")
	var direction = Vector2(direction_x,direction_y)
	
	
	if Input.is_action_just_pressed("timeslow"):
		Engine.set_time_scale(0.2)
	if Input.is_action_just_released("timeslow"):
		Engine.set_time_scale(1)
	
	
	if Input.is_action_just_pressed("jump"):
		jump_press_time = time
		if is_on_floor() or in_coyote_interval_floor():
			if is_on_wall() and direction_x:
				wall_jump()
			else:
				jump()
		elif is_on_wall() or in_coyot_interval_wall():
			wall_jump()
	
	if Input.is_action_just_released("jump"):
		if in_jump and velocity[1] < 0:
			jump_ended_early = true
	
	
	#if direction and Input.is_action_just_pressed("dash"):
		#velocity = (direction).normalized()*DSHV
	
	if direction_x:
		if is_on_floor():
			velocity[0] = move_toward(velocity[0], direction_x*speed, ACC)
		else:
			velocity[0] = move_toward(velocity[0], direction_x*speed, ACC/AIRC)
	else:
		if is_on_floor():
			velocity[0] = move_toward(velocity[0], direction_x*speed, ACC)
		else:
			velocity[0] = move_toward(velocity[0], 0, ACC/8)
	
	if is_on_floor():
		$Node2D.rotation = move_toward($Node2D.rotation, (get_floor_normal().rotated(deg_to_rad(90))).angle(),0.05)
	#elif is_on_wall():
		#$Node2D.rotation = move_toward($Node2D.rotation, (get_wall_normal().rotated(deg_to_rad(180))).angle(),0.1)
	else:
		$Node2D.rotation = move_toward($Node2D.rotation, 0,0.1)
	#$Node2D.skew = velocity[0]
	#linear_velocity = Vector2(Input.get_axis("move_left","move_right")*1000,linear_velocity[1])
	
	#$Node2D/Sprite2D.material.get_shader_parameter("r")
	#$Node2D/Sprite2D.get_material().set_shader_parameter("size", 0.0);
	
	move_and_slide()
	
	$Node2D/Node2D/Sprite2D.material.set_shader_parameter("r", (velocity).angle()*-2);
	$Node2D/Node2D/Sprite2D.material.set_shader_parameter("size", abs(clamp(velocity.length()/3000,0,0.5)));
	
