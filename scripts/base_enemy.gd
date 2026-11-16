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
# Horizontal movement speed while jumping.
@export var jump_move_speed: float = 150.0

@export_group("Recovery")
@export var health_recovery_rate: float = 0.0

@export_group("Attack")
@export var attack_damage: int = 10

@export_enum("Default", "Fire", "Poison", "Ice", "Corrupted")
var attack_damage_type: int = BaseStats.DamageType.DEFAULT

# --- Component References and Runtime State ---
var stats: EntityStats
var hurtbox: Hurtbox

# Tracks fractional HP and individual ability cooldowns.
var _health_recovery_progress: float = 0.0


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


# --- Frame Updates ---
func _process(delta: float) -> void:
	recover_health(delta)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
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
