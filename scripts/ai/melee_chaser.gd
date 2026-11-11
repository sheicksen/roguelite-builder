class_name MeleeChaser
extends BaseEnemy

## Basic melee enemy AI.
## Detects the player, approaches them,
## and attacks when within range.

@export_group("AI Behavior")
@export var detection_range: float = 250.0
@export var attack_range: float = 32.0

@export_group("Combat")
@export var equipped_ability: AbilityData

var target: Player
var melee_ability: Ability

func _ready() -> void:
	super._ready()

	# Default to a Knife if no ability is assigned.
	var config: AbilityData = KnifeConfig.new()

	# Use the configured ability if one is provided.
	if equipped_ability != null:
		config = equipped_ability.duplicate(true) as AbilityData

	# Enemy attacks should target the player.
	config.stats = AttackStats.new(
		attack_damage,
		attack_damage_type,
		[BaseStats.Faction.PLAYER]
	)

	# Create the ability and attach it to the enemy.
	melee_ability = Ability.new("EnemyAttack", config)
	add_child(melee_ability)


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
		# Player is within attack range.
		velocity.x = 0.0

		# Determine which direction the enemy is facing.
		var facing: int = 1 if direction >= 0.0 else -1

		# Use the equipped melee ability.
		melee_ability.use_ability(self, facing)

	# Let BaseEnemy handle gravity and move_and_slide().
	super._physics_process(delta)
