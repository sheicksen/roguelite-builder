
extends GutTest


## Verify that a real MeleeChaser finds the player
## and the room's navigation system.
func test_enemy_discovers_navigation_and_player() -> void:
	# Create the editable room.
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	# Create a player target.
	var player: Player = load(
		"res://scenes/Player.tscn"
	).instantiate()

	player.global_position = Vector2(200, 200)
	add_child_autofree(player)

	# Create our melee enemy.
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.global_position = Vector2(100, 200)
	enemy.detection_range = 500.0
	add_child_autofree(enemy)

	# Allow the physics process to run.
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Confirm that the enemy identified its target.
	assert_true(
		enemy.target == player,
		"Enemy should detect the player."
	)

	# Confirm that it discovered the navigation system.
	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	assert_not_null(
		enemy.terrain_navigation,
		"Enemy should discover TerrainNavigation."
	)

	assert_true(
		enemy.terrain_navigation == navigation,
		"Enemy should use the room's navigation system."
	)

## Verify that a MeleeChaser physically leaves an upper
## platform and lands on a lower platform.
func test_enemy_physically_drops_to_lower_platform() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	add_child_autofree(room)

	# Create a small upper ledge.
	var upper_cell := Vector2i(240, 240)
	room.place_solid_tile(upper_cell)

	# Create a lower floor, one tile below the ledge.
	for x in range(235, 240):
		room.place_solid_tile(Vector2i(x, 241))

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	navigation.rebuild_navigation()

	# Get the standing positions from the navigation graph.
	var upper_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[upper_cell]
	)

	var lower_cell := Vector2i(239, 241)
	var lower_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[lower_cell]
	)

	var player_cell := Vector2i(236, 241)
	var player_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[player_cell]
	)

	# Place the player on the lower floor.
	var player: Player = load(
		"res://scenes/Player.tscn"
	).instantiate()

	add_child_autofree(player)

	# The player's collision shape is taller than the enemy's.
	player.global_position = player_position + Vector2(0, -7)

	# Keep the player stationary during this test.
	player.set_physics_process(false)

	# Create the enemy on the upper ledge.
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.move_speed = 100
	enemy.can_jump = false
	enemy.jump_height = 0.0
	enemy.detection_range = 500.0

	add_child_autofree(enemy)
	enemy.global_position = upper_position

	# Verify the navigation system provides a drop route.
	var route: Array[Dictionary] = navigation.get_navigation_steps(
		upper_position,
		player_position,
		false,
		100.0,
		0.0
	)

	var has_drop: bool = false

	for step in route:
		if step["movement"] == "drop":
			has_drop = true
			break

	assert_true(
		has_drop,
		"Navigation must provide a drop instruction."
	)

	if not has_drop:
		return

	# Allow the physics engine to initialize collisions.
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_true(
		enemy.is_on_floor(),
		"Enemy should begin on the upper platform."
	)

	# Track whether the enemy actually leaves the ledge
	# and subsequently lands on the lower floor.
	var became_airborne: bool = false
	var landed_below: bool = false

	for frame in range(180):
		await get_tree().physics_frame

		if not enemy.is_on_floor():
			became_airborne = true

		if (
			became_airborne
			and enemy.is_on_floor()
			and absf(enemy.global_position.y - lower_position.y) <= 4.0
		):
			landed_below = true
			break

	assert_true(
		became_airborne,
		"Enemy should physically leave the upper ledge."
	)

	assert_true(
		landed_below,
		"Enemy should successfully land on the lower platform."
	)

