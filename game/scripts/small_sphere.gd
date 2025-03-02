extends Area3D

func _ready():
    # Connect the body entered signal
    body_entered.connect(_on_body_entered)
    print("Hex nut ready for collection")

func _on_body_entered(body: Node3D):
    if body.is_in_group("player"):
        print("Player touched hex nut!")
        # Call collect_sphere on the player
        body.collect_sphere()
        # Remove the hex nut
        queue_free() 