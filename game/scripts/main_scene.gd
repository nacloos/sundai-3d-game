extends Node3D

const NUM_CREATURES = 5
const PLANET_RADIUS = 20.0

var game_started = false
var game_paused = false

@onready var creature_scene = preload("res://scenes/creature.tscn")
@onready var collection_label = $UI/CollectionLabel

func _ready():
	# Create a simple start UI
	create_start_ui()
	
	# Don't start the game yet - set things up but wait for player input
	pause_game()
	
	# Set up environment
	var world_environment = $WorldEnvironment
	var directional_light = $DirectionalLight3D
	 
	# Configure lighting
	directional_light.light_energy = 1.5
	directional_light.shadow_enabled = true
	
	# Connect sphere collection signal
	var character = $Character
	character.sphere_collected.connect(_on_sphere_collected)
	
	# Hide collection label initially
	if collection_label:
		collection_label.hide()

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
	collection_label.text = "Hex Nuts: %d" % total
	
	# Check if all 6 hex nuts are collected
	if total >= 6:
		# Wait a brief moment before transitioning
		await get_tree().create_timer(1.0).timeout
		# Change to the departure scene
		get_tree().change_scene_to_file("res://scenes/departure_scene.tscn")

func pause_game():
	# Disable character input processing
	var character = $Character
	if character:
		character.set_process(false)
		character.set_process_input(false)
		character.set_physics_process(false)

func resume_game():
	# Enable character processing
	var character = $Character
	if character:
		character.set_process(true)
		character.set_process_input(true)
		character.set_physics_process(true)
	
	# Spawn creatures if not already spawned
	if !get_tree().get_nodes_in_group("creature").size():
		spawn_creatures()

func toggle_pause():
	if !game_started:
		return
		
	game_paused = !game_paused
	
	if game_paused:
		# Pause the game
		pause_game()
		
		# Show the pause UI
		if not has_node("PauseUI"):
			create_pause_ui()
		else:
			get_node("PauseUI").visible = true
			
		# Capture mouse for UI interaction
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# Resume the game
		resume_game()
		
		# Hide the pause UI
		if has_node("PauseUI"):
			get_node("PauseUI").visible = false
			
		# Recapture mouse for game
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func start_game():
	if game_started:
		return
		
	game_started = true
	
	# Remove the UI
	var start_ui = get_node("StartUI")
	if start_ui:
		start_ui.queue_free()
	
	# Show collection label
	if collection_label:
		collection_label.show()
	
	# Enable the character and spawn creatures
	resume_game()
	
	# Set initial character position
	var character = $Character
	if character:
		character.position = Vector3(0, 21, 0)  # Start above planet surface
		
	# Capture mouse for the game
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Start game on any key press if not started yet
	if !game_started and event is InputEventKey and event.pressed:
		start_game()
	
	# Toggle pause with ESC key
	if game_started and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle_pause()

