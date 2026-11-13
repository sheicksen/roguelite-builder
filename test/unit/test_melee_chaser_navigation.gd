
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
	var upper_cell := Vector2i(281, 279)

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

	# Activate pursuit.
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
