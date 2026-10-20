extends GutTest

func test_enemy_initializes_stats() -> void:
	# Load the enemy scene.
	var enemy_scene = load("res://scenes/Enemy.tscn")

	# Create an enemy instance.
	var enemy = enemy_scene.instantiate()

	# Add it to the scene tree so _ready() runs.
	# GUT will clean it up after the test.
	add_child_autofree(enemy)

	# Check that the enemy has stats.
	assert_not_null(enemy.stats)

	# Check the starting values.
	assert_eq(enemy.stats.health, enemy.max_health)
	assert_eq(enemy.stats.speed, enemy.move_speed)
	assert_eq(
		enemy.stats.faction,
		BaseStats.Faction.ENEMY
	)

func test_enemy_takes_damage() -> void:
	# Create an enemy from our scene.
	var enemy = load("res://scenes/Enemy.tscn").instantiate()

	# Set known starting values.
	enemy.max_health = 100
	enemy.defense = 0

	# Add the enemy so _ready() executes.
	add_child_autofree(enemy)

	# Create an attack dealing 25 damage.
	var attack = AttackStats.new(
		25,
		BaseStats.DamageType.DEFAULT,
		[BaseStats.Faction.ENEMY]
	)

	# Simulate the enemy receiving the attack.
	enemy.hurtbox.receive_hit(attack)

	# Check the enemy's remaining health.
	assert_eq(
		enemy.stats.health,
		75,
        "Enemy should have 75 health after taking 25 damage"
	)

	# Make sure the enemy is still alive.
	assert_false(enemy.is_queued_for_deletion())


func test_enemy_dies_at_zero_health() -> void:
	# Create an enemy with 100 HP and no defense.
	var enemy = load("res://scenes/Enemy.tscn").instantiate()
	enemy.max_health = 100
	enemy.defense = 0

	add_child_autofree(enemy)

	# Create an attack that deals lethal damage.
	var attack = AttackStats.new(
		100,
		BaseStats.DamageType.DEFAULT,
		[BaseStats.Faction.ENEMY]
	)

	# Apply the attack through the hurtbox.
	enemy.hurtbox.receive_hit(attack)

	# Health should reach zero.
	assert_eq(
		enemy.stats.health,
		0,
        "Enemy health should be zero"
	)

	# The enemy should be scheduled for removal.
	assert_true(
		enemy.is_queued_for_deletion(),
        "Enemy should be queued for deletion when killed"
	)
