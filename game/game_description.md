# Astronaut Planet - Game Implementation Prompt

Create a 3D game where players control an astronaut character exploring a small spherical planet. The game should feature smooth character movement, custom gravity mechanics, and multiple character animations.

Use this document as a checklist to implement and review your implementation.

## Core Mechanics

### Planet and Environment
1. Create a spherical planet with a radius of 20 units using a `SphereMesh` and corresponding `SphereShape3D` for collision
2. Set up a basic environment with directional lighting and shadows
3. Implement a custom gravity system that pulls the character towards the planet's center with a strength of 20.0

### Character Setup
1. Use the provided character models from the assets folder:
   - Walking animation: "Animation_Walking_withSkin.glb"
   - Running animation: "Animation_Running_withSkin.glb"
   - Dancing animation: "Animation_Excited_Walk_F_withSkin.glb"
2. Create a CharacterBody3D node with a CapsuleShape3D (radius: 0.3, height: 1.8)
3. For each animation model:
   a. Create a Node3D parent node (WalkingModel, RunningModel, DancingModel)
   b. Instance the GLB file as a child of its respective Node3D
   c. The final hierarchy should be:
      ```
      Character (CharacterBody3D)
      ├── CollisionShape3D
      ├── WalkingModel (Node3D)
      │   └── Animation_Walking_withSkin (GLB instance)
      │       └── AnimationPlayer
      ├── RunningModel (Node3D)
      │   └── Animation_Running_withSkin (GLB instance)
      │       └── AnimationPlayer
      └── DancingModel (Node3D)
          └── Animation_Excited_Walk_F_withSkin (GLB instance)
              └── AnimationPlayer
      ```
4. Position the model parent nodes at an offset of -1 unit on the Y-axis relative to the character body
5. Rotate the WalkingModel and RunningModel 180 degrees around the Y-axis
6. Rotate the DancingModel 270 degrees around the Y-axis (180 + 90 degrees)

### Movement System
1. Implement WASD/Arrow key movement with a base speed of 5.0 units/second
2. Add running capability (2x speed) when holding the designated run key
3. Calculate movement direction relative to the character's orientation on the planet
4. Ensure movement is tangent to the planet's surface
5. Implement smooth character rotation with a rotation speed of 2.5

### Animation System
1. Configure animation references in the character script:
   ```gdscript
   @onready var walking_animation_player = $WalkingModel/Animation_Walking_withSkin/AnimationPlayer
   @onready var running_animation_player = $RunningModel/Animation_Running_withSkin/AnimationPlayer
   @onready var dancing_animation_player = $DancingModel/Animation_Excited_Walk_F_withSkin/AnimationPlayer
   ```
2. Configure all animation players to loop their animations using the correct animation paths:
   - Walking: "Armature|walking_man|baselayer"
   - Running: "Armature|running|baselayer"
   - Dancing: "Armature|Excited_Walk_F|baselayer"
3. Handle state management for:
   - Idle (no animation)
   - Walking
   - Running
   - Dancing
4. Handle smooth transitions between states
5. Stop animations when the character is stationary
6. Implement dance mode toggle with spacebar
   - Dancing should stop when movement input is detected

### Camera System
1. Create a camera mount that follows the character
2. Position the camera at an offset of (0, 5, 8) from the mount
3. Implement mouse-controlled camera rotation with:
   - Sensitivity: 0.003
   - Vertical angle limits: -80 to +80 degrees
4. Add mouse capture toggle with Escape key

## Implementation Details

### Physics Processing
1. Calculate gravity direction each frame as (planet_center - character_position).normalized() * GRAVITY_STRENGTH
2. Reset gravity velocity when character is on floor
3. Apply gravity velocity to character movement
4. Update character's up direction to align with planet surface

### Input Handling
1. Capture movement input as a normalized Vector2
2. Convert 2D input into 3D movement direction using character's orientation
3. Handle mouse motion for camera rotation
4. Implement spacebar for dance toggle
5. Add escape key for mouse capture toggle

### Required Variables
```gdscript
# Movement and state
var movement_speed = 5.0
var rotation_speed = 2.5
var is_running = false
var is_dancing = false

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
```

