class_name Player extends CharacterBody2D

# Default values used
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const AIR_FRICTION = 150.0
const FRICTION = 0
const JUMP_LENIENCY = 0.2

# Player specific stats
var stats: EntityStats # Passed into hurtbox
var health_recovery: float
var max_stamina: int 
var stamina: int
var stamina_recovery: float

# Player's Children
var hurtbox: Hurtbox
var abilities: Array


# Jump handling.
var can_jump: bool = true
var num_jumps: int = 1
var jump_timer: Timer
var jumps_made: int = 0

# Movement feel
var jump_height: int = JUMP_VELOCITY
var friction: int = 0
var air_friction: int = 0

# Visuals
@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _init(
	_name: String = "Player",
	_faction: int = 1,
	_health: int = 100,
	_speed: int = 300,
	_stamina: int = 100,
	_abilities: Array = [],
	
) -> void:
	friction = FRICTION
	stats = EntityStats.new(_name, _faction, _health, _speed)
	jump_timer = Timer.new()
	jump_timer.set_one_shot(true)
	add_child(jump_timer)
	jump_timer.timeout.connect(disable_jump)

func _ready() -> void:
	hurtbox = Hurtbox.new(stats, 0, $CollisionShape2D.shape)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if is_on_floor():
		air_friction = 0
		if not can_jump:
			can_jump = true
		jumps_made = 0
		
	if not is_on_floor():
		if velocity.x == 0:
			air_friction = AIR_FRICTION
		velocity += get_gravity() * delta
		if jump_timer.get_time_left() <= 0.0 and jumps_made == 0:
			# print("Timer started")
			jump_timer.call_deferred("start", JUMP_LENIENCY)
		
	# Handle jump.
	if Input.is_action_just_pressed("jump") and can_jump:
		if jumps_made < num_jumps:
			# print("Jump made")
			jumps_made += 1
			velocity.y = jump_height

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		if direction > 0:
			player_sprite.flip_h = true
		else:
			player_sprite.flip_h = false
			
		velocity.x = direction * (hurtbox.stats.speed - air_friction)
	else:
		velocity.x = move_toward(velocity.x, 0, hurtbox.stats.speed - air_friction)
	
	if is_on_floor():
		if velocity.x != 0:
			player_sprite.play("walk")
		else:
			player_sprite.play("idle")
	else:
		player_sprite.play("jump")

	move_and_slide()
	
	
func disable_jump() -> void:
	# print("Jump disabled")
	if jumps_made >= num_jumps - 1:
		can_jump = false

func add_jump(amount:int) -> int:
	if amount < 0:
		push_error("Cannot add negative jumps")
		return -1
	num_jumps += amount
	return num_jumps
