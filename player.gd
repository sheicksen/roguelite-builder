extends CharacterBody2D

@export var speed: float = 250.0

func _physics_process(_delta):
	var direction = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
        "ui_down"
	)

	velocity = direction * speed
	move_and_slide()
	
