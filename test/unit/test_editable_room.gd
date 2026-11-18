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


func test_destructible_tile_health() -> void:
	var room = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.destructible_max_health = 100
	add_child_autofree(room)

	var test_cell := Vector2i(32, 32)

	# Create a block with full health.
	room.place_destructible_tile(test_cell)

	assert_true(room.has_destructible_tile(test_cell))
	assert_eq(room.get_destructible_health(test_cell), 100)

	# Damage the block without destroying it.
	assert_false(room.damage_destructible_tile(test_cell, 40))
	assert_eq(room.get_destructible_health(test_cell), 60)

	# Deal enough damage to destroy it.
	assert_true(room.damage_destructible_tile(test_cell, 60))
	assert_false(room.has_destructible_tile(test_cell))
	assert_eq(room.get_destructible_health(test_cell), 0)


func test_independent_destructible_tiles() -> void:
	var room = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.destructible_max_health = 100
	add_child_autofree(room)

	# Create two separate destructible blocks.
	var cell_a := Vector2i(33, 33)
	var cell_b := Vector2i(34, 33)

	room.place_destructible_tile(cell_a)
	room.place_destructible_tile(cell_b)

	# Damage only the first block.
	room.damage_destructible_tile(cell_a, 40)

	# Verify that the second block is unaffected.
	assert_eq(room.get_destructible_health(cell_a), 60)
	assert_eq(room.get_destructible_health(cell_b), 100)

	# Destroy the first block.
	room.damage_destructible_tile(cell_a, 60)

	assert_false(room.has_destructible_tile(cell_a))
	assert_true(room.has_destructible_tile(cell_b))
	assert_eq(room.get_destructible_health(cell_b), 100)


func test_replace_destructible_tile() -> void:
	var room = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	var test_cell := Vector2i(35, 35)

	# Place and damage a destructible block.
	room.place_destructible_tile(test_cell)
	room.damage_destructible_tile(test_cell, 30)

	# Replace it with a regular solid block.
	room.place_solid_tile(test_cell)

	# The old destructible block and health are gone.
	assert_false(room.has_destructible_tile(test_cell))
	assert_eq(room.get_destructible_health(test_cell), 0)

	# The new solid block exists.
	assert_true(room.has_solid_tile(test_cell))


func test_damage_destructible_at_world_position() -> void:
	var room = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.destructible_max_health = 100
	add_child_autofree(room)

	var test_cell := Vector2i(36, 36)
	room.place_destructible_tile(test_cell)

	# Find the global position at the center of this tile.
	var world_position: Vector2 = room.destructible_terrain.to_global(
		room.destructible_terrain.map_to_local(test_cell)
	)

	# Damage the tile through its world position.
	var destroyed: bool = room.damage_destructible_at_position(
		world_position,
		40
	)

	assert_false(destroyed)
	assert_eq(room.get_destructible_health(test_cell), 60)

	# Destroy the tile with a second hit.
	destroyed = room.damage_destructible_at_position(
		world_position,
		60
	)

	assert_true(destroyed)
	assert_false(room.has_destructible_tile(test_cell))


func test_terrain_hurtbox_receives_attack() -> void:
	var room = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.destructible_max_health = 100
	add_child_autofree(room)

	var test_cell := Vector2i(37, 37)
	room.place_destructible_tile(test_cell)

	# Find the hurtbox created for this tile.
	var hurtbox = room._destructible_hurtboxes[test_cell] as TerrainHurtbox

	assert_not_null(hurtbox)
	assert_true(hurtbox.get_collision_layer_value(3))

	# Create an attack that targets environment objects.
	var targets: Array[int] = [3]
	var attack := AttackStats.new(
		40,
		BaseStats.DamageType.DEFAULT,
		targets
	)

	# Deliver the attack to the terrain hurtbox.
	hurtbox.receive_hit(attack)
	await get_tree().process_frame

	assert_eq(room.get_destructible_health(test_cell), 60)

	# Destroy the tile with another attack.
	hurtbox.receive_hit(attack)
	hurtbox.receive_hit(attack)
	await get_tree().process_frame

	assert_false(room.has_destructible_tile(test_cell))
	assert_eq(room.get_destructible_health(test_cell), 0)