func create_start_ui():
	# Create a CanvasLayer to ensure UI is drawn on top
	var canvas = CanvasLayer.new()
	canvas.name = "StartUI"
	add_child(canvas)
	
	# Create the UI container
	var ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui)
	
	# Create a star-field background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.15, 1.0)  # Deep space blue
	ui.add_child(bg)
	
	# Add stars (small circles) randomly to the background
	for i in range(100):
		# Create a round star using PanelContainer
		var star = PanelContainer.new()
		var size = randf_range(1, 3)
		star.custom_minimum_size = Vector2(size, size)
		star.position = Vector2(randf_range(0, 1024), randf_range(0, 600))
		
		# Random star colors (mostly white with some colorful ones)
		var color_choice = randi() % 10
		var star_color
		if color_choice < 7:
			star_color = Color(1, 1, 1, randf_range(0.5, 1.0))  # White stars with varying brightness
		elif color_choice < 8:
			star_color = Color(0.7, 0.7, 1.0, 1.0)  # Bluish stars
		elif color_choice < 9:
			star_color = Color(1.0, 0.7, 0.7, 1.0)  # Reddish stars
		else:
			star_color = Color(1.0, 1.0, 0.7, 1.0)  # Yellowish stars
		
		# Create round style
		var star_style = StyleBoxFlat.new()
		star_style.bg_color = star_color
		star_style.corner_radius_top_left = int(size / 2)
		star_style.corner_radius_top_right = int(size / 2)
		star_style.corner_radius_bottom_left = int(size / 2)
		star_style.corner_radius_bottom_right = int(size / 2)
		star.add_theme_stylebox_override("panel", star_style)
		
		# Create a timer for the star to create twinkling effect
		var timer = Timer.new()
		timer.wait_time = randf_range(0.5, 3.0)  # Random timing
		timer.autostart = true
		timer.one_shot = false
		bg.add_child(timer)
		
		# Connect timer to a lambda that will make star twinkle
		timer.timeout.connect(func(): 
			var tween = create_tween()
			tween.tween_property(star, "modulate", Color(1, 1, 1, randf_range(0.2, 1.0)), 0.5)
			tween.tween_property(star, "modulate", Color(1, 1, 1, randf_range(0.5, 1.0)), 0.5)
		)
		
		bg.add_child(star)
	
	# Add a few planets
	var planet_colors = [
		Color(0.7, 0.3, 0.9, 1.0),  # Purple
		Color(0.3, 0.7, 0.9, 1.0),  # Blue
		Color(1.0, 0.6, 0.2, 1.0)   # Orange
	]
	
	for i in range(3):
		# Create a container for the planet to allow rotation
		var planet_container = Control.new()
		planet_container.size = Vector2(80, 80)
		planet_container.position = Vector2(randf_range(50, 974), randf_range(50, 550))
		bg.add_child(planet_container)
		
		# Create a round planet using PanelContainer
		var planet = PanelContainer.new()
		var size = randf_range(30, 70)
		planet.custom_minimum_size = Vector2(size, size)
		planet.position = Vector2((80-size)/2, (80-size)/2)
		
		# Make it circular by setting corner radius
		var style = StyleBoxFlat.new()
		style.bg_color = planet_colors[i]
		style.corner_radius_top_left = int(size / 2)
		style.corner_radius_top_right = int(size / 2)
		style.corner_radius_bottom_left = int(size / 2)
		style.corner_radius_bottom_right = int(size / 2)
		planet.add_theme_stylebox_override("panel", style)
		planet_container.add_child(planet)
		
		# Create a tween for continuous rotation
		var tween = create_tween()
		tween.tween_property(planet_container, "rotation_degrees", 360, randf_range(20, 40))
		tween.set_loops()
		
		# Create a tween for floating movement
		var move_tween = create_tween()
		var target_pos = Vector2(
			planet_container.position.x + randf_range(-50, 50),
			planet_container.position.y + randf_range(-50, 50)
		)
		move_tween.tween_property(planet_container, "position", target_pos, randf_range(5, 10))
		move_tween.tween_property(planet_container, "position", planet_container.position, randf_range(5, 10))
		move_tween.set_loops()
	
	# Create a main container
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.size_flags_stretch_ratio = 2.0
	ui.add_child(main_container)
	
	# Add some top spacing
	var top_spacer = Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_spacer.size_flags_stretch_ratio = 0.5
	main_container.add_child(top_spacer)
	
	# Create center container for the main content
	var center_container = HBoxContainer.new()
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_container.size_flags_stretch_ratio = 2.0
	main_container.add_child(center_container)
	
	# Left spacer
	var left_spacer = Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_spacer.size_flags_stretch_ratio = 0.5
	center_container.add_child(left_spacer)
	
	# Create a content box
	var content_box = VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_container.add_child(content_box)
	
	# Add title label with stylized text
	var title_label = Label.new()
	title_label.text = "ASTRONAUT PLANET 3D"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))  # Golden text
	title_label.add_theme_color_override("font_shadow_color", Color(0.9, 0.4, 0.1, 0.5))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	content_box.add_child(title_label)
	
	# Add a subtitle
	var subtitle = Label.new()
	subtitle.text = "Explore the Planet & Repair Your Ship"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))  # Light blue
	content_box.add_child(subtitle)
	
	# Add some spacing
	var mid_spacer = Control.new()
	mid_spacer.custom_minimum_size = Vector2(0, 30)
	content_box.add_child(mid_spacer)
	
	# Add start button with stylized appearance
	var button = Button.new()
	button.text = "START MISSION"
	button.add_theme_font_size_override("font_size", 28)
	button.custom_minimum_size = Vector2(250, 60)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Style the button with a theme override
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.6, 0.8, 1.0)  # Blue button
	button_style.border_width_bottom = 4
	button_style.border_color = Color(0.1, 0.3, 0.5, 1.0)
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_left = 10
	button_style.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", button_style)
	
	# Hover style
	var hover_style = button_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.7, 0.9, 1.0)  # Lighter blue on hover
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = button_style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.45, 0.7, 1.0)  # Darker blue when pressed
	pressed_style.border_width_bottom = 2
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	content_box.add_child(button)
	
	# Add test button below the start button
	var test_button = Button.new()
	test_button.text = "Test End Scene"
	test_button.add_theme_font_size_override("font_size", 20)
	test_button.custom_minimum_size = Vector2(200, 40)
	test_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Style the test button (similar to main button but smaller and different color)
	var test_button_style = StyleBoxFlat.new()
	test_button_style.bg_color = Color(0.6, 0.2, 0.8, 1.0)  # Purple button
	test_button_style.border_width_bottom = 4
	test_button_style.border_color = Color(0.3, 0.1, 0.5, 1.0)
	test_button_style.corner_radius_top_left = 8
	test_button_style.corner_radius_top_right = 8
	test_button_style.corner_radius_bottom_left = 8
	test_button_style.corner_radius_bottom_right = 8
	test_button.add_theme_stylebox_override("normal", test_button_style)
	
	# Hover style for test button
	var test_hover_style = test_button_style.duplicate()
	test_hover_style.bg_color = Color(0.7, 0.3, 0.9, 1.0)  # Lighter purple on hover
	test_button.add_theme_stylebox_override("hover", test_hover_style)
	
	# Pressed style for test button
	var test_pressed_style = test_button_style.duplicate()
	test_pressed_style.bg_color = Color(0.5, 0.15, 0.7, 1.0)  # Darker purple when pressed
	test_pressed_style.border_width_bottom = 2
	test_button.add_theme_stylebox_override("pressed", test_pressed_style)
	
	# Add some spacing before the test button
	var test_button_spacer = Control.new()
	test_button_spacer.custom_minimum_size = Vector2(0, 10)
	content_box.add_child(test_button_spacer)
	
	content_box.add_child(test_button)
	
	# Connect the button signals
	button.connect("pressed", start_game)
	test_button.connect("pressed", _on_test_button_pressed)
	
	# Add help text
	var help_text = Label.new()
	help_text.text = "Press Any Key to Start"
	help_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_text.add_theme_font_size_override("font_size", 16)
	help_text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.7))
	content_box.add_child(help_text)
	
	# Add right spacer
	var right_spacer = Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_spacer.size_flags_stretch_ratio = 0.5
	center_container.add_child(right_spacer)
	
	# Add bottom spacer
	var bottom_container = VBoxContainer.new()
	bottom_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_container.add_child(bottom_container)
	
	# Add control guide in the bottom
	var guide_container = HBoxContainer.new()
	guide_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_container.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_container.add_child(guide_container)
	
	var controls_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.9)  # More opaque
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.border_width_left = 3  # Thicker border
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.3, 0.5, 0.9, 0.8)  # Brighter border
	controls_panel.add_theme_stylebox_override("panel", panel_style)
	guide_container.add_child(controls_panel)
	
	var controls_vbox = VBoxContainer.new()
	controls_vbox.custom_minimum_size = Vector2(400, 0)
	controls_panel.add_child(controls_vbox)
	
	var controls_title = Label.new()
	controls_title.text = "ASTRONAUT CONTROLS"
	controls_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_title.add_theme_font_size_override("font_size", 18)
	controls_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	controls_vbox.add_child(controls_title)
	
	var controls_grid = GridContainer.new()
	controls_grid.columns = 2
	controls_grid.add_theme_constant_override("h_separation", 20)
	controls_grid.add_theme_constant_override("v_separation", 8)
	controls_vbox.add_child(controls_grid)
	
	# Add control mappings
	add_control_mapping(controls_grid, "Movement", "WASD or Arrow Keys")
	add_control_mapping(controls_grid, "Run", "Hold Shift")
	add_control_mapping(controls_grid, "Dance", "Space Bar")
	add_control_mapping(controls_grid, "Camera", "Mouse Movement")
	add_control_mapping(controls_grid, "Pause", "ESC")
	add_control_mapping(controls_grid, "Objective", "Collect Ship Parts")
	
	# Bottom padding
	var btm_pad = Control.new()
	btm_pad.custom_minimum_size = Vector2(0, 10)
	bottom_container.add_child(btm_pad)
	
	# Store reference to the UI
	canvas.set_meta("ui_elements", {"content_box": content_box, "button": button})

