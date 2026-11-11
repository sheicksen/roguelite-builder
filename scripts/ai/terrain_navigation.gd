
class_name TerrainNavigation
extends Node2D

## Automatically detects potential standing positions
## using the room's existing terrain layers.

@export var enemy_half_height: float = 16.0
@export var debug_enemy_half_width: float = 16.0
@export var debug_point_radius: float = 8.0

@onready var room: EditableRoom = get_parent() as EditableRoom

# World positions where an enemy could potentially stand.
var walkable_positions: Array[Vector2] = []
var _rebuild_queued: bool = false

# Stores our automatically generated navigation graph.
var astar: AStar2D = AStar2D.new()

# Maps terrain cells to their navigation point IDs.
var point_ids_by_cell: Dictionary = {}

# Stores possible jump connections between navigation points.
var candidate_jumps: Array[Vector2i] = []

# Jump connections that pass our initial distance check.
# These still need collision and landing validation.
var jump_connections: Array[Vector2i] = []

# Temporary visualization of a calculated route.
var debug_path: PackedVector2Array = PackedVector2Array()

@export_group("Jump Testing")
@export var debug_move_speed: float = 100.0
@export var debug_jump_height: float = 64.0



func _ready() -> void:
	# Allow enemies to discover the navigation system.
	add_to_group("terrain_navigation")

	# Listen for terrain modifications.
	room.terrain_changed.connect(_request_rebuild)



## Schedules one rebuild, even if many tiles change at once.
func _request_rebuild() -> void:
	if _rebuild_queued:
		return

	_rebuild_queued = true
	call_deferred("rebuild_navigation")


