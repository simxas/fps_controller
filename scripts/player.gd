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
	pass
