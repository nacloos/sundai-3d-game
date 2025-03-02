extends CharacterBody3D

# Movement and state
var movement_speed = 5.0
var rotation_speed = 2.5
var is_running = false
var is_dancing = false

# Collection counter
var hex_nuts_collected = 0
signal sphere_collected(total: int)

# Camera
var camera_rotation_x = 0.0
var camera_rotation_y = 0.0
var camera_sensitivity = 0.003
var min_camera_angle = -80.0  # Degrees
var max_camera_angle = 80.0   # Degrees

# Physics
const GRAVITY_STRENGTH = 20.0
var gravity: Vector3
var gravity_velocity: Vector3 = Vector3.ZERO
var move_dir: Vector3 = Vector3.ZERO
var up_dir: Vector3
var forward_dir: Vector3
var right_dir: Vector3
var orientation: Basis

# Node references
@onready var walking_model = $WalkingModel
@onready var running_model = $RunningModel
@onready var dancing_model = $DancingModel
@onready var walking_animation_player = $WalkingModel/Animation_Walking_withSkin/AnimationPlayer
@onready var running_animation_player = $RunningModel/Animation_Running_withSkin/AnimationPlayer
@onready var dancing_animation_player = $DancingModel/Animation_Excited_Walk_F_withSkin/AnimationPlayer
@onready var camera_mount = $"../CameraMount"

func _ready():
    # Add to player group for hex nut collection
    add_to_group("player")
    
    # Hide running and dancing models initially
    running_model.hide()
    dancing_model.hide()
    
    # Set up animations
    walking_animation_player.get_animation("Armature|walking_man|baselayer").loop_mode = 1
    running_animation_player.get_animation("Armature|running|baselayer").loop_mode = 1
    dancing_animation_player.get_animation("Armature|Excited_Walk_F|baselayer").loop_mode = 1
    
    # Stop all animations initially
    walking_animation_player.stop()
    running_animation_player.stop()
    dancing_animation_player.stop()
    
    # Set initial mouse mode
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    if event is InputEventMouseMotion:
        # Rotate camera mount horizontally
        camera_rotation_y -= event.relative.x * camera_sensitivity
        
        # Rotate camera vertically with clamping
        camera_rotation_x -= event.relative.y * camera_sensitivity
        camera_rotation_x = clamp(camera_rotation_x, 
                                deg_to_rad(min_camera_angle), 
                                deg_to_rad(max_camera_angle))
    
    if event.is_action_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    # Get input direction - disabled backward movement
    var input_dir = Vector2.ZERO
    input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    input_dir.y = Input.get_action_strength("move_forward")  # Removed backward input
    input_dir = input_dir.normalized()
    
    # Handle running state
    is_running = Input.is_action_pressed("run") and input_dir != Vector2.ZERO
    
    # Handle dancing
    if Input.is_action_just_pressed("dance"):
        if !is_dancing:
            start_dancing()
    
    if is_dancing and input_dir != Vector2.ZERO:
        stop_dancing()
    
    # Calculate gravity direction (towards planet center)
    var planet_center = Vector3.ZERO
    var to_center = planet_center - global_position
    gravity = to_center.normalized() * GRAVITY_STRENGTH
    
    # Handle gravity
    if is_on_floor():
        gravity_velocity = Vector3.ZERO
    else:
        gravity_velocity += gravity * delta
    
    # Calculate movement direction
    up_dir = -gravity.normalized()
    forward_dir = -transform.basis.z
    right_dir = transform.basis.x
    
    # Convert 2D input to 3D movement
    move_dir = (forward_dir * input_dir.y + right_dir * input_dir.x).normalized()
    
    # Project movement onto planet surface tangent
    move_dir = (move_dir - up_dir * move_dir.dot(up_dir)).normalized()
    
    # Set velocity
    var speed = movement_speed * (2.0 if is_running else 1.0)
    velocity = move_dir * speed + gravity_velocity
    
    # Update character orientation
    if move_dir.length() > 0.1:
        var target_transform = Transform3D()
        target_transform = target_transform.looking_at(move_dir, up_dir)
        transform.basis = transform.basis.slerp(target_transform.basis, delta * rotation_speed)
    
    # Align with planet surface
    up_direction = up_dir
    move_and_slide()
    
    # Update camera position and orientation
    camera_mount.global_position = global_position
    camera_mount.basis = Basis()  # Reset rotation
    camera_mount.rotate_y(camera_rotation_y)  # Apply yaw
    camera_mount.rotate_object_local(Vector3.RIGHT, camera_rotation_x)  # Apply pitch
    
    # Update animations
    update_animations(input_dir)

func update_animations(input_dir: Vector2):
    if is_dancing:
        return
        
    if input_dir == Vector2.ZERO:
        walking_animation_player.stop()
        running_animation_player.stop()
    else:
        if is_running:
            walking_model.hide()
            running_model.show()
            if !running_animation_player.is_playing():
                running_animation_player.play("Armature|running|baselayer")
        else:
            running_model.hide()
            walking_model.show()
            if !walking_animation_player.is_playing():
                walking_animation_player.play("Armature|walking_man|baselayer")

func start_dancing():
    is_dancing = true
    walking_model.hide()
    running_model.hide()
    dancing_model.show()
    dancing_animation_player.play("Armature|Excited_Walk_F|baselayer")

func stop_dancing():
    is_dancing = false
    dancing_model.hide()
    walking_model.show()
    dancing_animation_player.stop()

func collect_sphere():
    hex_nuts_collected += 1
    print("Hex nut collected! Total: ", hex_nuts_collected)
    sphere_collected.emit(hex_nuts_collected)