func test_hitbox_damages_destructible_terrain() -> void:
	var room = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.destructible_max_health = 100
	add_child_autofree(room)

	# Place a destructible tile.
	var test_cell := Vector2i(38, 38)
	room.place_destructible_tile(test_cell)

	# Create attack stats that target the environment.
	var targets: Array[int] = [3]

	var attack := AttackStats.new(
		40,
		BaseStats.DamageType.DEFAULT,
		targets
	)

	# Create a collision shape for our attack.
	var attack_shape := RectangleShape2D.new()
	attack_shape.size = Vector2(32, 32)

	# Create a real Hitbox using the team's system.
	var hitbox := Hitbox.new(
		attack,
		0.0,
		attack_shape
	)

	room.add_child(hitbox)

	# Position the hitbox directly over our tile.
	hitbox.global_position = room.destructible_terrain.to_global(
		room.destructible_terrain.map_to_local(test_cell)
	)

	# Allow Godot's physics engine to detect the overlap.
	for i in range(4):
		await get_tree().physics_frame

	# Allow deferred damage to be applied.
	await get_tree().process_frame

	# Verify that the collision caused damage.
	assert_true(room.has_destructible_tile(test_cell))
	assert_eq(room.get_destructible_health(test_cell), 60)


func test_hidden_passage_tile() -> void:
	var room = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	var test_cell := Vector2i(39, 39)

	# Start with a regular wall.
	room.place_solid_tile(test_cell)
	assert_true(room.has_solid_tile(test_cell))

	# Replace it with a hidden passage.
	room.place_hidden_passage_tile(test_cell)

	assert_true(room.has_hidden_passage_tile(test_cell))
	assert_false(room.has_solid_tile(test_cell))
	assert_false(room.has_platform_tile(test_cell))
	assert_false(room.has_destructible_tile(test_cell))

	# The hidden passage should use the solid tile's artwork.
	assert_eq(
		room.hidden_passages.get_cell_source_id(test_cell),
		room.solid_source_id
	)

	assert_eq(
		room.hidden_passages.get_cell_atlas_coords(test_cell),
		room.solid_atlas_coords
	)

	# Collision must be disabled for hidden passages.
	assert_false(room.hidden_passages.collision_enabled)

	# Removing the passage should clear the cell.
	room.remove_tile(test_cell)
	assert_false(room.has_hidden_passage_tile(test_cell))


func test_save_and_restore_room_data() -> void:
	var room = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	add_child_autofree(room)

	var solid_cell := Vector2i(40, 40)
	var platform_cell := Vector2i(41, 40)
	var destructible_cell := Vector2i(42, 40)
	var hidden_cell := Vector2i(43, 40)

	# Build a room containing every terrain type.
	room.place_solid_tile(solid_cell)
	room.place_platform_tile(platform_cell)
	room.place_destructible_tile(destructible_cell)
	room.place_hidden_passage_tile(hidden_cell)

	# Damage one block before saving.
	room.damage_destructible_tile(destructible_cell, 25)

	# Serialize and deserialize through JSON.
	var saved_data: Dictionary = room.get_room_data()
	var json_text: String = JSON.stringify(saved_data)
	var parsed_data: Variant = JSON.parse_string(json_text)

	assert_true(parsed_data is Dictionary)

	if not parsed_data is Dictionary:
		return

	# Remove our test tiles.
	room.remove_tile(solid_cell)
	room.remove_tile(platform_cell)
	room.remove_tile(destructible_cell)
	room.remove_tile(hidden_cell)

	# Restore the saved room.
	assert_true(room.load_room_data(parsed_data))

	# Verify every terrain type was restored.
	assert_true(room.has_solid_tile(solid_cell))
	assert_true(room.has_platform_tile(platform_cell))
	assert_true(room.has_destructible_tile(destructible_cell))
	assert_true(room.has_hidden_passage_tile(hidden_cell))

	# Check the one-way platform alternative.
	assert_eq(
		room.platforms.get_cell_alternative_tile(platform_cell),
		room.platform_alternative_id
	)

	# Check destructible health and combat detection.
	assert_eq(
		room.get_destructible_health(destructible_cell),
		75
	)

	assert_true(
		room._destructible_hurtboxes.has(destructible_cell)
	)


