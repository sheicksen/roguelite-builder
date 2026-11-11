
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
