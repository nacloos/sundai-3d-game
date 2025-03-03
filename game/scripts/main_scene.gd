extends Node3D

const NUM_CREATURES = 5
const PLANET_RADIUS = 20.0

@onready var creature_scene = preload("res://scenes/creature.tscn")
@onready var collection_label = $UI/CollectionLabel
@onready var win_screen = $UI/WinScreen

func _ready():
	# Spawn multiple creatures at random positions
	spawn_creatures()
	
	# Connect sphere collection signal
	var character = $Character
	character.sphere_collected.connect(_on_sphere_collected)
	character.game_won.connect(_on_game_won)
	
	# Hide win screen initially
	win_screen.hide()
	
	# Connect restart button
	$UI/WinScreen/VBoxContainer/RestartButton.pressed.connect(_on_restart_button_pressed)

func spawn_creatures():
	# Get reference to the original creature
	var original_creature = $Creature
	
	# Create multiple creatures
	for i in range(NUM_CREATURES):
		# Generate random position on planet surface
		var random_pos = random_point_on_sphere(PLANET_RADIUS + 1.0)
		
		# Create new creature instance
		var new_creature
		if i == 0:
			# Reuse the original creature for the first one
			new_creature = original_creature
		else:
			# Instance new creatures for the rest
			new_creature = creature_scene.instantiate()
			add_child(new_creature)
		
		# Position the creature
		new_creature.global_transform.origin = random_pos
		
		# Orient the creature to align with planet surface
		var up_dir = random_pos.normalized()
		var forward_dir = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized()
		forward_dir = (forward_dir - up_dir * forward_dir.dot(up_dir)).normalized()
		var right_dir = up_dir.cross(forward_dir)
		
		var basis = Basis(right_dir, up_dir, -forward_dir)
		new_creature.global_transform.basis = basis

func random_point_on_sphere(radius):
	var theta = randf() * 2.0 * PI
	var phi = acos(2.0 * randf() - 1.0)
	
	var x = radius * sin(phi) * cos(theta)
	var y = radius * sin(phi) * sin(theta)
	var z = radius * cos(phi)
	
	return Vector3(x, y, z)

func _on_sphere_collected(total: int):
	collection_label.text = "Hex Nuts: %d / 6" % total

func _on_game_won():
	# Show win screen
	win_screen.show()
	
	# Enable mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Stop creature movement
	for creature in get_tree().get_nodes_in_group("creatures"):
		if creature.has_method("stop_movement"):
			creature.stop_movement()
	
	# Make player dance
	var character = $Character
	if character.has_method("start_dancing"):
		character.start_dancing()

func _on_restart_button_pressed():
	# Reload the current scene
	get_tree().reload_current_scene()