## Verify newly placed terrain has valid physics collision.
## Prevents incorrect TileSet source IDs from breaking movement.
func test_placed_terrain_has_collision_shapes() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	add_child_autofree(room)

	# Place each terrain type in a separate cell.
	var solid_cell := Vector2i(50, 50)
	var platform_cell := Vector2i(51, 50)
	var destructible_cell := Vector2i(52, 50)

	room.place_solid_tile(solid_cell)
	room.place_platform_tile(platform_cell)
	room.place_destructible_tile(destructible_cell)

	# Check all three terrain types.
	var terrain_checks: Array[Dictionary] = [
		{
			"layer": room.solid_terrain,
			"cell": solid_cell
		},
		{
			"layer": room.platforms,
			"cell": platform_cell
		},
		{
			"layer": room.destructible_terrain,
			"cell": destructible_cell
		}
	]

	for check in terrain_checks:
		var layer: TileMapLayer = check["layer"]
		var cell: Vector2i = check["cell"]

		# Confirm the tile was actually placed.
		assert_ne(
			layer.get_cell_source_id(cell),
			-1,
			"Terrain should have a valid source ID."
		)

		# Retrieve the tile's physics configuration.
		var tile_data: TileData = layer.get_cell_tile_data(cell)

		assert_not_null(
			tile_data,
			"Terrain should have valid TileData."
		)

		if tile_data == null:
			continue

		# Physics layer 0 must contain a collision polygon.
		assert_gt(
			tile_data.get_collision_polygons_count(0),
			0,
			"Terrain should have a collision polygon."
		)

		assert_true(
			layer.collision_enabled,
			"Terrain collision should be enabled."
		)

	# Verify that terrain uses the correct physics layers.
	assert_eq(
		room.solid_terrain.tile_set.get_physics_layer_collision_layer(0),
		1,
		"Solid terrain should use collision layer 1."
	)

	assert_eq(
		room.destructible_terrain.tile_set.get_physics_layer_collision_layer(0),
		1,
		"Destructible terrain should use collision layer 1."
	)

	assert_eq(
		room.platforms.tile_set.get_physics_layer_collision_layer(0),
		2,
		"Platforms should use collision layer 2."
	)


## Verify a sword swing damages destructible terrain only once,
## even though the ability creates multiple overlapping hitboxes.
func test_player_sword_damages_destructible_once_per_swing() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	room.destructible_max_health = 100
	add_child_autofree(room)

	# Create a destructible tile.
	var test_cell := Vector2i(80, 80)
	room.place_destructible_tile(test_cell)

	# Find the tile's position in world coordinates.
	var tile_position: Vector2 = (
		room.destructible_terrain.to_global(
			room.destructible_terrain.map_to_local(test_cell)
		)
	)

	# Create a player positioned to strike the tile.
	var player: Player = load(
		"res://scenes/Player.tscn"
	).instantiate()

	add_child_autofree(player)
	player.set_physics_process(false)

	# The Sword's first hitbox is 30 pixels ahead.
	player.global_position = tile_position - Vector2(30.0, 0.0)

	# The third ability is the Sword.
	var sword: Ability = player.abilities[2]

	# Verify the Sword can target the environment.
	assert_true(
		sword.data.stats.targets.has(BaseStats.Faction.ENVIRONMENT),
		"Sword should target destructible terrain."
	)

	# Perform one sword attack toward the tile.
	sword.use_ability(player, 1)

	# Allow physics to detect overlapping hitboxes.
	for i in range(4):
		await get_tree().physics_frame

	# Allow deferred terrain damage to finish.
	await get_tree().process_frame

	# One swing should deal exactly 30 damage.
	assert_eq(
		room.get_destructible_health(test_cell),
		70,
		"Sword should damage each tile only once per swing."
	)


## Verify one Knife attack can damage multiple destructible tiles
## without applying duplicate damage to either tile.
func test_player_knife_damages_multiple_destructible_tiles() -> void:
	var room: EditableRoom = load(
		"res://scenes/EditableRoom.tscn"
	).instantiate()

	room.edit_mode = false
	room.destructible_max_health = 100
	add_child_autofree(room)

	# Create two adjacent destructible tiles.
	var cell_a := Vector2i(90, 90)
	var cell_b := Vector2i(91, 90)

	room.place_destructible_tile(cell_a)
	room.place_destructible_tile(cell_b)

	# Determine the first tile's world position.
	var tile_position: Vector2 = (
		room.destructible_terrain.to_global(
			room.destructible_terrain.map_to_local(cell_a)
		)
	)

	# Create a stationary player facing the tiles.
	var player: Player = load(
		"res://scenes/Player.tscn"
	).instantiate()

	add_child_autofree(player)
	player.set_physics_process(false)

	# The Knife has a 30-pixel offset and a
	# 60-pixel-wide hitbox.
	player.global_position = tile_position - Vector2(30.0, 0.0)

	# The player's first ability is the Knife.
	var knife: Ability = player.abilities[0]

	assert_true(
		knife.data.stats.targets.has(BaseStats.Faction.ENVIRONMENT),
		"Knife should be able to damage destructible terrain."
	)

	# Perform one attack toward both tiles.
	knife.use_ability(player, 1)

	# Allow collision detection and deferred damage.
	for i in range(4):
		await get_tree().physics_frame

	await get_tree().process_frame

	# Both tiles should have taken exactly 10 damage.
	assert_eq(
		room.get_destructible_health(cell_a),
		90,
		"First tile should take 10 damage."
	)

	assert_eq(
		room.get_destructible_health(cell_b),
		90,
		"Second tile should take 10 damage."
	)
