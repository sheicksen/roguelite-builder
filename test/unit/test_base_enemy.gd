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


func test_enemy_health_regeneration() -> void:
	# Create an enemy with 100 health.
	var enemy = load("res://scenes/Enemy.tscn").instantiate()
	enemy.max_health = 100
	enemy.defense = 0
	enemy.health_recovery_rate = 2.0

	add_child_autofree(enemy)

	# Damage the enemy by 20 HP.
	enemy.hurtbox.receive_hit(
		AttackStats.new(
			20,
			BaseStats.DamageType.DEFAULT,
			[BaseStats.Faction.ENEMY]
		)
	)

	assert_eq(enemy.stats.health, 80)

	# Simulate half a second of regeneration.
	enemy.recover_health(0.5)
	assert_eq(enemy.stats.health, 81)

	# Simulate another second.
	enemy.recover_health(1.0)
	assert_eq(enemy.stats.health, 83)

	# Regeneration cannot exceed maximum health.
	enemy.recover_health(20.0)
	assert_eq(enemy.stats.health, 100)


func test_enemy_jump_configuration() -> void:
	var enemy: BaseEnemy = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.can_jump = false
	enemy.jump_height = 64.0

	add_child_autofree(enemy)

	# Allow Godot's physics system to initialize.
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Jumping should be disabled.
	assert_false(enemy.try_jump())

	# Check the configured jump height.
	assert_eq(enemy.jump_height, 64.0)

	# Jump velocity should point upward.
	assert_true(enemy.get_jump_velocity() < 0.0)

	# Verify that jumping can be enabled.
	enemy.can_jump = true
	assert_true(enemy.can_jump)


## Verify that an enemy's equipped ability damages
## a target through the current ability system.
func test_enemy_equipped_ability_damages_target() -> void:
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.attack_damage = 20
	add_child_autofree(enemy)

	# Keep the enemy stationary during the test.
	enemy.set_physics_process(false)

	# Create a target belonging to the player faction.
	var target_stats := EntityStats.new(
		"Test Player",
		BaseStats.Faction.PLAYER,
		100,
		0
	)

	var target_shape := RectangleShape2D.new()
	target_shape.size = Vector2(32, 32)

	var target_hurtbox := Hurtbox.new(
		target_stats,
		0.0,
		target_shape
	)

	add_child_autofree(target_hurtbox)

	# Place the target within the Knife's hitbox.
	target_hurtbox.global_position = (
		enemy.global_position + Vector2(30, 0)
	)

	# Allow physics to initialize.
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Attack using the equipped ability,
	# not the removed BaseEnemy.attack() method.
	enemy.active_ability.use_ability(enemy, 1)

	# Allow the new hitbox to detect the target.
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_eq(
		target_stats.health,
		80,
		"Equipped ability should deal 20 damage."
	)
