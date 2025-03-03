extends Node3D

@onready var camera = $Camera3D
@onready var target: Node3D = $"../Character"

# Camera settings
const DISTANCE = 8.0       # Distance behind character
const HEIGHT = 2.0         # Height above character
const SMOOTHING = 6.0      # Camera movement smoothing
const DIRECTION_SMOOTHING = 1.5  # How quickly camera follows direction changes (lower = smoother)

# Camera rotation
var camera_rotation = 0.0
var camera_sensitivity = 0.003

# Smoothing variables
var current_follow_dir = Vector3.FORWARD
var last_valid_move_dir = Vector3.FORWARD

# Exposed direction vectors for character to use
var cam_forward_dir: Vector3
var cam_right_dir: Vector3

func _ready():
	if target and camera:
		camera_rotation = PI
		# Set initial camera position
		update_camera_position(1.0)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate camera based on mouse movement
		camera_rotation -= event.relative.x * camera_sensitivity

func _physics_process(delta):
	if !target:
		return
		
	update_camera_position(delta)

func update_camera_position(delta):
	# Get planet-relative up direction
	var planet_center = Vector3.ZERO
	var up_dir = (target.global_position - planet_center).normalized()
	
	# Calculate base forward direction from camera rotation
	var base_forward = Vector3(sin(camera_rotation), 0, cos(camera_rotation))
	
	# Project onto planet tangent plane
	var forward_dir = (base_forward - up_dir * base_forward.dot(up_dir)).normalized()
	
	# Calculate right direction perpendicular to up and forward
	var right_dir = up_dir.cross(forward_dir).normalized()
	
	# Recalculate forward for perfect orthogonality
	forward_dir = right_dir.cross(up_dir).normalized()
	
	# Expose these directions for the character to use
	cam_forward_dir = forward_dir
	cam_right_dir = right_dir
	
	# Handle movement direction smoothing
	var move_length = target.move_dir.length()
	
	# Determine direction to follow
	var target_follow_dir
	if move_length > 0.1:
		# Character is moving - update last valid direction
		last_valid_move_dir = target.move_dir.normalized()
		target_follow_dir = last_valid_move_dir
	else:
		# Character isn't moving - use camera's own direction
		target_follow_dir = forward_dir
	
	# Smoothly blend between current direction and target direction
	current_follow_dir = current_follow_dir.slerp(target_follow_dir, delta * DIRECTION_SMOOTHING)
	
	# Calculate camera position using the smoothed direction
	var camera_offset = -current_follow_dir * DISTANCE
	var height_offset = up_dir * HEIGHT
	var desired_position = target.global_position + camera_offset + height_offset
	
	# Smoothly move camera position
	global_position = global_position.lerp(desired_position, delta * SMOOTHING)
	
	# Make the camera look at a point in front of the character
	var look_target = target.global_position + forward_dir * 2.0
	look_at(look_target, up_dir)