## Verify that a MeleeChaser can physically jump
## onto a higher solid platform.
func test_enemy_physically_jumps_to_upper_platform() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	add_child_autofree(room)

	# Build a lower floor.
	var lower_cell := Vector2i(260, 260)

	for x in range(257, 261):
		room.place_solid_tile(Vector2i(x, 260))

	# Build an upper platform one tile higher.
	var upper_cell := Vector2i(261, 259)

	for x in range(261, 266):
		room.place_solid_tile(Vector2i(x, 259))

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	navigation.rebuild_navigation()

	# Retrieve the calculated standing positions.
	var lower_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[lower_cell]
	)

	var upper_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[upper_cell]
	)

	var player_cell := Vector2i(264, 259)

	var player_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[player_cell]
	)

	# Create the player on the upper platform.
	var player: Player = load(
		"res://scenes/Player.tscn"
	).instantiate()

	add_child_autofree(player)
	player.global_position = player_position + Vector2(0, -7)
	player.set_physics_process(false)

	# Create an enemy capable of jumping 64 pixels.
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.move_speed = 100
	enemy.can_jump = true
	enemy.jump_height = 64.0

	# Prevent the enemy from jumping during initialization.
	enemy.detection_range = 0.0

	add_child_autofree(enemy)

	# Start slightly above and left of the standing point.
	# Allow gravity to settle the enemy onto the floor.
	enemy.global_position = lower_position + Vector2(-4.0, -8.0)

	# Verify the enemy receives an upward jump route.
	var route: Array[Dictionary] = navigation.get_navigation_steps(
		lower_position,
		player_position,
		true,
		100.0,
		64.0
	)

	var has_jump: bool = false

	for step in route:
		if (
			step["movement"] == "jump"
			and step["position"].y < lower_position.y
		):
			has_jump = true
			break

	assert_true(
		has_jump,
		"Navigation should generate an upward jump."
	)

	if not has_jump:
		return


	# Allow the enemy to settle onto the floor before
	# enabling pursuit.
	var started_grounded: bool = false

	for frame in range(30):
		await get_tree().physics_frame

		if enemy.is_on_floor():
			started_grounded = true
			break

	assert_true(
		started_grounded,
		"Enemy should begin grounded."
	)

	if not started_grounded:
		print(
			"Grounding failed | Position: ",
			enemy.global_position,
			" | Expected floor position: ",
			lower_position,
			" | Velocity: ",
			enemy.velocity
		)
		return

	# Enable pursuit only after the enemy is grounded.
	enemy.detection_range = 500.0


	# Track the actual jump and landing.
	var became_airborne: bool = false
	var reached_upper_height: bool = false
	var landed_above: bool = false

	for frame in range(240):
		await get_tree().physics_frame

		if not enemy.is_on_floor():
			became_airborne = true

		if enemy.global_position.y < lower_position.y - 24.0:
			reached_upper_height = true

		if (
			became_airborne
			and enemy.is_on_floor()
			and absf(enemy.global_position.y - upper_position.y) <= 4.0
			and enemy.global_position.x >= upper_position.x - 16.0
		):
			landed_above = true
			break

	assert_true(
		became_airborne,
		"Enemy should physically leave the ground."
	)

	assert_true(
		reached_upper_height,
		"Enemy should reach the elevated platform's height."
	)

	assert_true(
		landed_above,
		"Enemy should successfully land on the upper platform."
	)

	if not landed_above:
		return

	# Remember where the enemy landed.
	var landing_x: float = enemy.global_position.x

	# Let the AI continue pursuing the player.
	for frame in range(60):
		await get_tree().physics_frame

	assert_true(
		enemy.global_position.x > landing_x + 8.0,
		"Enemy should continue pursuing after landing."
	)

## Verify that an enemy without jumping capabilities
## does not attempt to reach an elevated platform.
func test_enemy_does_not_jump_to_unreachable_platform() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	add_child_autofree(room)

	# Create two adjacent platforms at different heights.
	var lower_cell := Vector2i(280, 280)
	var upper_cell := Vector2i(284, 279)


	room.place_solid_tile(lower_cell)
	room.place_solid_tile(upper_cell)

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	navigation.rebuild_navigation()

	var lower_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[lower_cell]
	)

	var upper_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[upper_cell]
	)

	# Create a stationary player on the higher platform.
	var player: Player = load(
		"res://scenes/Player.tscn"
	).instantiate()

	add_child_autofree(player)
	player.global_position = upper_position + Vector2(0, -7)
	player.set_physics_process(false)

	# Create an enemy that cannot jump.
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.can_jump = false
	enemy.jump_height = 0.0
	enemy.move_speed = 100

	# Disable detection while the enemy settles.
	enemy.detection_range = 0.0

	add_child_autofree(enemy)
	enemy.global_position = lower_position + Vector2(-4, -8)

	# Verify there is no valid upward route.
	var route: Array[Dictionary] = navigation.get_navigation_steps(
		lower_position,
		upper_position,
		false,
		100.0,
		0.0
	)

	assert_eq(
		route.size(),
		0,
		"Non-jumping enemy should have no upward route."
	)

	# Wait for the enemy to land before starting AI.
	var started_grounded: bool = false

	for frame in range(30):
		await get_tree().physics_frame

		if enemy.is_on_floor():
			started_grounded = true
			break

	assert_true(
		started_grounded,
		"Enemy should begin grounded."
	)

	if not started_grounded:
		return

	var starting_position: Vector2 = enemy.global_position

	# Activate pursuit and measure navigation requests.
	var requests_before: int = enemy.path_request_count

	enemy.detection_range = 500.0

	var attempted_jump: bool = false
	var became_airborne: bool = false

	# Observe actual movement for two seconds
	# at the default 60 physics updates per second.
	for frame in range(120):
		await get_tree().physics_frame

		if enemy.jump_in_progress:
			attempted_jump = true

		if not enemy.is_on_floor():
			became_airborne = true

	# Measure how many routes were requested during
	# the 120 physics frames.
	var requests_made: int = (
		enemy.path_request_count - requests_before
	)

	print(
		"UNREACHABLE ENEMY | Path requests over 120 frames: ",
		requests_made
	)

	# An unreachable target should not trigger a
	# navigation request every physics frame.
	assert_true(
		requests_made >= 1 and requests_made <= 4,
		"Unreachable enemies should respect the repath interval."
	)

	assert_false(
		attempted_jump,
		"Enemy should not attempt an impossible jump."
	)

	assert_false(
		became_airborne,
		"Enemy should remain safely on the lower platform."
	)

	assert_true(
		enemy.global_position.distance_to(starting_position) <= 2.0,
		"Enemy should remain idle without a valid route."
	)

