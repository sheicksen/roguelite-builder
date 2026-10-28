class_name Player extends CharacterBody2D

# Default values used
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const AIR_FRICTION = 150.0
const JUMP_LENIENCY = 0.2

# Player specific stats
var stats: EntityStats # Passed into hurtbox
var health_recovery: float = 0
var max_stamina: int = 100
var stamina: float = 100
var stamina_recovery: float = 0.05

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
var air_friction: int = 0

var sprint_boost: int       # Amount speed is increased by when sprinting
var sprinting = false       # Tracks if the character is currently sprinting
var current_speed: int      # manages current speed (stats.speed + speed boost)

var crouching: bool = false
# Visuals
@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

func _init(
	_name: String = "Player",
	_faction: int = 1,
	_health: int = 100,
	_speed: int = 300,
	_sprint_boost: int = 200,
	_stamina: int = 100,
	_abilities: Array = [],
	
) -> void:
	sprint_boost = _sprint_boost
	current_speed = _speed
	stats = EntityStats.new(_name, _faction, _health, _speed)
	jump_timer = Timer.new()
	jump_timer.set_one_shot(true)
	add_child(jump_timer)
	jump_timer.timeout.connect(disable_jump)
	
	stats.speed_changed.connect(update_speed)

func _ready() -> void:
	hurtbox = Hurtbox.new(stats, 0, $PlayerCollider.shape)

func _physics_process(delta: float) -> void:
	if sprinting:
		drain_stamina.call_deferred()
	else:
		regain_stamina.call_deferred()
	# Enable jumping and sprinting if character is in contact with the floor
	if is_on_floor():
		air_friction = 0
		if not can_jump:
			can_jump = true
		jumps_made = 0
		
		if Input.is_action_just_pressed("sprint"):
			if stamina > 0:
				sprint()
		if Input.is_action_just_released("sprint") or stamina <= 0:
			print("Sprint ended")
			end_sprint()
		
	# Handle falling, jump forgiveness, and apply air friction
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

	if Input.is_action_just_pressed("crouch"):
		toggle_crouch.call_deferred()
		
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		if direction > 0:
			player_sprite.flip_h = true
		else:
			player_sprite.flip_h = false
			
		velocity.x = direction * (current_speed - air_friction)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed - air_friction)
	
	if is_on_floor():
		if velocity.x != 0:
			player_sprite.play("walk")
		else:
			player_sprite.play("idle")
	else:
		player_sprite.play("jump")

	move_and_slide()

var offset: int = 0
func _process(_delta: float) -> void:
	if Input.is_action_pressed("look_down") and is_on_floor():
		if camera.offset.y < 100:
			camera.offset.y += 5
	elif camera.offset.y > 0:
		camera.offset.y -= 5
	
func disable_jump() -> void:
	if jumps_made >= num_jumps - 1:
		can_jump = false

func add_jump(amount:int) -> int:
	if amount < 0:
		push_error("Cannot add negative jumps")
		return -1
	num_jumps += amount
	return num_jumps

func sprint() -> void:
	if not sprinting:
		sprinting = true
		player_sprite.speed_scale = 3.0
		current_speed = stats.speed + sprint_boost

func end_sprint() -> void:
	if sprinting:
		sprinting = false
		player_sprite.speed_scale = 1.0
		current_speed = stats.speed

func update_speed() -> int:
	if sprinting:
		current_speed = stats.speed + sprint_boost
	else:
		current_speed = stats.speed
	return current_speed
	
func drain_stamina() -> float:
	var new_stamina = stamina - 0.2
	if new_stamina < 0:
		new_stamina = 0
	stamina = new_stamina
	return stamina

func regain_stamina() -> float:
	var new_stamina = stamina + stamina_recovery
	if new_stamina >= max_stamina:
		new_stamina = max_stamina
	stamina = new_stamina
	return stamina
	
func toggle_crouch() -> void:
	if crouching and not $RoofCheckRay.is_colliding():
		crouching = false
		$PlayerCollider.scale.y = 1
	else:
		crouching = true
		$PlayerCollider.scale.y = 0.5
	