func add_control_mapping(grid, action, keys):
	var action_label = Label.new()
	action_label.text = action + ":"
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	action_label.add_theme_font_size_override("font_size", 16)
	action_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
	grid.add_child(action_label)
	
	var keys_label = Label.new()
	keys_label.text = keys
	keys_label.add_theme_font_size_override("font_size", 16)
	keys_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	grid.add_child(keys_label)

func create_pause_ui():
	# Create a CanvasLayer for the pause UI
	var canvas = CanvasLayer.new()
	canvas.name = "PauseUI"
	add_child(canvas)
	
	# Create the UI container
	var ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui)
	
	# Create a semi-transparent background with star field
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.15, 0.9)  # Deep space blue with transparency
	ui.add_child(bg)
	
	# Add animated stars to the background
	for i in range(70):
		# Create a round star using PanelContainer
		var star = PanelContainer.new()
		var size = randf_range(1, 3)
		star.custom_minimum_size = Vector2(size, size)
		star.position = Vector2(randf_range(0, 1024), randf_range(0, 600))
		
		# Add twinkling effect with random colors
		var color_choice = randi() % 10
		var star_color
		if color_choice < 7:
			star_color = Color(1, 1, 1, randf_range(0.5, 1.0))  # White stars with varying brightness
		elif color_choice < 8:
			star_color = Color(0.7, 0.7, 1.0, 1.0)  # Bluish stars
		elif color_choice < 9:
			star_color = Color(1.0, 0.7, 0.7, 1.0)  # Reddish stars
		else:
			star_color = Color(1.0, 1.0, 0.7, 1.0)  # Yellowish stars
		
		# Create round style
		var star_style = StyleBoxFlat.new()
		star_style.bg_color = star_color
		star_style.corner_radius_top_left = int(size / 2)
		star_style.corner_radius_top_right = int(size / 2)
		star_style.corner_radius_bottom_left = int(size / 2)
		star_style.corner_radius_bottom_right = int(size / 2)
		star.add_theme_stylebox_override("panel", star_style)
		
		# Create a timer for the star to create twinkling effect
		var timer = Timer.new()
		timer.wait_time = randf_range(0.5, 3.0)  # Random timing
		timer.autostart = true
		timer.one_shot = false
		bg.add_child(timer)
		
		# Connect timer to a lambda that will make star twinkle
		timer.timeout.connect(func(): 
			var tween = create_tween()
			tween.tween_property(star, "modulate", Color(1, 1, 1, randf_range(0.2, 1.0)), 0.5)
			tween.tween_property(star, "modulate", Color(1, 1, 1, randf_range(0.5, 1.0)), 0.5)
		)
		
		bg.add_child(star)
	
	# Add floating planets with rotation
	var planet_colors = [
		Color(0.7, 0.3, 0.9, 1.0),  # Purple
		Color(0.3, 0.7, 0.9, 1.0),  # Blue
		Color(1.0, 0.6, 0.2, 1.0)   # Orange
	]
	
	for i in range(3):
		var planet_container = Control.new()
		planet_container.size = Vector2(80, 80)
		planet_container.position = Vector2(randf_range(50, 974), randf_range(50, 550))
		bg.add_child(planet_container)
		
		# Create a round planet using PanelContainer
		var planet = PanelContainer.new()
		var size = randf_range(30, 60)
		planet.custom_minimum_size = Vector2(size, size)
		planet.position = Vector2((80-size)/2, (80-size)/2)
		
		# Make it circular by setting corner radius
		var planet_style = StyleBoxFlat.new()
		planet_style.bg_color = planet_colors[i]
		planet_style.corner_radius_top_left = int(size / 2)
		planet_style.corner_radius_top_right = int(size / 2)
		planet_style.corner_radius_bottom_left = int(size / 2)
		planet_style.corner_radius_bottom_right = int(size / 2)
		planet.add_theme_stylebox_override("panel", planet_style)
		planet_container.add_child(planet)
		
		# Create a tween for continuous rotation
		var tween = create_tween()
		tween.tween_property(planet_container, "rotation_degrees", 360, randf_range(20, 40))
		tween.set_loops()
		
		# Create a tween for floating movement
		var move_tween = create_tween()
		var target_pos = Vector2(
			planet_container.position.x + randf_range(-50, 50),
			planet_container.position.y + randf_range(-50, 50)
		)
		move_tween.tween_property(planet_container, "position", target_pos, randf_range(5, 10))
		move_tween.tween_property(planet_container, "position", planet_container.position, randf_range(5, 10))
		move_tween.set_loops()
	
	# Create center container
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(center_container)
	
	# Create a panel for the pause menu
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.2, 0.8)
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.3, 0.6, 0.9, 1.0)
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	center_container.add_child(panel)
	
	# Content container
	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(400, 0)
	content.add_theme_constant_override("separation", 15)
	panel.add_child(content)
	
	# Add some padding at the top
	var top_pad = Control.new()
	top_pad.custom_minimum_size = Vector2(0, 15)
	content.add_child(top_pad)
	
	# Add pause title
	var title = Label.new()
	title.text = "MISSION PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))  # Golden text
	title.add_theme_color_override("font_shadow_color", Color(0.9, 0.4, 0.1, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(title)
	
	# Animate the title with a subtle floating effect
	var title_tween = create_tween()
	title_tween.tween_property(title, "position:y", title.position.y - 5, 1.0)
	title_tween.tween_property(title, "position:y", title.position.y, 1.0)
	title_tween.set_loops()
	
	# Divider
	var divider = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.5, 0.7, 1.0, 0.5)
	sep_style.thickness = 2
	divider.add_theme_stylebox_override("separator", sep_style)
	content.add_child(divider)
	
	# Add mission objective reminder
	var objective = Label.new()
	objective.text = "Mission Objective: Collect all ship parts to repair your vessel and return home."
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_font_size_override("font_size", 16)
	objective.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
	content.add_child(objective)
	
	# Add a small divider for visual separation
	var controls_divider = HSeparator.new()
	var ctrl_sep_style = StyleBoxLine.new()
	ctrl_sep_style.color = Color(0.5, 0.7, 1.0, 0.5)
	ctrl_sep_style.thickness = 1
	controls_divider.add_theme_stylebox_override("separator", ctrl_sep_style)
	content.add_child(controls_divider)
	
	# Controls reminder container - make it MUCH more visible
	# Use the full width of the content area
	var controls_container = VBoxContainer.new()
	controls_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_container.size_flags_vertical = Control.SIZE_EXPAND_FILL  # Take available space
	controls_container.custom_minimum_size = Vector2(0, 200)  # Taller for better visibility
	content.add_child(controls_container)
	
	# Make the controls panel very prominent with bright border
	var controls_bg = PanelContainer.new()
	controls_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var controls_bg_style = StyleBoxFlat.new()
	controls_bg_style.bg_color = Color(0.05, 0.1, 0.2, 0.95)  # Darker but more opaque
	controls_bg_style.corner_radius_top_left = 15
	controls_bg_style.corner_radius_top_right = 15
	controls_bg_style.corner_radius_bottom_left = 15
	controls_bg_style.corner_radius_bottom_right = 15
	controls_bg_style.border_width_left = 4  # Thick border
	controls_bg_style.border_width_right = 4
	controls_bg_style.border_width_top = 4
	controls_bg_style.border_width_bottom = 4
	controls_bg_style.border_color = Color(0.6, 0.8, 1.0, 1.0)  # Very bright border
	controls_bg_style.shadow_color = Color(0, 0, 0, 0.5)
	controls_bg_style.shadow_size = 5
	controls_bg.add_theme_stylebox_override("panel", controls_bg_style)
	controls_container.add_child(controls_bg)
	
	# Add padding inside the panel
	var controls_inner = MarginContainer.new()
	controls_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_inner.add_theme_constant_override("margin_left", 15)
	controls_inner.add_theme_constant_override("margin_right", 15)
	controls_inner.add_theme_constant_override("margin_top", 15)
	controls_inner.add_theme_constant_override("margin_bottom", 15)
	controls_bg.add_child(controls_inner)
	
	# Add a VBox for the content
	var controls_vbox = VBoxContainer.new()
	controls_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_vbox.add_theme_constant_override("separation", 15)
	controls_inner.add_child(controls_vbox)
	
	# Add a prominent title
	var controls_title = Label.new()
	controls_title.text = "ASTRONAUT CONTROLS"
	controls_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_title.add_theme_font_size_override("font_size", 24)  # Larger
	controls_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	controls_title.add_theme_color_override("font_shadow_color", Color(0.9, 0.4, 0.1, 0.8))
	controls_title.add_theme_constant_override("shadow_offset_x", 2)
	controls_title.add_theme_constant_override("shadow_offset_y", 2)
	controls_vbox.add_child(controls_title)
	
	# Add a grid for the controls
	var controls_grid = GridContainer.new()
	controls_grid.columns = 2
	controls_grid.add_theme_constant_override("h_separation", 30)  # More horizontal space
	controls_grid.add_theme_constant_override("v_separation", 12)  # More vertical space
	controls_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls_vbox.add_child(controls_grid)
	
	# Add control mappings with larger font
	add_control_mapping_large(controls_grid, "Movement", "WASD or Arrow Keys")
	add_control_mapping_large(controls_grid, "Run", "Hold Shift")
	add_control_mapping_large(controls_grid, "Dance", "Space Bar")
	add_control_mapping_large(controls_grid, "Camera", "Mouse Movement")
	add_control_mapping_large(controls_grid, "Pause", "ESC")
	add_control_mapping_large(controls_grid, "Objective", "Collect Ship Parts")
	
	# Add resume button
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(button_container)
	
	var resume_button = Button.new()
	resume_button.text = "RESUME MISSION"
	resume_button.add_theme_font_size_override("font_size", 22)
	resume_button.custom_minimum_size = Vector2(200, 50)
	
	# Style the button
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.6, 0.8, 1.0)  # Blue button
	button_style.border_width_bottom = 4
	button_style.border_color = Color(0.1, 0.3, 0.5, 1.0)
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_left = 10
	button_style.corner_radius_bottom_right = 10
	resume_button.add_theme_stylebox_override("normal", button_style)
	
	# Hover style
	var hover_style = button_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.7, 0.9, 1.0)  # Lighter blue on hover
	resume_button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = button_style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.45, 0.7, 1.0)  # Darker blue when pressed
	pressed_style.border_width_bottom = 2
	resume_button.add_theme_stylebox_override("pressed", pressed_style)
	
	button_container.add_child(resume_button)
	
	# Pulse animation for the button
	var button_tween = create_tween()
	button_tween.tween_property(resume_button, "scale", Vector2(1.05, 1.05), 0.8)
	button_tween.tween_property(resume_button, "scale", Vector2(1.0, 1.0), 0.8)
	button_tween.set_loops()
	
	# Connect the button signal
	resume_button.connect("pressed", toggle_pause)
	
	# Add ESC help text
	var help_text = Label.new()
	help_text.text = "Press ESC to Resume"
	help_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_text.add_theme_font_size_override("font_size", 16)
	help_text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.7))
	content.add_child(help_text)
	
	# Add some padding at the bottom
	var bottom_pad = Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, 15)
	content.add_child(bottom_pad)

# Add a new function for larger control mappings in the pause screen
func add_control_mapping_large(grid, action, keys):
	var action_label = Label.new()
	action_label.text = action + ":"
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	action_label.add_theme_font_size_override("font_size", 18)  # Larger font
	action_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
	grid.add_child(action_label)
	
	var keys_label = Label.new()
	keys_label.text = keys
	keys_label.add_theme_font_size_override("font_size", 18)  # Larger font
	keys_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	grid.add_child(keys_label)

func _on_test_button_pressed():
	# Directly change to the departure scene
	get_tree().change_scene_to_file("res://scenes/departure_scene.tscn") 
