
extends KinematicBody

var velocity=Vector3()
var view_sensitivity = 0.3
var yaw = 0
var pitch = 0

const FLY_SPEED=100
const FLY_ACCEL=4

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		yaw = fmod(yaw - event.relative_x * view_sensitivity, 360)
		pitch = max(min(pitch - event.relative_y * view_sensitivity, 90), -90)
		get_node("yaw").set_rotation(Vector3(0, deg2rad(yaw), 0))
		get_node("yaw/heroCamera").set_rotation(Vector3(deg2rad(pitch), 0, 0))

func _fixed_process(delta):
	_fly(delta)

func _ready():
	self.set_fixed_process(true)
	self.set_process_input(true)

func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _fly(delta):
	# Check if player clicked Escape button
	if(Input.is_key_pressed(KEY_ESCAPE)):
		# Check if player clicked Shift button
		if(Input.is_key_pressed(KEY_SHIFT)):
			# If both buttons are clicked quit the game
			self.get_tree().quit()

	# read the rotation of the camera
	var aim = get_node("yaw/heroCamera").get_global_transform().basis
	# calculate the direction where the player want to move
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
		
	# calculate the target where the player want to move
	var target = direction*FLY_SPEED
	
	# calculate the velocity to move the player toward the target
	velocity = Vector3().linear_interpolate(target, FLY_ACCEL*delta)
	
	# move the node
	var motion = velocity*delta
	motion = self.move(motion)
	
	# slide until it doesn't need to slide anymore, or after n times
	var original_vel = velocity
	var attempts = 4 # number of attempts to slide the node
	
	while(attempts and self.is_colliding()):
		var n = self.get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		# check that the resulting velocity is not opposite to the original velocity, which would mean moving backward.
		if(original_vel.dot(velocity)>0):
			motion = self.move(motion)
			if (motion.length() < 0.001):
				break
		attempts -= 1
