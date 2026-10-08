class_name Player extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const FRICTION = 0

var jump_height: int
var friction: int
var health_recovery: float
var max_stamina: int
var stamina: int
var stamina_recovery: float
var can_jump: bool
var hurtbox: Hurtbox
var abilities: Array

func _init(
	_name: String = "Player",
	_faction: int = 1,
	_health: int = 100,
	_stamina: int = 100,
	_abilities: Array = [],
	_jump_height: int = -400
	
) -> void:
	jump_height = JUMP_VELOCITY
	friction = FRICTION

## Create hitbox


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_height

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * hurtbox.stats.speed
	else:
		velocity.x = move_toward(velocity.x, 0, hurtbox.stats.speed)

	move_and_slide()
