extends Control

signal joystick_input(input: Vector2)
signal dance_pressed

@onready var joystick = $Joystick
@onready var joystick_base = $Joystick/Base
@onready var joystick_knob = $Joystick/Base/Knob
@onready var dance_button = $DanceButton

var joystick_active = false
var joystick_max_distance = 100.0

func _ready():
	# Check if we're on a touch-enabled device
	var is_touch_enabled = DisplayServer.is_touchscreen_available()
	var is_mobile = OS.has_feature("mobile")
	
	# Only show controls on touch devices
	visible = is_touch_enabled or is_mobile
	if visible:
		print("Touch controls enabled - touch screen or mobile detected")
	else:
		print("Touch controls disabled - no touch screen detected")
		return
	
	modulate.a = 1.0
	
	# Set up joystick initial state
	reset_joystick()
	
	# Make sure controls are on top
	top_level = true
	
	# Connect dance button signal
	dance_button.pressed.connect(_on_dance_button_pressed)

func reset_joystick():
	joystick_active = false
	# Center the knob in the base
	if joystick_knob and joystick_base:
		joystick_knob.position = Vector2.ZERO
		joystick_knob.anchors_preset = Control.PRESET_CENTER
		print("Reset joystick to center")

func _input(event):
	if event is InputEventScreenTouch:
		print("Touch event detected: ", event.position)
		
		# Convert global touch position to local position within joystick base
		var touch_pos = joystick_base.get_global_rect().has_point(event.position)
		
		if event.pressed:
			if touch_pos:  # Touch is within joystick base
				joystick_active = true
				# Convert touch to local position
				var local_pos = joystick_base.get_local_mouse_position()
				move_knob(local_pos - joystick_base.size / 2)
				print("Joystick activated")
		else:  # Touch released
			if joystick_active:
				reset_joystick()
				joystick_input.emit(Vector2.ZERO)
				print("Joystick released")
	
	elif event is InputEventScreenDrag and joystick_active:
		# Convert drag to local position
		var local_pos = joystick_base.get_local_mouse_position()
		move_knob(local_pos - joystick_base.size / 2)

func move_knob(delta: Vector2):
	var distance = delta.length()
	
	if distance > joystick_max_distance:
		delta = delta.normalized() * joystick_max_distance
	
	joystick_knob.position = delta
	
	# Emit normalized input vector (reversed Y for correct forward direction)
	var input = delta / joystick_max_distance
	input.y = -input.y  # Reverse Y axis
	joystick_input.emit(input)
	print("Joystick input: ", input)

func _on_dance_button_pressed():
	print("Dance button pressed")
	dance_pressed.emit() 