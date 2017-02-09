extends RigidBody

var view_sensitivity = 0.3;

const WALK_SPEED = 3;
const JUMP_SPEED = 3;
const MAX_ACCEL = 0.02;
const AIR_ACCEL = 0.05;

var is_moving = false;
var on_floor = false;

var attachment_startpos = Vector3();
var bob_angle = Vector3();
var bob_amount = 0.03;

func _ready():
	self.set_process(true);
	self.set_process_input(true);
	
func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		var yaw = rad2deg(get_node("eyes").get_rotation().y);
		var pitch = rad2deg(get_node("eyes/camera").get_rotation().x);
		
		yaw = fmod(yaw - event.relative_x * view_sensitivity, 360);
		pitch = max(min(pitch - event.relative_y * view_sensitivity, 90), -90);
		
		get_node("eyes").set_rotation(Vector3(0, deg2rad(yaw), 0));
		get_node("eyes/camera").set_rotation(Vector3(deg2rad(pitch), 0, 0));
		
func _integrate_forces(state):
	
	var aim = get_node("eyes").get_global_transform().basis;
	var direction = Vector3();
	is_moving = false;
	
	
	
	if Input.is_action_pressed("move_forward"):
		direction -= aim[2];
		is_moving = true;
	if Input.is_action_pressed("move_back"):
		direction += aim[2];
		is_moving = true;
	if Input.is_action_pressed("move_left"):
		direction -= aim[0];
		is_moving = true;
	if Input.is_action_pressed("move_right"):
		direction += aim[0];
		is_moving = true;
	direction = direction.normalized();
	
	var ray = get_node("ray");
	if ray.is_colliding():
		var up = state.get_total_gravity().normalized();
		var normal = ray.get_collision_normal();
		var floor_velocity = Vector3();
		
		var speed = WALK_SPEED;
		var diff = floor_velocity + direction * WALK_SPEED - state.get_linear_velocity();
		var vertdiff = aim[1] * diff.dot(aim[1]);
		diff -= vertdiff;
		diff = diff.normalized() * clamp(diff.length(), 0, MAX_ACCEL / state.get_step());
		diff += vertdiff;
		self.apply_impulse(Vector3(), diff * self.get_mass());
		
		on_floor = true;
		
		if Input.is_key_pressed(KEY_SPACE):
			#apply_impulse(Vector3(), normal * JUMP_SPEED * get_mass());
			self.apply_impulse(Vector3(), Vector3(0,1,0) * JUMP_SPEED * self.get_mass());
	else:
		self.apply_impulse(Vector3(), direction * AIR_ACCEL * self.get_mass());
		
		on_floor = false;
	state.integrate_forces();
	
func _enter_tree():
	get_node("eyes/camera").make_current();
	attachment_startpos = get_node("eyes/camera/attachment").get_translation();
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);

func _process(delta):
	if(Input.is_key_pressed(KEY_ESCAPE)):
		if(Input.is_key_pressed(KEY_SHIFT)):
			self.get_tree().quit()
			
	if is_moving && on_floor:
		var move_speed = 3.0;
		var trans = get_node("eyes/camera/attachment").get_translation();
		trans = trans.linear_interpolate(Vector3(attachment_startpos.x + bob_amount * -sin(bob_angle.x), attachment_startpos.y + bob_amount * -sin(bob_angle.y), 0), 10*delta);
		get_node("eyes/camera/attachment").set_translation(trans);
		bob_angle.x += move_speed*1.5*delta;
		if bob_angle.x >= 2*PI:
			bob_angle.x = 0;
		bob_angle.y += move_speed*1.5*delta;
		if bob_angle.y >= PI:
			bob_angle.y = 0;
	else:
		var target = attachment_startpos;
		if !on_floor:
			target.y -= bob_amount;
		
		var trans = get_node("eyes/camera/attachment").get_translation().linear_interpolate(target, 10*delta);
		get_node("eyes/camera/attachment").set_translation(trans);
		
		bob_angle.x = 0;
		bob_angle.y = 0;