## Verify that jumping and dropping are mutually exclusive
## and that compatibility properties reflect the current state.
func test_traversal_state_transitions() -> void:
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	add_child_autofree(enemy)

	# The enemy should begin without active traversal.
	assert_eq(
		enemy.traversal_mode,
		MeleeChaser.TraversalMode.NONE
	)
	assert_false(enemy.jump_in_progress)
	assert_false(enemy.drop_in_progress)

	# Starting a jump should enable only jumping.
	enemy._set_traversal_mode(MeleeChaser.TraversalMode.JUMP)

	assert_true(enemy.jump_in_progress)
	assert_false(enemy.drop_in_progress)
	assert_true(enemy._is_traversing_platforms())

	# Switching to a drop should automatically end jumping.
	enemy._set_traversal_mode(MeleeChaser.TraversalMode.DROP)

	assert_false(enemy.jump_in_progress)
	assert_true(enemy.drop_in_progress)
	assert_true(enemy._is_traversing_platforms())

	# Ending traversal should clear both properties.
	enemy._set_traversal_mode(MeleeChaser.TraversalMode.NONE)

	assert_false(enemy.jump_in_progress)
	assert_false(enemy.drop_in_progress)
	assert_false(enemy._is_traversing_platforms())

## Verify that a missed jump clears the old route
## and allows immediate path recalculation.
func test_missed_jump_resets_repath_timer() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	add_child_autofree(room)

	# Create a platform for the enemy to stand on.
	var floor_cell := Vector2i(280, 280)
	room.place_solid_tile(floor_cell)

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	navigation.rebuild_navigation()

	var floor_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[floor_cell]
	)

	# Spawn an enemy without activating pursuit.
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.detection_range = 0.0
	add_child_autofree(enemy)
	enemy.global_position = floor_position + Vector2(-4.0, -8.0)

	# Allow physics to settle the enemy onto the floor.
	var started_grounded: bool = false

	for frame in range(30):
		await get_tree().physics_frame

		if enemy.is_on_floor():
			started_grounded = true
			break

	assert_true(started_grounded, "Enemy should begin grounded.")

	if not started_grounded:
		return

	# Stop automatic updates so we can test the
	# landing-recovery logic without interference.
	enemy.set_physics_process(false)

	# Simulate an enemy that was airborne but has
	# landed too far from its intended waypoint.
	enemy.navigation_steps.clear()
	enemy.navigation_steps.append({
		"position": enemy.global_position + Vector2(200.0, -64.0),
		"movement": "jump"
	})

	enemy.navigation_step_index = 0
	enemy._set_traversal_mode(MeleeChaser.TraversalMode.JUMP)
	enemy.jump_was_airborne = true
	enemy.jump_horizontal_unlocked = true
	enemy.repath_timer = enemy.repath_interval

	# Process the unsuccessful landing.
	enemy.follow_navigation_steps()

	# The jump should finish and discard the failed route.
	assert_false(enemy.jump_in_progress)
	assert_true(enemy.navigation_steps.is_empty())

	# A new path should be allowed immediately.
	assert_eq(
		enemy.repath_timer,
		0.0,
		"Missed jumps should trigger immediate repathing."
	)


