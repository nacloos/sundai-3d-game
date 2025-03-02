extends CharacterBody3D

@onready var walking_animation_player = $WalkingModel/Animation_Walking_withSkin/AnimationPlayer
@onready var running_animation_player = $RunningModel/Animation_Running_withSkin/AnimationPlayer

const GRAVITY_STRENGTH = 20.0
const CHASE_SPEED = 6.0
const WALK_SPEED = 3.0
const ROTATION_SPEED = 2.5
const DETECTION_RANGE = 10.0
const RANDOM_WALK_TIME_MIN = 2.0
const RANDOM_WALK_TIME_MAX = 5.0
const IDLE_TIME_MIN = 1.0
const IDLE_TIME_MAX = 3.0

var gravity: Vector3
var gravity_velocity: Vector3 = Vector3.ZERO
var move_dir: Vector3 = Vector3.ZERO
var up_dir: Vector3
var forward_dir: Vector3
var right_dir: Vector3
var orientation: Basis

var player: Node3D = null
var random_walk_timer: float = 0.0
var is_walking: bool = false
var random_direction: Vector3 = Vector3.ZERO

func _ready():
	# Wait for scene tree to be ready
	await get_tree().process_frame
	
	# Find player node
	player = get_tree().get_root().find_child("Character", true, false)
	if not player:
		push_error("Could not find player node")
		return
	
	# Configure animations to loop
	if walking_animation_player and walking_animation_player.has_animation("Armature|walking_man|baselayer"):
		walking_animation_player.get_animation("Armature|walking_man|baselayer").loop_mode = 1
	if running_animation_player and running_animation_player.has_animation("Armature|running|baselayer"):
		running_animation_player.get_animation("Armature|running|baselayer").loop_mode = 1
	
	# Hide running model initially
	$RunningModel.hide()
	
	# Start with random walk timer
	_start_random_walk_timer()

func _start_random_walk_timer():
	if is_walking:
		# Set timer for walking duration
		random_walk_timer = randf_range(RANDOM_WALK_TIME_MIN, RANDOM_WALK_TIME_MAX)
	else:
		# Set timer for idle duration
		random_walk_timer = randf_range(IDLE_TIME_MIN, IDLE_TIME_MAX)

func _get_random_direction():
	# Get a random direction tangent to the planet surface
	var random_angle = randf() * PI * 2.0
	var right = Vector3(cos(random_angle), 0, sin(random_angle))
	up_dir = -gravity.normalized()
	return (right - up_dir * right.dot(up_dir)).normalized()

func _physics_process(delta):
	# Skip if player reference is invalid
	if not player:
		return
		
	# Calculate gravity direction towards planet center
	var planet_center = Vector3.ZERO
	gravity = (planet_center - global_position).normalized() * GRAVITY_STRENGTH
	
	# Handle gravity
	if is_on_floor():
		gravity_velocity = Vector3.ZERO
	else:
		gravity_velocity += gravity * delta
	
	# Calculate movement direction towards player if in range
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < DETECTION_RANGE:
		# Chase player mode
		up_dir = -gravity.normalized()
		var to_player = (player.global_position - global_position).normalized()
		move_dir = (to_player - up_dir * to_player.dot(up_dir)).normalized()
		
		# Set velocity
		velocity = move_dir * CHASE_SPEED
		
		# Play running animation
		if running_animation_player and running_animation_player.has_animation("Armature|running|baselayer"):
			$WalkingModel.hide()
			$RunningModel.show()
			if not running_animation_player.is_playing():
				running_animation_player.play("Armature|running|baselayer")
	else:
		# Random walk mode
		random_walk_timer -= delta
		
		if random_walk_timer <= 0:
			# Toggle walking state and get new timer
			is_walking = !is_walking
			_start_random_walk_timer()
			
			if is_walking:
				# Get new random direction when starting to walk
				random_direction = _get_random_direction()
		
		if is_walking:
			move_dir = random_direction
			velocity = move_dir * WALK_SPEED
		else:
			velocity = Vector3.ZERO
		
		# Play walking animation
		if walking_animation_player and walking_animation_player.has_animation("Armature|walking_man|baselayer"):
			$RunningModel.hide()
			$WalkingModel.show()
			if is_walking and not walking_animation_player.is_playing():
				walking_animation_player.play("Armature|walking_man|baselayer")
			elif not is_walking and walking_animation_player.is_playing():
				walking_animation_player.stop()
	
	# Apply gravity
	velocity += gravity_velocity
	
	# Update character orientation
	up_dir = -gravity.normalized()
	if move_dir != Vector3.ZERO:
		var target_transform = Transform3D()
		target_transform = target_transform.looking_at(move_dir, up_dir)
		transform.basis = transform.basis.slerp(target_transform.basis, delta * ROTATION_SPEED)
	
	# Align with planet surface
	up_direction = up_dir
	move_and_slide() 
