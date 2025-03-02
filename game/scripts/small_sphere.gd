extends Area3D

func _ready():
	# Connect the body entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	# Check if the colliding body is in the "player" group
	if body.is_in_group("player"):
		# Call the collect_sphere method on the player
		body.collect_sphere()
		# Remove this hex nut from the scene
		queue_free() 
