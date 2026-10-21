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


func test_enemy_hitbox_setup() -> void:
	# Create an enemy.
	var enemy = load("res://scenes/Enemy.tscn").instantiate()

	# Configure the enemy's attack.
	enemy.attack_damage = 25
	enemy.attack_damage_type = BaseStats.DamageType.FIRE
	enemy.attack_hitbox_size = Vector2(48, 24)

	var target_layers: Array[int] = [BaseStats.Faction.PLAYER]
	enemy.attack_target_layers = target_layers

	add_child_autofree(enemy)

	# Verify that the hitbox was created.
	assert_not_null(enemy.hitbox)

	# Verify its damage properties.
	assert_eq(enemy.hitbox.attack_effects.damage, 25)
	assert_eq(
		enemy.hitbox.attack_effects.damage_type,
		BaseStats.DamageType.FIRE
	)

	# Verify the target layer.
	assert_has(
		enemy.hitbox.attack_effects.targets,
		BaseStats.Faction.PLAYER
	)

	# Verify the attack shape.
	var shape := enemy.hitbox.shape as RectangleShape2D
	assert_not_null(shape)

	if shape != null:
		assert_eq(shape.size, Vector2(48, 24))

	# Attacks should be disabled by default.
	assert_false(enemy.hitbox.monitoring)

func test_enemy_attack_activation() -> void:
	# Create an enemy with a short attack duration.
	var enemy: BaseEnemy = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.attack_duration = 0.05

	add_child_autofree(enemy)

	# Hitbox should start disabled.
	assert_false(enemy.hitbox.monitoring)

	# Activate the attack.
	enemy.attack()

	# Hitbox should now be enabled.
	assert_true(enemy.hitbox.monitoring)

	# Wait for the attack to finish.
	await wait_seconds(0.15)

	# Hitbox should automatically turn off.
	assert_false(enemy.hitbox.monitoring)


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


func test_enemy_attack_damages_target() -> void:
	# Create the enemy.
	var enemy: BaseEnemy = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.attack_damage = 20
	enemy.attack_duration = 0.25
	add_child_autofree(enemy)

	# Create a target belonging to the player faction.
	var target_stats := EntityStats.new(
		"Test Player",
		BaseStats.Faction.PLAYER,
		100,
		0
	)

	# Give the target a physical hurtbox.
	var target_shape := RectangleShape2D.new()
	target_shape.size = Vector2(32, 32)

	var target_hurtbox := Hurtbox.new(
		target_stats,
		0.0,
		target_shape
	)

	add_child_autofree(target_hurtbox)

	# Place the target within attack range.
	target_hurtbox.global_position = enemy.global_position

	# Allow the collision system to initialize.
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Activate the enemy's attack.
	enemy.attack()

	# Allow Godot to detect the overlap.
	await get_tree().physics_frame
	await get_tree().physics_frame

	# The player should have taken 20 damage.
	assert_eq(
		target_stats.health,
		80,
		"Enemy attack should deal 20 damage"
	)

func test_enemy_ability_cooldowns() -> void:
	var enemy: BaseEnemy = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	# Configure two abilities.
	var ability_list: Array[String] = ["Fireball", "Dash"]
	enemy.abilities = ability_list

	enemy.ability_cooldown = 4.0
	enemy.ability_recovery_rate = 2.0

	add_child_autofree(enemy)

	# Fireball should initially be available.
	assert_true(enemy.can_use_ability("Fireball"))

	# An unassigned ability should be unavailable.
	assert_false(enemy.can_use_ability("Teleport"))

	# Start Fireball's cooldown.
	assert_true(enemy.try_start_ability_cooldown("Fireball"))

	# Fireball should now be unavailable.
	assert_false(enemy.can_use_ability("Fireball"))

	# Dash should still be available.
	assert_true(enemy.can_use_ability("Dash"))

	# One second at 2x recovery removes 2 seconds.
	enemy.update_ability_cooldowns(1.0)
	assert_false(enemy.can_use_ability("Fireball"))

	# Another second finishes the cooldown.
	enemy.update_ability_cooldowns(1.0)
	assert_true(enemy.can_use_ability("Fireball"))


func test_enemy_climbing() -> void:
	var enemy: BaseEnemy = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	add_child_autofree(enemy)

	# Climbing is disabled by default.
	assert_false(enemy.can_climb)
	assert_false(enemy.try_start_climb(true))

	# Enable climbing.
	enemy.can_climb = true

	# Cannot climb without a climbable surface.
	assert_false(enemy.try_start_climb(false))

	# Enter a valid climbing area.
	assert_true(enemy.try_start_climb(true))
	assert_true(enemy.is_climbing)

	# Move upward.
	enemy.set_climb_direction(-1.0)
	assert_eq(enemy.velocity.y, -enemy.climb_speed)

	# Stop climbing.
	enemy.stop_climb()
	assert_false(enemy.is_climbing)
	assert_eq(enemy.velocity.y, 0.0)
