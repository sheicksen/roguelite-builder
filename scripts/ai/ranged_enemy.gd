class_name RangedEnemy
extends BaseEnemy

## Ranged enemy AI.
## Maintains distance from the player and uses projectile abilities.

@export_group("AI Behavior")
@export var detection_range: float = 500.0
@export var preferred_range: float = 250.0
@export var minimum_range: float = 150.0

@export_group("Combat")
@export var equipped_ability: ProjectileData

var target: Player
var ranged_ability: RangedAbility

func _ready() -> void:
	# Initialize BaseEnemy's stats and components.
	super._ready()

	# Default to Poison Gun if no ability is assigned.
	var config: ProjectileData = PoisonGunConfig.new()

	# Use the configured projectile ability if one exists.
	if equipped_ability != null:
		config = equipped_ability.duplicate(false) as ProjectileData

	# Enemy projectiles should damage players, not enemies.
	config.stats = AttackStats.new(
		attack_damage,
		attack_damage_type,
		[BaseStats.Faction.PLAYER]
	)

	# Create and attach the ranged ability.
	ranged_ability = RangedAbility.new("EnemyProjectile", config)
	add_child(ranged_ability)


func _physics_process(delta: float) -> void:
	# Find the player if we don't have a valid target.
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Player

	# No player found, stop moving.
	if target == null:
		velocity.x = 0.0
		super._physics_process(delta)
		return

	# Calculate distance and direction to the player.
	var distance: float = global_position.distance_to(target.global_position)
	var direction: float = target.global_position.x - global_position.x

	# Determine which direction we're facing.
	var facing: int = 1 if direction >= 0.0 else -1

	if distance > detection_range:
		# Player is too far away. Stay idle.
		velocity.x = 0.0

	elif distance < minimum_range:
		# Player is too close. Move away.
		velocity.x = -signf(direction) * move_speed

	elif distance > preferred_range:
		# Player is too far away. Move closer.
		velocity.x = signf(direction) * move_speed

	else:
		# We're at a good distance. Stop moving.
		velocity.x = 0.0

	# Fire while the player is within detection range.
	if distance <= detection_range:
		ranged_ability.use_ability(self, facing)

	# Let BaseEnemy handle gravity and collisions.
	super._physics_process(delta)