### State Management Functions
1. Dance mode toggle:
```gdscript
func stop_dancing():
    is_dancing = false
    dancing_model.hide()
    walking_model.show()
    dancing_animation_player.stop()

# In _physics_process:
if Input.is_action_just_pressed("ui_select"):  # Space bar
    if !is_dancing:
        is_dancing = true
        walking_model.hide()
        running_model.hide()
        dancing_model.show()
        dancing_animation_player.play("Armature|Excited_Walk_F|baselayer")

if is_dancing and input_dir != Vector2.ZERO:
    stop_dancing()
```

2. Mouse capture toggle:
```gdscript
if event.is_action_pressed("ui_cancel"):
    if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
```

### Physics Process Flow
The `_physics_process` function should handle operations in this order:
1. Calculate gravity direction towards planet center
2. Process movement input
3. Handle dance mode toggle
4. Update character movement and orientation
5. Apply gravity
6. Update camera position and orientation

### Gravity Handling
```gdscript
func handle_gravity(delta):
    if character.is_on_floor():
        gravity_velocity = Vector3.ZERO
    else:
        gravity_velocity += gravity * delta
    
    character.velocity += gravity_velocity
    
    # Align character with planet surface
    up_dir = -gravity.normalized()
    character.up_direction = up_dir
    character.move_and_slide()
```

### Animation Management
1. Store references to all three model nodes and their animation players
2. Show/hide models based on current state
3. Play appropriate animation based on movement state
4. Handle animation transitions when:
   - Starting/stopping movement
   - Switching between walking/running
   - Entering/exiting dance mode

### Code Structure
1. Use @onready variables for node references
2. Implement _ready() for initial setup
3. Use _input() for mouse and keyboard input handling
4. Implement _physics_process() for movement and gravity
5. Create helper functions for:
   - Gravity handling
   - Animation state management
   - Camera orientation updates

## Assets Usage
The game requires three character models with animations from the assets/biped/biped/ directory.

### Required Model Paths and Configuration
1. Walking Model:
   - Path: `res://assets/biped/biped/Animation_Walking_withSkin.glb`
   - Transform: position=(0, -1, 0), rotation=(0, 180, 0)
   - Animation: "Armature|walking_man|baselayer"

2. Running Model:
   - Path: `res://assets/biped/biped/Animation_Running_withSkin.glb`
   - Transform: position=(0, -1, 0), rotation=(0, 180, 0)
   - Animation: "Armature|running|baselayer"

3. Dancing Model:
   - Path: `res://assets/biped/biped/Animation_Excited_Walk_F_withSkin.glb`
   - Transform: position=(0, -1, 0), rotation=(0, 270, 0)
   - Animation: "Armature|Excited_Walk_F|baselayer"

Each model should be instantiated as a child of the Character node. The AnimationPlayer nodes will be automatically created as children of their respective models and can be accessed via `$Character/ModelName/AnimationPlayer`.

## Expected Behavior
- Character should smoothly walk/run on the planet's surface
- Character should always orient correctly relative to the planet's surface
- Camera should follow the character while allowing free rotation
- Animations should transition smoothly between states
- Dancing should be interruptible by movement
- Gravity should feel natural and consistent

## Additional Implementation Details

### Scene Structure
Create a scene with the following node hierarchy:
```
TestScene (Node3D)
├── WorldEnvironment
├── DirectionalLight3D
├── Planet (StaticBody3D)
│   ├── MeshInstance3D
│   └── CollisionShape3D
├── Character (CharacterBody3D)
│   ├── CollisionShape3D
│   ├── WalkingModel
│   ├── RunningModel
│   └── DancingModel
└── CameraMount (Node3D)
    └── Camera3D
```

### Animation Setup
1. Animation names in the GLB files:
   - Walking: "Armature|walking_man|baselayer"
   - Running: "Armature|running|baselayer"
   - Dancing: "Armature|Excited_Walk_F|baselayer"
2. Set up animation looping in _ready():
```gdscript
walking_animation_player.get_animation("Armature|walking_man|baselayer").loop_mode = 1
running_animation_player.get_animation("Armature|running|baselayer").loop_mode = 1
dancing_animation_player.get_animation("Armature|Excited_Walk_F|baselayer").loop_mode = 1
```

### Input Configuration
Set up the following input actions in the Project Settings:
1. "move_forward" - W key and Up arrow
2. "move_backward" - S key and Down arrow
3. "move_left" - A key and Left arrow
4. "move_right" - D key and Right arrow
5. "run" - Shift key
6. "ui_select" - Space bar (for dancing)
7. "ui_cancel" - Escape key (for mouse capture)

