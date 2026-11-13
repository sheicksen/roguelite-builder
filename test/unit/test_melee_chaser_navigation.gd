
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
