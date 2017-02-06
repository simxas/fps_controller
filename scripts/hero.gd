
extends KinematicBody

var velocity = Vector3()
var view_sensitivity = 0.3
var yaw = 0
var pitch = 0

const FLY_SPEED=100
const FLY_ACCEL=4

# added for _walk function
var is_moving = false

const WALK_MAX_SPEED = 15
const ACCEL = 2
const DEACCEL = 4
const GRAVITY = -9.8 * 3

const JUMP_SPEED = 3 * 3

var on_floor = false

const MAX_SLOPE_ANGLE = 40

var jump_timeout = 0
const MAX_JUMP_TIMEOUT = 0.2

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		yaw = fmod(yaw - event.relative_x * view_sensitivity, 360)
		pitch = max(min(pitch - event.relative_y * view_sensitivity, 90), -90)
		get_node("yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
		get_node("yaw/heroCamera").set_rotation(Vector3(deg2rad(pitch), 0, 0))

func _fixed_process(delta):
#	_fly(delta)
	_walk(delta)

func _ready():
	self.set_fixed_process(true)
	self.set_process_input(true)

func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _fly(delta):
	if(Input.is_key_pressed(KEY_ESCAPE)):
		if(Input.is_key_pressed(KEY_SHIFT)):
			self.get_tree().quit()

	var aim = get_node("yaw/heroCamera").get_global_transform().basis
	var direction = Vector3()
	if Input.is_action_pressed("move_forward"):
		direction -= aim[2]
	if Input.is_action_pressed("move_back"):
		direction += aim[2]
	if Input.is_action_pressed("move_left"):
		direction -= aim[0]
	if Input.is_action_pressed("move_right"):
		direction += aim[0]
	
	direction = direction.normalized()
		
	var target = direction*FLY_SPEED
	
	velocity = Vector3().linear_interpolate(target, FLY_ACCEL * delta)
	
	var motion = velocity*delta
	motion = self.move(motion)
	
	var original_vel = velocity
	var attempts = 4 # number of attempts to slide the node
	
	while(attempts and self.is_colliding()):
		var n = self.get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		
		if(original_vel.dot(velocity) > 0):
			motion = self.move(motion)
			if (motion.length() < 0.001):
				break
		attempts -= 1

func _walk(delta):
	if jump_timeout > 0:
		jump_timeout -= delta
	var ray = get_node("ray")
	
	if(Input.is_key_pressed(KEY_ESCAPE)):
		if(Input.is_key_pressed(KEY_SHIFT)):
			self.get_tree().quit()

	var aim = get_node("yaw/heroCamera").get_global_transform().basis
	
	var direction = Vector3()
	if Input.is_action_pressed("move_forward"):
		direction -= aim[2]
	if Input.is_action_pressed("move_back"):
		direction += aim[2]
	if Input.is_action_pressed("move_left"):
		direction -= aim[0]
	if Input.is_action_pressed("move_right"):
		direction += aim[0]
	
	is_moving = (direction.length() > 0) # new code
	
	direction.y = 0
	direction = direction.normalized()
	
	var is_ray_colliding = ray.is_colliding()
	
	if !on_floor and jump_timeout <= 0 and is_ray_colliding:
		self.set_translation(ray.get_collision_point())
		on_floor = true
	elif on_floor and not is_ray_colliding:
		on_floor = false
	
	if on_floor:
		var n = ray.get_collision_normal()
		velocity = velocity - velocity.dot(n) * n

		if (rad2deg(acos(n.dot(Vector3(0, 1, 0)))) > MAX_SLOPE_ANGLE):
			velocity.y += delta * GRAVITY
	else:
		velocity.y += delta * GRAVITY
	
	
	var target = direction * WALK_MAX_SPEED
	var accel = DEACCEL
	if is_moving:
		accel = ACCEL
	
	var hvel = velocity
	hvel.y = 0
	hvel = hvel.linear_interpolate(target, accel * delta)
	velocity.x = hvel.x
	velocity.z = hvel.z
		
	
	var motion = velocity * delta
	motion = self.move(motion)
	
	var original_vel = velocity
	
	if(motion.length() > 0 and self.is_colliding()):
		var n = self.get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		if(original_vel.dot(velocity) > 0):
			motion = self.move(motion)
	
	if on_floor:
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_SPEED
			jump_timeout = MAX_JUMP_TIMEOUT
			on_floor = false
