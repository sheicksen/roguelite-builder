extends GutTest

func test_place_and_remove_solid_tile() -> void:
	# Create our editable room scene.
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	# Use an empty cell away from our painted terrain.
	var test_cell := Vector2i(30, 30)

	# Confirm the position starts empty.
	assert_false(room.has_solid_tile(test_cell))

	# Place a solid block.
	room.place_solid_tile(test_cell)

	# Verify the block exists.
	assert_true(room.has_solid_tile(test_cell))

	# Remove the block.
	room.remove_solid_tile(test_cell)

	# Verify the position is empty again.
	assert_false(room.has_solid_tile(test_cell))

func test_switch_terrain_types() -> void:
	var room = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	# Use a position away from the existing terrain.
	var test_cell := Vector2i(31, 31)

	room.remove_tile(test_cell)

	# Place a semi-solid platform.
	room.place_platform_tile(test_cell)

	assert_true(room.has_platform_tile(test_cell))
	assert_false(room.has_solid_tile(test_cell))

	# Replace the platform with solid terrain.
	room.place_solid_tile(test_cell)

	assert_true(room.has_solid_tile(test_cell))
	assert_false(room.has_platform_tile(test_cell))

	# Remove the terrain.
	room.remove_tile(test_cell)

	assert_false(room.has_solid_tile(test_cell))
	assert_false(room.has_platform_tile(test_cell))
