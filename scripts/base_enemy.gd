class_name BaseEnemy
extends CharacterBody2D

## Base class for configurable enemies.
## Handles stats, damage, recovery, movement options, and abilities.

# --- Enemy Configuration ---

@export_group("Stats")
@export var enemy_name: String = "Basic Enemy"
@export var max_health: int = 100
@export var move_speed: int = 100
@export var defense: int = 0

@export_group("Movement")
@export var jump_height: float = 64.0
@export var can_jump: bool = false
@export var can_climb: bool = false
@export var climb_speed: float = 100.0

@export_group("Abilities")
# Ability names; actual effects will be handled by other systems.
@export var abilities: Array[String] = []
@export var ability_recovery_rate: float = 1.0
@export var ability_cooldown: float = 3.0

@export_group("Recovery")
@export var health_recovery_rate: float = 0.0

@export_group("Attack")
@export var attack_damage: int = 10

@export_range(0.05, 5.0, 0.05)
var attack_duration: float = 0.25

@export_enum("Default", "Fire", "Poison", "Ice", "Corrupted")
var attack_damage_type: int = BaseStats.DamageType.DEFAULT

@export var attack_hitbox_size: Vector2 = Vector2(32, 32)

# Uses physics collision layer numbers (1-based).
@export var attack_target_layers: Array[int] = [
	BaseStats.Faction.PLAYER
]


# --- Component References and Runtime State ---

var stats: EntityStats
var hurtbox: Hurtbox
var hitbox: Hitbox
var attack_timer: Timer
var is_climbing: bool = false

# Tracks fractional HP and individual ability cooldowns.
var _health_recovery_progress: float = 0.0
var _ability_cooldowns: Dictionary = {}


# --- Initialization ---

func _ready() -> void:
	# Initialize stats using the team's EntityStats system.
	stats = EntityStats.new(
		enemy_name,
		BaseStats.Faction.ENEMY,
		max_health,
		move_speed,
		defense
	)

	# Create the area where the enemy can receive damage.
	var hurtbox_shape := RectangleShape2D.new()
	hurtbox_shape.size = Vector2(32, 32)

	hurtbox = Hurtbox.new(
		stats,
		0.0,
		hurtbox_shape,
		false,
		true
	)

	hurtbox.health_changed.connect(_on_health_changed)
	add_child(hurtbox)

	# Create the enemy's attack using the team's Hitbox system.
	var attack_stats := AttackStats.new(
		attack_damage,
		attack_damage_type,
		attack_target_layers
	)

	var hitbox_shape := RectangleShape2D.new()
	hitbox_shape.size = attack_hitbox_size

	hitbox = Hitbox.new(
		attack_stats,
		0.0,
		hitbox_shape
	)

	# Only detect attack collisions while attacking.
	hitbox.monitoring = false
	add_child(hitbox)

	# Timer controls how long the attack hitbox stays active.
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = attack_duration
	attack_timer.timeout.connect(_end_attack)
	add_child(attack_timer)


# --- Frame Updates ---

func _process(delta: float) -> void:
	recover_health(delta)
	update_ability_cooldowns(delta)


func _physics_process(delta: float) -> void:
	# Apply gravity unless standing on the ground or climbing.
	if not is_climbing and not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


# --- Health and Death ---

func _on_health_changed(
	old_health: int,
	new_health: int
) -> void:
	print("Enemy health: ", old_health, " -> ", new_health)

	if new_health <= 0:
		die()


func recover_health(delta: float) -> void:
	# Regeneration is disabled for dead enemies or when rate <= 0.
	if stats == null or health_recovery_rate <= 0.0:
		return

	if stats.health <= 0:
		return

	if stats.health >= stats.max_health:
		_health_recovery_progress = 0.0
		return

	# Accumulate fractional HP until a whole point can be healed.
	_health_recovery_progress += health_recovery_rate * delta
	var heal_amount: int = int(_health_recovery_progress)

	if heal_amount > 0:
		stats.heal(heal_amount)
		_health_recovery_progress -= heal_amount


func die() -> void:
	# Can be expanded later for death animations or loot drops.
	print(enemy_name, " has died!")
	queue_free()


# --- Attacking ---

## Activates the attack hitbox for the configured duration.
func attack() -> void:
	if hitbox == null or attack_timer == null:
		return

	# Prevent overlapping attacks.
	if not attack_timer.is_stopped():
		return

	hitbox.monitoring = true
	attack_timer.start()


func _end_attack() -> void:
	if is_instance_valid(hitbox):
		hitbox.monitoring = false


# --- Jumping ---

## Calculate the upward velocity needed for the desired jump height.
func get_jump_velocity() -> float:
	var gravity: float = get_gravity().y

	if gravity <= 0.0 or jump_height <= 0.0:
		return 0.0

	return -sqrt(2.0 * gravity * jump_height)


## Called by future enemy AI when attempting to jump.
func try_jump() -> bool:
	if not can_jump or not is_on_floor():
		return false

	velocity.y = get_jump_velocity()
	return true


# --- Climbing ---

## Starts climbing if permitted and a climbable area is available.
func try_start_climb(in_climb_area: bool) -> bool:
	if not can_climb or not in_climb_area:
		return false

	is_climbing = true
	velocity = Vector2.ZERO
	return true


func set_climb_direction(direction: float) -> void:
	if not is_climbing:
		return

	# -1 moves up, +1 moves down, 0 stops.
	velocity.y = clampf(direction, -1.0, 1.0) * climb_speed


func stop_climb() -> void:
	is_climbing = false
	velocity.y = 0.0


# --- Abilities and Cooldowns ---

## Checks whether an assigned ability is ready to use.
func can_use_ability(ability_name: String) -> bool:
	if ability_name.is_empty() or not abilities.has(ability_name):
		return false

	return _ability_cooldowns.get(ability_name, 0.0) <= 0.0


## Starts an ability's cooldown if that ability is ready.
func try_start_ability_cooldown(ability_name: String) -> bool:
	if not can_use_ability(ability_name):
		return false

	_ability_cooldowns[ability_name] = maxf(ability_cooldown, 0.0)
	return true


func update_ability_cooldowns(delta: float) -> void:
	if delta <= 0.0 or ability_recovery_rate <= 0.0:
		return

	# Each ability recovers independently.
	for ability_name in _ability_cooldowns.keys():
		var remaining: float = _ability_cooldowns[ability_name]

		remaining -= delta * ability_recovery_rate

		_ability_cooldowns[ability_name] = maxf(remaining, 0.0)
