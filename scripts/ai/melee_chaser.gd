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

@onready var ground_ahead: RayCast2D = $GroundAhead

@export_group("Pathfinding")
@export var waypoint_tolerance: float = 12.0

@export_group("Debug")
@export var debug_logging: bool = false

## Types of platform traversal the enemy can perform.
enum TraversalMode {
	NONE,
	JUMP,
	DROP
}

var terrain_navigation: TerrainNavigation
var navigation_steps: Array[Dictionary] = []
var navigation_step_index: int = 0
var jump_reported: bool = false
var jump_was_airborne: bool = false
var jump_is_upward: bool = false
var jump_horizontal_unlocked: bool = false
var drop_was_airborne: bool = false
var drop_direction: float = 0.0

@export_range(0.2, 3.0, 0.1)
var repath_interval: float = 0.75
var repath_timer: float = 0.0

# Counts how often this enemy requests a navigation path.
var path_request_count: int = 0

## Prints AI navigation information only when debugging is enabled.
func _debug_log(message: String) -> void:
	if debug_logging:
		print(message)


## Returns true while jumping or performing a controlled drop.
func _is_traversing_platforms() -> bool:
	return traversal_mode != TraversalMode.NONE


## Sets the enemy's current traversal state.
func _set_traversal_mode(mode: TraversalMode) -> void:
	traversal_mode = mode


# The enemy's current platform traversal state.
var traversal_mode: TraversalMode = TraversalMode.NONE

# Compatibility properties for existing code and tests.
var jump_in_progress: bool:
	get:
		return traversal_mode == TraversalMode.JUMP

var drop_in_progress: bool:
	get:
		return traversal_mode == TraversalMode.DROP


func _ready() -> void:
	super._ready()

	# Default to a Knife if no ability is assigned.
	var config: AbilityData = KnifeConfig.new()

	# Use the configured ability if one is provided.
	if equipped_ability != null:
		config = equipped_ability.duplicate(false) as AbilityData

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

	# Find the room's automatically generated navigation graph.
	if not is_instance_valid(terrain_navigation):
		terrain_navigation = get_tree().get_first_node_in_group(
			"terrain_navigation"
		) as TerrainNavigation

		# Listen for changes to the room's navigation graph.
		if is_instance_valid(terrain_navigation):
			terrain_navigation.navigation_rebuilt.connect(
				_on_navigation_rebuilt
			)


	# Count down until the next path recalculation.
	repath_timer = maxf(repath_timer - delta, 0.0)

	# Calculate distance and direction to the player.
	var distance = global_position.distance_to(target.global_position)
	var direction = target.global_position.x - global_position.x

	if _is_traversing_platforms():
		# Finish an active jump before returning to combat decisions.
		follow_navigation_steps()

	elif distance > detection_range:
		# Player is too far away. Stay idle.
		velocity.x = 0.0

	elif distance > attack_range:
		if terrain_navigation == null:
			# No navigation system available.
			# Fall back to direct movement.
			velocity.x = signf(direction) * move_speed
		else:
			# Recalculate only when the timer expires.
			# An unreachable target can produce an empty route,
			# so an empty route alone must not trigger a retry.
			if repath_timer <= 0.0:
				path_request_count += 1

				navigation_steps = terrain_navigation.get_navigation_steps(
					global_position,
					target.global_position,
					can_jump,
					float(move_speed),
					jump_height
				)
				navigation_step_index = 0
				repath_timer = repath_interval

			# Follow the automatically generated instructions.
			follow_navigation_steps()

	else:
		# Player is within attack range.
		velocity.x = 0.0

		# Clear the completed route so we can pursue again
		# if the player moves away.
		navigation_steps.clear()
		navigation_step_index = 0
		jump_reported = false

		# Determine which direction the enemy is facing.
		var facing: int = 1 if direction >= 0.0 else -1

		# Use the equipped melee ability.
		melee_ability.use_ability(self, facing)

	# Prevent walking off platforms.
	if (
		is_on_floor()
		and not _is_traversing_platforms()
		and absf(velocity.x) > 0.0
	):

		# Check for ground in the direction of movement.
		ground_ahead.position.x = signf(velocity.x) * 24.0
		ground_ahead.force_raycast_update()


		if not ground_ahead.is_colliding():
			velocity.x = 0.0

			# Report when ledge protection interrupts movement.
			if not jump_reported:
				_debug_log(str(
					"GroundAhead stopped movement | Position: ",
					global_position,
					" | Navigation step: ",
					navigation_step_index
				))
				jump_reported = true

	# Let BaseEnemy handle gravity and move_and_slide().
	super._physics_process(delta)