### Initial Setup
1. Position the character at (0, 21, 0) to start above the planet
2. Set initial mouse mode in _ready():
```gdscript
Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
```
3. Hide running and dancing models initially:
```gdscript
running_model.hide()
dancing_model.hide()
```
4. Stop all animations initially:
```gdscript
walking_animation_player.stop()
running_animation_player.stop()
dancing_animation_player.stop()
```

### Movement and Camera Calculations
1. Camera rotation variables:
```gdscript
var camera_rotation_x = 0.0  # Pitch
var camera_rotation_y = 0.0  # Yaw
```

2. Mouse input handling for camera:
```gdscript
func _input(event):
    if event is InputEventMouseMotion:
        # Rotate camera mount horizontally
        camera_rotation_y -= event.relative.x * camera_sensitivity
        
        # Rotate camera vertically with clamping
        camera_rotation_x -= event.relative.y * camera_sensitivity
        camera_rotation_x = clamp(camera_rotation_x, 
                                deg_to_rad(min_camera_angle), 
                                deg_to_rad(max_camera_angle))
```

3. Movement vector calculation:
```gdscript
# Calculate character orientation vectors
up_dir = -gravity.normalized()
forward_dir = -character.transform.basis.z
right_dir = character.transform.basis.x

# Convert 2D input to 3D movement
move_dir = (forward_dir * input_dir.y + right_dir * input_dir.x).normalized()

# Project movement onto planet surface tangent
move_dir = (move_dir - up_dir * move_dir.dot(up_dir)).normalized()
```

4. Camera orientation update:
```gdscript
camera_mount.global_transform.origin = character.global_transform.origin
camera_mount.basis = Basis()  # Reset rotation
camera_mount.rotate_y(camera_rotation_y)  # Apply yaw
camera_mount.rotate_object_local(Vector3.RIGHT, camera_rotation_x)  # Apply pitch
```

5. Character orientation:
```gdscript
# Align character with movement direction
if move_dir != up_dir:
    var target_transform = Transform3D()
    target_transform = target_transform.looking_at(move_dir, up_dir)
    character.transform.basis = character.transform.basis.slerp(
        target_transform.basis, 
        delta * rotation_speed
    )
```

These calculations ensure:
- Smooth camera control with proper angle limits
- Movement that stays tangent to the planet surface
- Correct character orientation relative to movement direction
- Proper alignment with the planet's gravity

## Common Issues and Solutions

### Animation Node Path Issues
1. **GLB Animation Player Access**
   - **Problem**: Animation players are not direct children of the model nodes, but are inside the GLB instances
   - **Incorrect Path**: `$WalkingModel/AnimationPlayer`
   - **Correct Path**: `$WalkingModel/Animation_Walking_withSkin/AnimationPlayer`
   - **Solution**: Always reference AnimationPlayer nodes through the complete path including the GLB instance:
     ```gdscript
     # Correct animation player references
     @onready var walking_animation_player = $WalkingModel/Animation_Walking_withSkin/AnimationPlayer
     @onready var running_animation_player = $RunningModel/Animation_Running_withSkin/AnimationPlayer
     @onready var dancing_animation_player = $DancingModel/Animation_Excited_Walk_F_withSkin/AnimationPlayer
     ```

2. **Animation Loading Timing**
   - **Problem**: Attempting to access animations before they are fully loaded
   - **Solution**: 
     - Wait for animations to load in _ready():
     ```gdscript
     func _ready():
         # Wait a frame for animations to load
         await get_tree().process_frame
         
         # Then configure animations
         if walking_animation_player and walking_animation_player.has_animation("Armature|walking_man|baselayer"):
             walking_animation_player.get_animation("Armature|walking_man|baselayer").loop_mode = 1
     ```
     - Add null checks before accessing animation players
     - Use an animations_ready flag to track initialization state

3. **Scene Structure Requirements**
   - **Problem**: Incorrect node hierarchy can break animation references
   - **Solution**: Follow the exact scene hierarchy:
     ```
     Character (CharacterBody3D)
     ├── CollisionShape3D
     ├── WalkingModel (Node3D)
     │   └── Animation_Walking_withSkin (GLB instance)
     │       └── AnimationPlayer
     ├── RunningModel (Node3D)
     │   └── Animation_Running_withSkin (GLB instance)
     │       └── AnimationPlayer
     └── DancingModel (Node3D)
         └── Animation_Excited_Walk_F_withSkin (GLB instance)
             └── AnimationPlayer
     ```
