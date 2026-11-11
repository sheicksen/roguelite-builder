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
@export var platform_graph: PlatformGraph
@export var waypoint_tolerance: float = 16.0

var route_ids: PackedInt64Array = PackedInt64Array()
var route_index: int = 0

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

	# Calculate distance and direction to the player.
	var distance = global_position.distance_to(target.global_position)
	var direction = target.global_position.x - global_position.x

	if distance > detection_range:
		# Player is too far away. Stay idle.
		velocity.x = 0.0

	elif distance > attack_range:
		# Calculate a route if we don't already have one.
		if platform_graph != null and route_ids.is_empty():
			route_ids = platform_graph.get_route_ids(
				global_position,
				target.global_position
			)
			route_index = 0

		# Follow the navigation graph when available.
		# Otherwise, fall back to direct chasing.
		if not follow_route():
			velocity.x = signf(direction) * move_speed


	else:
		# Player is within attack range.
		velocity.x = 0.0

		# Determine which direction the enemy is facing.
		var facing: int = 1 if direction >= 0.0 else -1

		# Use the equipped melee ability.
		melee_ability.use_ability(self, facing)

	# Prevent walking off platforms.
	if is_on_floor() and absf(velocity.x) > 0.0:
		# Check for ground in the direction of movement.
		ground_ahead.position.x = signf(velocity.x) * 24.0
		ground_ahead.force_raycast_update()

		if not ground_ahead.is_colliding():
			velocity.x = 0.0

	# Let BaseEnemy handle gravity and move_and_slide().
	super._physics_process(delta)


## Follow the current navigation route.
## Stop when the next connection requires jumping.
func follow_route() -> bool:
	if platform_graph == null or route_ids.is_empty():
		return false

	while route_index < route_ids.size():
		var point_id: int = route_ids[route_index]
		var waypoint: Vector2 = platform_graph.astar.get_point_position(point_id)

		# Check whether we reached the waypoint horizontally.
		if absf(global_position.x - waypoint.x) <= waypoint_tolerance:
			print("Reached waypoint: ", point_id)
			route_index += 1
			continue

		# Check whether the next connection requires jumping.
		if route_index > 0:
			var previous_id: int = route_ids[route_index - 1]

			if platform_graph.is_jump_connection(previous_id, point_id):
				velocity.x = 0.0
				return true

		# Walk toward the next waypoint.
		var direction: float = signf(waypoint.x - global_position.x)
		velocity.x = direction * move_speed
		return true

	# Finished the route.
	return false