## Finds all potential standing positions in the room.
func rebuild_navigation() -> void:
	_rebuild_queued = false
	walkable_positions.clear()

	# Clear the previous graph before regenerating it.
	astar.clear()
	point_ids_by_cell.clear()
	candidate_jumps.clear()
	jump_connections.clear()

	var ground_cells: Dictionary = {}

	var terrain_layers: Array[TileMapLayer] = [
		room.solid_terrain,
		room.platforms,
		room.destructible_terrain
	]

	# Collect occupied terrain cells without duplicates.
	for layer in terrain_layers:
		for cell in layer.get_used_cells():
			ground_cells[cell] = true

	var tile_size: Vector2 = Vector2(
		room.solid_terrain.tile_set.tile_size
	)

	# Check whether each terrain cell has space above it.
	for cell in ground_cells.keys():
		var standing_cell: Vector2i = cell + Vector2i.UP

		if _is_occupied(standing_cell):
			continue

		# Locate the top surface of the terrain tile.
		var ground_center: Vector2 = room.solid_terrain.map_to_local(cell)

		var standing_position: Vector2 = ground_center - Vector2(
			0.0,
			tile_size.y / 2.0 + enemy_half_height
		)

		# Store the resulting position in world coordinates.
		var world_position: Vector2 = room.solid_terrain.to_global(
			standing_position
		)

		walkable_positions.append(world_position)

		# Register this standing position with AStar2D.
		var point_id: int = astar.get_available_point_id()
		astar.add_point(point_id, world_position)

		# Remember which terrain cell produced this point.
		point_ids_by_cell[cell] = point_id

	# Find platforms separated by exactly one empty tile.
	for cell in point_ids_by_cell.keys():
		var gap_cell: Vector2i = cell + Vector2i.RIGHT
		var landing_cell: Vector2i = cell + Vector2i(2, 0)

		# A walking connection already exists here.
		if point_ids_by_cell.has(gap_cell):
			continue

		# There must be a standing position across the gap.
		if not point_ids_by_cell.has(landing_cell):
			continue

		# Reject gaps blocked by terrain.
		if _is_occupied(gap_cell):
			continue

		if _is_occupied(gap_cell + Vector2i.UP):
			continue

		# Store the potential jump.
		var from_id: int = point_ids_by_cell[cell]
		var to_id: int = point_ids_by_cell[landing_cell]

		candidate_jumps.append(Vector2i(from_id, to_id))

	print("Candidate jumps: ", candidate_jumps.size())


	# Use the project's default gravity for our initial test.
	var gravity: float = float(
		ProjectSettings.get_setting("physics/2d/default_gravity")
	)

	var max_jump_distance: float = estimate_max_jump_distance(
		debug_move_speed,
		debug_jump_height,
		gravity
	)

	# Check each candidate gap.
	# Evaluate potential jumps and add reachable ones to AStar.
	for connection in candidate_jumps:
		var start: Vector2 = astar.get_point_position(connection.x)
		var end: Vector2 = astar.get_point_position(connection.y)

		# For now, only allow jumps between equal-height platforms.
		if absf(start.y - end.y) > 1.0:
			continue

		var distance: float = absf(end.x - start.x)
		var within_range: bool = distance <= max_jump_distance

		print(
			"Jump distance: ", distance,
			" | Maximum: ", max_jump_distance,
			" | Within range: ", within_range
		)


		var clear_path: bool = false

		if within_range:
			clear_path = is_jump_arc_clear(
				start,
				end,
				gravity
			)

		print("Jump arc clear: ", clear_path)

		if within_range and clear_path:
			astar.connect_points(connection.x, connection.y, true)
			jump_connections.append(connection)

	print("Provisional jump connections: ", jump_connections.size())

	# Connect adjacent walkable cells horizontally.
	var walking_connections: int = 0

	for cell in point_ids_by_cell.keys():
		var neighbor_cell: Vector2i = cell + Vector2i.RIGHT

		# Only connect points if both cells are walkable.
		if point_ids_by_cell.has(neighbor_cell):
			var from_id: int = point_ids_by_cell[cell]
			var to_id: int = point_ids_by_cell[neighbor_cell]

			astar.connect_points(from_id, to_id)
			walking_connections += 1

	print("Walking connections: ", walking_connections)

	# Test a route between the leftmost and rightmost points.
	debug_path.clear()

	if walkable_positions.size() >= 2:
		var leftmost: Vector2 = walkable_positions[0]
		var rightmost: Vector2 = walkable_positions[0]

		for position in walkable_positions:
			if position.x < leftmost.x:
				leftmost = position

			if position.x > rightmost.x:
				rightmost = position

		if leftmost != rightmost:
			debug_path = get_navigation_path(leftmost, rightmost)

			# Inspect movement instructions along the route.
			var steps: Array[Dictionary] = get_navigation_steps(
				leftmost,
				rightmost
			)

			for step in steps:
				if step["movement"] == "jump":
					print("Navigation requires JUMP to: ", step["position"])

	print("Path contains ", debug_path.size(), " points")

	queue_redraw()

	print("Generated navigation positions: ", walkable_positions.size())


## Checks whether a tile position is occupied by terrain.
func _is_occupied(cell: Vector2i) -> bool:
	return (
		room.has_solid_tile(cell)
		or room.has_platform_tile(cell)
		or room.has_destructible_tile(cell)
	)


## Draw debug markers at generated standing positions.
func _draw() -> void:
	# Draw walking connections as green lines.
	for point_id in astar.get_point_ids():
		var start_position: Vector2 = astar.get_point_position(point_id)

		for neighbor_id in astar.get_point_connections(point_id):
			# Draw each two-way connection only once.
			if point_id < neighbor_id:
				var end_position: Vector2 = astar.get_point_position(neighbor_id)

				draw_line(
					to_local(start_position),
					to_local(end_position),
					Color.GREEN,
					3.0
				)

	# Draw standing positions as cyan circles.
	for world_position in walkable_positions:
		draw_circle(
			to_local(world_position),
			debug_point_radius,
			Color.CYAN
		)

	# Draw the calculated route in yellow.
	for i in range(debug_path.size() - 1):
		draw_line(
			to_local(debug_path[i]),
			to_local(debug_path[i + 1]),
			Color.YELLOW,
			5.0
		)

	# Draw potential jump connections in orange.
	for connection in candidate_jumps:
		var start_position: Vector2 = astar.get_point_position(
			connection.x
		)

		var end_position: Vector2 = astar.get_point_position(
			connection.y
		)

		draw_line(
			to_local(start_position),
			to_local(end_position),
			Color.ORANGE,
			4.0
		)


