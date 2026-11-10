class_name MeleeChaser
extends BaseEnemy

## Basic melee enemy AI.
## Detects the player, approaches them,
## and attacks when within range.

@export_group("AI Behavior")
@export var detection_range: float = 250.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.5

var target: Player
var _attack_cooldown_remaining: float = 0.0

func _physics_process(delta: float) -> void:
	# Find the player if we don't already have a valid target.
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Player

	# Stop moving if there's no player.
	if target == null:
		velocity.x = 0.0
		super._physics_process(delta)
		return

	# Calculate distance and direction to the player.
	var distance = global_position.distance_to(target.global_position)
	var direction = target.global_position.x - global_position.x

	if distance > detection_range:
		# Player is too far away. Stay idle.
		velocity.x = 0.0

	elif distance > attack_range:
		# Player is detected but not close enough to attack.
		velocity.x = signf(direction) * move_speed

	else:
		# Player is within attack range. Stop moving.
		velocity.x = 0.0

	# Let BaseEnemy handle gravity and move_and_slide().
	super._physics_process(delta)
