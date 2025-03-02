extends Node3D

func _ready():
    # Set up environment
    var world_environment = $WorldEnvironment
    var directional_light = $DirectionalLight3D
    
    # Configure lighting
    directional_light.light_energy = 1.5
    directional_light.shadow_enabled = true
    
    # Set initial character position
    var character = $Character
    character.position = Vector3(0, 21, 0)  # Start above planet surface 