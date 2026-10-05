extends CharacterBody2D

# NOT INTENDED FOR FINAL PRODUCT USE

const JUMP_VELOCITY = -400.0

var ability_1_stats: AttackStats = AttackStats.new(20, 0, [2])
var ability_2_stats: AttackStats = AttackStats.new(10, 0, [2, 3])
var player_stats: EntityStats = EntityStats.new("Player", 1, 100, 300)
var facing = 1


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_1") and not event.is_echo():
		var hitbox = Hitbox.new(ability_1_stats, 0.0, ability_shape)
		hitbox.position.x = facing * 50
		add_child(hitbox)
		
	if event.is_action_pressed("ability_2") and not event.is_echo():
		var hitbox = Hitbox.new(ability_2_stats, 0.5, ability_shape)
		hitbox.position.x = facing * 50
		add_child(hitbox)
		

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		facing = direction
		velocity.x = direction *  player_stats.speed
	else:
		velocity.x = move_toward(velocity.x, 0, player_stats.speed)

	move_and_slide()
	
@onready var ability_shape:CircleShape2D =  CircleShape2D.new()
@onready var hurtbox_shape:CapsuleShape2D = $CollisionShape2D.shape
@onready var player_hurtbox: Hurtbox = Hurtbox.new(player_stats, 0.0, hurtbox_shape)

func _ready() -> void:
	ability_shape.radius = 20.0
	add_child(player_hurtbox)