## Verify that Chaser behavior pursues a player
## along a continuous, flat platform.
func test_chaser_pursues_player_on_flat_ground() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	add_child_autofree(room)

	# Build a continuous floor.
	for x in range(300, 316):
		room.place_solid_tile(Vector2i(x, 300))

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	navigation.rebuild_navigation()

	var enemy_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[Vector2i(303, 300)]
	)

	var player_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[Vector2i(312, 300)]
	)

	# Create a stationary player.
	var player: Player = load(
		"res://scenes/Player.tscn"
	).instantiate()

	add_child_autofree(player)
	player.global_position = player_position + Vector2(0, -7)
	player.set_physics_process(false)
	player.collision_layer = 0

	# Configure a Chaser enemy.
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.behavior_type = MeleeChaser.BehaviorType.CHASER
	enemy.move_speed = 100
	enemy.detection_range = 0.0

	add_child_autofree(enemy)
	enemy.global_position = enemy_position + Vector2(0, -8)

	# Allow the enemy to settle onto the floor.
	for frame in range(30):
		await get_tree().physics_frame

		if enemy.is_on_floor():
			break

	assert_true(enemy.is_on_floor())

	if not enemy.is_on_floor():
		return

	var starting_distance: float = enemy.global_position.distance_to(
		player.global_position
	)

	# Enable pursuit.
	enemy.detection_range = 500.0

	for frame in range(30):
		await get_tree().physics_frame

	var ending_distance: float = enemy.global_position.distance_to(
		player.global_position
	)

	assert_lt(
		ending_distance,
		starting_distance,
		"Chaser should move closer to the player."
	)


## Verify that Ranged behavior retreats when
## the player is too close and can be attacked.
func test_ranged_enemy_retreats_when_too_close() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	add_child_autofree(room)

	# Create a continuous floor with room to retreat.
	for x in range(300, 316):
		room.place_solid_tile(Vector2i(x, 300))

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	navigation.rebuild_navigation()

	var enemy_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[Vector2i(307, 300)]
	)

	var player_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[Vector2i(308, 300)]
	)

	# Create a stationary player.
	var player: Player = load(
		"res://scenes/Player.tscn"
	).instantiate()

	add_child_autofree(player)
	player.global_position = player_position + Vector2(0, -7)
	player.set_physics_process(false)
	player.collision_layer = 0

	# Configure a ranged-behavior enemy.
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.behavior_type = MeleeChaser.BehaviorType.RANGED
	enemy.move_speed = 100
	enemy.detection_range = 0.0

	add_child_autofree(enemy)
	enemy.global_position = enemy_position + Vector2(0, -8)

	# Wait for the enemy to become grounded.
	for frame in range(30):
		await get_tree().physics_frame

		if enemy.is_on_floor():
			break

	assert_true(enemy.is_on_floor())

	if not enemy.is_on_floor():
		return

	# Confirm that the equipped ability can hit the player.
	assert_true(
		enemy._can_attack_target(),
		"Enemy should be able to attack at this distance."
	)

	if not enemy._can_attack_target():
		return

	var starting_x: float = enemy.global_position.x

	# Enable ranged behavior.
	enemy.detection_range = 500.0

	for frame in range(10):
		await get_tree().physics_frame

	assert_lt(
		enemy.global_position.x,
		starting_x,
		"Ranged enemy should retreat from a nearby player."
	)


## Verify that Turret behavior does not pursue
## or retreat from a nearby player.
func test_turret_remains_stationary() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	add_child_autofree(room)

	# Create a flat floor.
	for x in range(300, 316):
		room.place_solid_tile(Vector2i(x, 300))

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	navigation.rebuild_navigation()

	var enemy_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[Vector2i(307, 300)]
	)

	var player_position: Vector2 = navigation.astar.get_point_position(
		navigation.point_ids_by_cell[Vector2i(308, 300)]
	)

	# Create a stationary player.
	var player: Player = load(
		"res://scenes/Player.tscn"
	).instantiate()

	add_child_autofree(player)
	player.global_position = player_position + Vector2(0, -7)
	player.set_physics_process(false)
	player.collision_layer = 0

	# Configure the enemy as a Turret.
	var enemy: MeleeChaser = load(
		"res://scenes/Enemy.tscn"
	).instantiate()

	enemy.behavior_type = MeleeChaser.BehaviorType.TURRET
	enemy.detection_range = 0.0

	add_child_autofree(enemy)
	enemy.global_position = enemy_position + Vector2(0, -8)

	# Allow the enemy to settle onto the floor.
	for frame in range(30):
		await get_tree().physics_frame

		if enemy.is_on_floor():
			break

	assert_true(enemy.is_on_floor())

	if not enemy.is_on_floor():
		return

	var starting_x: float = enemy.global_position.x

	# Enable detection and let the AI process.
	enemy.detection_range = 500.0

	for frame in range(30):
		await get_tree().physics_frame

	assert_almost_eq(
		enemy.global_position.x,
		starting_x,
		1.0,
		"Turret should remain stationary near the player."
	)

	assert_true(
		enemy.target == player,
		"Turret should still detect the player."
	)
