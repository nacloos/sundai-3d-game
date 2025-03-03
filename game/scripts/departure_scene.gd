extends Node3D

var animation_started = false
var animation_speed = 30.0  # Increased speed for z-axis movement
var initial_height = 30.0
var initial_z = -100.0
var target_z = 40.0  # Final position closer to camera

@onready var spaceship = $Spaceship
@onready var camera = $Camera3D
@onready var success_label = $UI/SuccessLabel
@onready var restart_button = $UI/RestartButton

func _ready():
	# Initialize UI
	success_label.text = "Mission Accomplished!\nReturning Home"
	restart_button.hide()
	
	# Set initial positions
	spaceship.position.y = initial_height
	spaceship.position.z = initial_z
	
	# Start the animation automatically after a short delay
	await get_tree().create_timer(0.5).timeout
	start_departure()

func _process(delta):
	if animation_started:
		# Move spaceship towards camera
		spaceship.position.z = move_toward(spaceship.position.z, target_z, animation_speed * delta)
		
		# Slightly rise as it comes closer
		spaceship.position.y = initial_height + (spaceship.position.z - initial_z) * 0.1
		
		# Check if animation is complete
		if spaceship.position.z >= target_z - 0.1:
			animation_started = false
			show_restart_button()

func start_departure():
	animation_started = true

func show_restart_button():
	restart_button.show()
	# Create a small scale animation for the button
	var tween = create_tween()
	tween.tween_property(restart_button, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(restart_button, "scale", Vector2(1.0, 1.0), 0.5)
	tween.set_loops()

func _on_restart_button_pressed():
	# Change back to the main scene
	get_tree().change_scene_to_file("res://scenes/main_scene.tscn") 