## Calculates a path between two world positions.
## Returns an empty path if no route exists.
func get_navigation_path(
	from_position: Vector2,
	to_position: Vector2
) -> PackedVector2Array:
	if astar.get_point_count() == 0:
		return PackedVector2Array()

	# Find the nearest navigation points.
	var start_id: int = astar.get_closest_point(from_position)
	var end_id: int = astar.get_closest_point(to_position)

	if start_id == -1 or end_id == -1:
		return PackedVector2Array()

	# Let AStar2D calculate the route.
	return astar.get_point_path(start_id, end_id)

## Estimates horizontal travel during a jump
## that starts and ends at the same height.
func estimate_max_jump_distance(
	move_speed: float,
	jump_height: float,
	gravity: float
) -> float:
	if move_speed <= 0.0 or jump_height <= 0.0 or gravity <= 0.0:
		return 0.0

	# Match the jump velocity calculation in BaseEnemy.
	var jump_velocity: float = sqrt(2.0 * gravity * jump_height)

	# Time to rise and fall back to the starting height.
	var time_in_air: float = 2.0 * jump_velocity / gravity

	return move_speed * time_in_air

## Checks whether the enemy would overlap solid terrain
## at a given world position.
func is_position_blocked(world_position: Vector2) -> bool:
	var half_width: float = debug_enemy_half_width - 0.5
	var half_height: float = enemy_half_height - 0.5

	# Check all four corners of the enemy's collision box.
	var corners: Array[Vector2] = [
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(-half_width, half_height),
		Vector2(half_width, half_height)
	]

	var blocking_layers: Array[TileMapLayer] = [
		room.solid_terrain,
		room.destructible_terrain
	]

	for corner in corners:
		var point: Vector2 = world_position + corner

		for layer in blocking_layers:
			var local_point: Vector2 = layer.to_local(point)
			var cell: Vector2i = layer.local_to_map(local_point)

			if layer.get_cell_source_id(cell) != -1:
				return true

	return false


## Simulates a same-height jump and checks for obstacles.
func is_jump_arc_clear(
	start: Vector2,
	end: Vector2,
	gravity: float
) -> bool:
	if gravity <= 0.0 or debug_jump_height <= 0.0:
		return false

	var jump_speed: float = sqrt(
		2.0 * gravity * debug_jump_height
	)

	var flight_time: float = 2.0 * jump_speed / gravity
	var horizontal_speed: float = (end.x - start.x) / flight_time

	# Reject jumps requiring too much horizontal speed.
	if absf(horizontal_speed) > debug_move_speed:
		return false

	# Sample positions along the predicted jump.
	var samples: int = 24

	for i in range(1, samples + 1):
		var time: float = flight_time * float(i) / float(samples)

		var position: Vector2 = Vector2(
			start.x + horizontal_speed * time,
			start.y - jump_speed * time
				+ 0.5 * gravity * time * time
		)

		if is_position_blocked(position):
			print("Jump blocked at sample ", i, ": ", position)
			return false

	return true

## Returns a route with movement instructions.
## Each step contains a position and a movement type.
func get_navigation_steps(
	from_position: Vector2,
	to_position: Vector2
) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []

	if astar.get_point_count() == 0:
		return steps

	var start_id: int = astar.get_closest_point(from_position)
	var end_id: int = astar.get_closest_point(to_position)

	if start_id == -1 or end_id == -1:
		return steps

	var path_ids: PackedInt64Array = astar.get_id_path(
		start_id,
		end_id
	)

	for i in range(path_ids.size()):
		var current_id: int = path_ids[i]
		var movement: String = "start"

		if i > 0:
			var previous_id: int = path_ids[i - 1]

			# Check whether this connection requires jumping.
			var forward: Vector2i = Vector2i(
				previous_id,
				current_id
			)

			var backward: Vector2i = Vector2i(
				current_id,
				previous_id
			)

			if jump_connections.has(forward) or jump_connections.has(backward):
				movement = "jump"
			else:
				movement = "walk"

		steps.append({
			"position": astar.get_point_position(current_id),
			"movement": movement
		})

	return steps
