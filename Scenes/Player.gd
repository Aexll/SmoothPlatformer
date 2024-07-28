extends CharacterBody2D


@export var apex_curve:Curve 
#@export var img:Sprite2D
@onready var visual:Polygon2D = $Node2D/Node2D/Polygon2D

var SPEED		:float = 400	## Targeted speed
var ACC			:float = 250	## acceleration
var AIRC		:float = 0.5	## air control divider (the higher the value the less control you have)
var GRA			:float = 40		## gravity acceleration
var TRGGRA		:float = 700 	## Targeted gravity with air drag
var JMP			:float = 800	## Jump velocity
var JMPBUFT		:float = 0.15	## Activate the jump if jump key pressed to early
var JMPRLYGF	:float = 2 		## Jump ended early gravity factor
var APEXT		:float = 0.1	## Apex mode duration
var COYINT		:float = 0.1	## Coyote time interval
var WALLDRAG	:float = 0.5	## Wall Drag Factor
var DSHV		:float = 1500	## Dash velocity
var APXVV		:float = 40		## Apex vertical velocity switch
var APXGF		:float = 0.90	## Apex gravity factor

## VISUALS

var SQSHT		:float = 0.2	## Squeeshing time
var SQSHI		:float = 0.8	## Squeeshing intensity
var DFRMSZ		:float = 1		## Defrome size (deformation from velocity)
var DFRMMX		:float = 0.5	## Defrome maximum



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
var at_apex:bool = false
var apex_factor:float: ## when in apex mode, 1 when at apex top, if at down
	get: return 1-(clamp(abs(velocity[1])/APXVV,0,1))


var speed:float:
	get:
		var final_speed = SPEED
		return final_speed

var air_control:float:
	get:
		var final_ac = AIRC
		if at_apex: final_ac *= 1+apex_factor*5
		return final_ac

var gravity:float:
	get:
		var final_gravity = GRA
		if jump_ended_early:
			final_gravity *= JMPRLYGF # jump_ended_early_gravity_factor
		#if in_apex_mode:final_gravity*=1-apex_mode_factor_curved
		if at_apex:final_gravity*=1 - apex_factor*APXGF
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
	if tween_squeesh_inst: tween_reset()
	jump_ended_early = false
	in_jump = true
	#apex_reached_time = 0
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
	if tween_squeesh_inst: tween_squeesh_inst.stop()
	var mp = Vector2(abs(cos(dir.angle())),abs(sin(dir.angle())))
	var midscale = Vector2(1+0.4*intensity,1+0.4*intensity) - (mp) * 0.8 * intensity
	var midpos = Vector2(cos(dir.angle()),sin(dir.angle()))*10*intensity
	tween_squeesh_inst = get_tree().create_tween()
	tween_squeesh_inst.tween_property(visual, "position", midpos, delay/4)#.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween_squeesh_inst.parallel().tween_property($Node2D/Node2D, "scale", midscale, delay/4)#.set_trans(SQSHT).set_ease(Tween.EASE_OUT)
	tween_squeesh_inst.tween_property(visual, "position", Vector2(), delay/2)#.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween_squeesh_inst.parallel().tween_property($Node2D/Node2D, "scale", Vector2(1,1), delay/2)#.set_trans(SQSHT).set_ease(Tween.EASE_IN)
	await tween_squeesh_inst.finished

func tween_reset():
	tween_squeesh_inst.stop()
	tween_squeesh_inst = get_tree().create_tween()
	tween_squeesh_inst.tween_property(visual, "position", Vector2(), 0.05)#.set_trans(SQSHT).set_ease(Tween.EASE_IN)
	tween_squeesh_inst.parallel().tween_property($Node2D/Node2D, "scale", Vector2(1,1), 0.05)#.set_trans(SQSHT).set_ease(Tween.EASE_IN)
	await tween_squeesh_inst.finished

func on_wall_enter():
	in_jump = false
	on_wall = true
	if wtime(jump_press_time,JMPBUFT):
		wall_jump()
	tween_squeesh(-1*get_wall_normal(),SQSHT,SQSHI)
	
func on_wall_leave():
	on_wall = false
	last_was_on_wall_time = time

func when_on_wall():
	## Wall Drag
	var direction = Input.get_axis("move_left","move_right")
	if direction*get_wall_normal()[0] < 0: 
		velocity[1] *= WALLDRAG
	pass



func on_floor_enter():
	on_floor=true
	#apex_reached=false
	in_jump=false
	if wtime(jump_press_time,JMPBUFT):
		jump()
	tween_squeesh(Vector2.DOWN,SQSHT,SQSHI)

func on_floor_leave():
	on_floor=false
	last_was_on_floor_time = time

func when_on_floor():
	pass


func _physics_process(delta):
	
	## FLOOR
	if is_on_floor():
		when_on_floor()
		if not on_floor: on_floor_enter()
	elif on_floor:
		on_floor_leave()
	
	## WALL
	if is_on_wall():
		when_on_wall()
		if not on_wall: on_wall_enter()
	elif on_wall:
		on_wall_leave()

	## CELING
	if is_on_ceiling():
		if not on_celling:
			on_celling = true
			tween_squeesh(Vector2.UP,SQSHT,SQSHI)
	elif on_celling:
		on_celling = false
	
	## GRAVITY
	if not on_floor:
		velocity[1] = move_toward(velocity[1],TRGGRA,gravity)


	## APEX
	at_apex = abs(velocity[1]) < APXVV
	
	
	## DIRECTION
	var direction_x = Input.get_axis("move_left","move_right")
	var direction_y = Input.get_axis("move_up","move_down")
	var direction = Vector2(direction_x,direction_y)
	
	## TIMESCALE
	if Input.is_action_just_pressed("timeslow"):
		Engine.set_time_scale(0.2)
	if Input.is_action_just_released("timeslow"):
		Engine.set_time_scale(1)
	
	## JUMP START
	if Input.is_action_just_pressed("jump"):
		jump_press_time = time
		if is_on_floor() or in_coyote_interval_floor():
			if is_on_wall() and direction_x:
				wall_jump()
			else:
				jump()
		elif is_on_wall() or in_coyot_interval_wall():
			wall_jump()
	
	## JUMP STOP
	if Input.is_action_just_released("jump"):
		if in_jump and velocity[1] < 0:
			jump_ended_early = true
	
	## DASH (PROTOTYPE)
	#if direction and Input.is_action_just_pressed("dash"):
		#velocity = (direction).normalized()*DSHV
	
	## MOVING
	if direction_x:
		if is_on_floor():
			velocity[0] = move_toward(velocity[0], direction_x*speed, ACC)
		else:
			velocity[0] = move_toward(velocity[0], direction_x*speed, ACC*air_control)
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


	move_and_slide()
	
	## VISUAL
	visual.material.set_shader_parameter("r", (velocity).angle()*-2);
	var curent_size = visual.material.get_shader_parameter("size")
	var target_size = abs(clamp(velocity.length()/(3000*(1/DFRMSZ)),0,DFRMMX))
	visual.material.set_shader_parameter("size", move_toward(curent_size,target_size,0.8*delta));
	var current_offset = visual.material.get_shader_parameter("offset")
	var offset = Vector2()
	if on_floor:
		offset += Vector2(0,8)
	if on_wall:
		offset += Vector2(get_wall_normal()[0]*-8,0)
	visual.material.set_shader_parameter("offset", lerp(current_offset,offset, 0.1) );
	
