
extends GutTest

## Verify that destroying terrain automatically updates
## the navigation graph.

func test_navigation_updates_when_terrain_destroyed() -> void:
	# Create an editable room with its navigation system.
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	# Get the automatically generated navigation system.
	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	assert_not_null(navigation)

	# Choose an empty cell away from existing terrain.
	var test_cell := Vector2i(50, 50)

	# Place a destructible tile.
	room.place_destructible_tile(test_cell)

	# Build our starting navigation graph.
	navigation.rebuild_navigation()

	# The tile should now have a navigation point.
	assert_true(
		navigation.point_ids_by_cell.has(test_cell),
		"Navigation should include the destructible tile."
	)

	# Destroy the tile through the damage system.
	var destroyed: bool = room.damage_destructible_tile(
		test_cell,
		room.destructible_max_health
	)

	assert_true(destroyed)

	# Allow the deferred navigation rebuild to execute.
	await get_tree().process_frame
	await get_tree().process_frame

	# The destroyed tile should no longer exist.
	assert_false(room.has_destructible_tile(test_cell))

	# Its navigation point should also be removed.
	assert_false(
		navigation.point_ids_by_cell.has(test_cell),
		"Navigation should remove destroyed terrain."
	)


func test_destroying_platform_disconnects_route() -> void:
	# Create a room with automatic navigation.
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	# Create four adjacent destructible terrain tiles.
	var start_cell := Vector2i(60, 60)
	var middle_a := Vector2i(61, 60)
	var middle_b := Vector2i(62, 60)
	var end_cell := Vector2i(63, 60)

	for cell in [start_cell, middle_a, middle_b, end_cell]:
		room.place_destructible_tile(cell)

	# Generate the initial navigation graph.
	navigation.rebuild_navigation()

	# Get the standing positions at both ends.
	var start_id: int = navigation.point_ids_by_cell[start_cell]
	var end_id: int = navigation.point_ids_by_cell[end_cell]

	var start_position: Vector2 = navigation.astar.get_point_position(
		start_id
	)
	var end_position: Vector2 = navigation.astar.get_point_position(
		end_id
	)

	# The original route should cross all four tiles.
	var original_path: PackedVector2Array = (
		navigation.get_navigation_path(
			start_position,
			end_position
		)
	)

	assert_eq(original_path.size(), 4)

	# Destroy the two middle tiles through gameplay damage.
	room.damage_destructible_tile(
		middle_a,
		room.destructible_max_health
	)

	room.damage_destructible_tile(
		middle_b,
		room.destructible_max_health
	)

	# Let the automatic navigation rebuild complete.
	await get_tree().process_frame
	await get_tree().process_frame

	# Both endpoints should still exist.
	assert_true(navigation.point_ids_by_cell.has(start_cell))
	assert_true(navigation.point_ids_by_cell.has(end_cell))

	# The destroyed tiles should no longer support navigation.
	assert_false(navigation.point_ids_by_cell.has(middle_a))
	assert_false(navigation.point_ids_by_cell.has(middle_b))

	# AStar should no longer find a connected path.
	var updated_path: PackedVector2Array = (
		navigation.get_navigation_path(
			start_position,
			end_position
		)
	)

	assert_eq(
		updated_path.size(),
		0,
		"Destroying the middle tiles should disconnect the route."
	)


func test_elevated_jump_flight_time() -> void:
	# Create the room so TerrainNavigation has its expected parent.
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	# Use the room's existing navigation system.
	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	assert_not_null(navigation)

	var gravity: float = 980.0
	var jump_height: float = 64.0

	# Landing at the same height.
	var same_height_time: float = (
		navigation.estimate_jump_landing_time(
			0.0, 0.0, jump_height, gravity
		)
	)

	assert_true(same_height_time > 0.0)

	# Landing 32 pixels higher.
	var higher_time: float = (
		navigation.estimate_jump_landing_time(
			0.0, -32.0, jump_height, gravity
		)
	)

	assert_true(higher_time > 0.0)
	assert_true(higher_time < same_height_time)

	# Landing 96 pixels higher is impossible.
	var impossible_time: float = (
		navigation.estimate_jump_landing_time(
			0.0, -96.0, jump_height, gravity
		)
	)

	assert_eq(impossible_time, -1.0)

func test_detects_elevated_jump_candidate() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	# Create a lower floor and a higher platform.
	var lower_cell := Vector2i(70, 70)
	var upper_cell := Vector2i(71, 69)

	room.place_solid_tile(lower_cell)
	room.place_platform_tile(upper_cell)

	# Generate the navigation graph.
	navigation.rebuild_navigation()

	assert_true(navigation.point_ids_by_cell.has(lower_cell))
	assert_true(navigation.point_ids_by_cell.has(upper_cell))

	var lower_id: int = navigation.point_ids_by_cell[lower_cell]
	var upper_id: int = navigation.point_ids_by_cell[upper_cell]

	# Check that an upward jump was identified.
	var upward_jump := Vector2i(lower_id, upper_id)

	assert_true(
		navigation.candidate_jumps.has(upward_jump),
		"Navigation should detect the higher platform."
	)

func test_elevated_jump_arc_validation() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	var navigation: TerrainNavigation = room.get_node(
		"TerrainNavigation"
	) as TerrainNavigation

	navigation.debug_move_speed = 100.0
	navigation.debug_jump_height = 64.0

	var gravity: float = 980.0

	# A same-height jump should remain possible.
	assert_true(
		navigation.is_jump_arc_clear(
			Vector2(0, 0),
			Vector2(64, 0),
			gravity
		)
	)

	# A nearby elevated destination should be reachable.
	assert_true(
		navigation.is_jump_arc_clear(
			Vector2(0, 0),
			Vector2(32, -32),
			gravity
		)
	)

	# A destination above maximum jump height is impossible.
	assert_false(
		navigation.is_jump_arc_clear(
			Vector2(0, 0),
			Vector2(32, -96),
			gravity
		)
	)

	# A destination requiring excessive horizontal speed
	# should be rejected.
	assert_false(
		navigation.is_jump_arc_clear(
			Vector2(0, 0),
			Vector2(128, -32),
			gravity
		)
	)