## Follows automatically generated walking and jumping instructions.
func follow_navigation_steps() -> void:
	if navigation_steps.is_empty():
		# No route was found.
		velocity.x = 0.0
		return

	if navigation_step_index >= navigation_steps.size():
		# We've completed the route, but may not have
		# reached the player yet.
		move_toward_player_after_route()
		return


	# Continue an active jump until the enemy lands.
	if jump_in_progress:
		var landing: Vector2 = navigation_steps[navigation_step_index]["position"]
		var horizontal_distance: float = landing.x - global_position.x

		# For upward jumps, wait until the enemy has
		# risen above the landing platform.
		if jump_is_upward and not jump_horizontal_unlocked:
			if global_position.y <= landing.y - 1.0:
				jump_horizontal_unlocked = true
				_debug_log("Cleared ledge. Moving horizontally.")

		# Move sideways only after clearance.
		if jump_horizontal_unlocked and absf(horizontal_distance) > waypoint_tolerance:
			velocity.x = signf(horizontal_distance) * move_speed
		else:
			velocity.x = 0.0


		# Make sure the enemy has actually left the floor.
		if not is_on_floor():
			jump_was_airborne = true

		# Verify landing before advancing to the next waypoint.
		elif jump_was_airborne:
			_set_traversal_mode(TraversalMode.NONE)
			jump_was_airborne = false
			velocity.x = 0.0

			if (
				absf(horizontal_distance) <= waypoint_tolerance
				and absf(global_position.y - landing.y) <= 16.0
			):

				_debug_log(str("Jump landed at: ", global_position))
				navigation_step_index += 1
			else:
				_debug_log("Jump missed landing. Recalculating route.")
				navigation_steps.clear()
				navigation_step_index = 0

		return


	# Continue a deliberate drop until landing.
	if drop_in_progress:
		var landing: Vector2 = navigation_steps[navigation_step_index]["position"]
		var horizontal_distance: float = landing.x - global_position.x

		# Remember when the enemy leaves its current platform.
		if not is_on_floor():
			drop_was_airborne = true

		# Detect landing after the enemy has been airborne.
		elif drop_was_airborne:
			_set_traversal_mode(TraversalMode.NONE)
			drop_was_airborne = false
			velocity.x = 0.0

			if (
				absf(horizontal_distance) <= waypoint_tolerance
				and absf(global_position.y - landing.y) <= 16.0
			):
				_debug_log(str("Drop landed at: ", global_position))
				navigation_step_index += 1
			else:
				_debug_log("Drop missed landing. Recalculating route.")
				navigation_steps.clear()
				navigation_step_index = 0

			repath_timer = 0.0
			return

		# Keep moving in the original direction until the
		# enemy has completely left the upper platform.
		# Do not apply waypoint tolerance while still grounded.
		if not drop_was_airborne:
			velocity.x = drop_direction * move_speed
			return

		# Once airborne, steer toward the landing position.
		if absf(horizontal_distance) > waypoint_tolerance:
			velocity.x = signf(horizontal_distance) * move_speed
		else:
			velocity.x = 0.0

		return


	# Process walking instructions or start a jump.
	while navigation_step_index < navigation_steps.size():
		var step: Dictionary = navigation_steps[navigation_step_index]
		var waypoint: Vector2 = step["position"]
		var movement: String = step["movement"]

		# Begin a controlled drop toward a lower platform.
		if movement == "drop":
			_set_traversal_mode(TraversalMode.DROP)
			drop_was_airborne = not is_on_floor()

			# Remember the direction needed to leave the ledge.
			drop_direction = signf(
				waypoint.x - global_position.x
			)

			velocity.x = drop_direction * move_speed

			_debug_log(str("Drop started toward: ", waypoint))
			return


		# Start jumping toward the landing waypoint.
		if movement == "jump":
			velocity.x = 0.0

			# Check whether jumping is currently possible.
			if not jump_reported:
				_debug_log(str(
					"JUMP STEP | Can jump: ", can_jump,
					" | On floor: ", is_on_floor(),
					" | Position: ", global_position,
					" | Destination: ", waypoint
				))
				jump_reported = true

			if try_jump():
				_set_traversal_mode(TraversalMode.JUMP)
				jump_was_airborne = false

				# Determine whether the destination is higher.
				jump_is_upward = waypoint.y < global_position.y - 1.0

				# Same-height jumps can move sideways immediately.
				# Upward jumps must first clear the ledge.
				jump_horizontal_unlocked = not jump_is_upward

				if jump_horizontal_unlocked:
					velocity.x = signf(
						waypoint.x - global_position.x
					) * move_speed
				else:
					velocity.x = 0.0

				_debug_log(str("Jump launched toward: ", waypoint))

			return

		# Move to the next walking waypoint.
		if absf(global_position.x - waypoint.x) <= waypoint_tolerance:
			navigation_step_index += 1
			continue

		velocity.x = signf(
			waypoint.x - global_position.x
		) * move_speed

		return

	move_toward_player_after_route()


## Move toward the player's actual position after completing
## the navigation route.
func move_toward_player_after_route() -> void:
	if not is_instance_valid(target):
		velocity.x = 0.0
		return

	# Only use direct movement when we're at approximately
	# the same height as the player.
	if absf(target.global_position.y - global_position.y) > 24.0:
		velocity.x = 0.0
		return

	# Follow the player instead of stopping at a waypoint.
	var direction: float = target.global_position.x - global_position.x
	velocity.x = signf(direction) * move_speed


## Invalidates the current route when terrain changes.
func _on_navigation_rebuilt() -> void:
	# Request a fresh path on the next physics update.
	repath_timer = 0.0

	# Don't interrupt an enemy already in midair.
	if _is_traversing_platforms():
		return


	# Discard the old path.
	navigation_steps.clear()
	navigation_step_index = 0
	jump_reported = false

	_debug_log("Navigation changed. Enemy will recalculate its route.")
