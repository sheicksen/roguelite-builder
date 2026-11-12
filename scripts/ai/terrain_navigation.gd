
class_name TerrainNavigation
extends Node2D

## Emitted whenever the navigation graph has finished rebuilding.
signal navigation_rebuilt

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

# Possible downward connections between platforms.
var candidate_drops: Array[Vector2i] = []

# Validated drop connections used by A*.
var drop_connections: Array[Vector2i] = []

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
	candidate_drops.clear()
	drop_connections.clear()

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


	# Find potential upward jumps to nearby higher platforms.
	for cell in point_ids_by_cell.keys():
		# Look one or two tiles to either side.
		for horizontal_offset in [-2, -1, 1, 2]:
			# Look for platforms one or two tiles higher.
			for rise in [1, 2]:
				var landing_cell: Vector2i = (
					cell + Vector2i(horizontal_offset, -rise)
				)

				if not point_ids_by_cell.has(landing_cell):
					continue

				var from_id: int = point_ids_by_cell[cell]
				var to_id: int = point_ids_by_cell[landing_cell]

				var connection := Vector2i(from_id, to_id)

				# Store the upward jump as a directional candidate.
				if not candidate_jumps.has(connection):
					candidate_jumps.append(connection)


	# Find possible drops from exposed platform edges.
	for cell in point_ids_by_cell.keys():
		# Check both directions.
		for direction in [-1, 1]:
			var edge_cell: Vector2i = (
				cell + Vector2i(direction, 0)
			)

			# A drop must begin at an exposed edge.
			if _is_occupied(edge_cell):
				continue

			# Search up to three tiles horizontally
			# and three tiles below the starting platform.
			for horizontal_distance in range(1, 4):
				for drop_depth in range(1, 4):
					var landing_cell: Vector2i = (
						cell + Vector2i(
							direction * horizontal_distance,
							drop_depth
						)
					)

					if not point_ids_by_cell.has(landing_cell):
						continue

					var from_id: int = point_ids_by_cell[cell]
					var to_id: int = point_ids_by_cell[landing_cell]

					var connection := Vector2i(from_id, to_id)

					if not candidate_drops.has(connection):
						candidate_drops.append(connection)


	# Use the project's default gravity for our initial test.
	var gravity: float = float(
		ProjectSettings.get_setting("physics/2d/default_gravity")
	)

	var max_jump_distance: float = estimate_max_jump_distance(
		debug_move_speed,
		debug_jump_height,
		gravity
	)


	# Validate horizontal gaps and jumps to higher platforms.
	for connection in candidate_jumps:
		var start: Vector2 = astar.get_point_position(connection.x)
		var end: Vector2 = astar.get_point_position(connection.y)

		# Godot's Y coordinates increase downward.
		var same_height: bool = absf(end.y - start.y) <= 1.0
		var upward_jump: bool = end.y < start.y - 1.0

		# Downward movement will have its own logic later.
		if not same_height and not upward_jump:
			continue

		# Validate jump distance, flight time, and clearance.
		if not is_jump_arc_clear(start, end, gravity):
			continue

		# Same-height jumps work in both directions.
		# Upward jumps are directional.
		astar.connect_points(
			connection.x,
			connection.y,
			same_height
		)

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

	# Validate possible drops and connect reachable platforms.
	for connection in candidate_drops:
		var start: Vector2 = astar.get_point_position(
			connection.x
		)

		var destination: Vector2 = astar.get_point_position(
			connection.y
		)

		# Reject drops that are too far away or obstructed.
		if not is_drop_path_clear(start, destination, gravity):
			continue

		# Create a one-way route from higher to lower.
		astar.connect_points(
			connection.x,
			connection.y,
			false
		)

		drop_connections.append(connection)

	print("Valid drop connections: ", drop_connections.size())

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

	# Notify enemies that the navigation graph has changed.
	navigation_rebuilt.emit()

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


## Calculate how long a jump takes to reach a landing
## height while descending.
## Returns -1 if the destination is too high.
func estimate_jump_landing_time(
	start_y: float,
	end_y: float,
	jump_height: float,
	gravity: float
) -> float:
	if jump_height <= 0.0 or gravity <= 0.0:
		return -1.0

	# Match BaseEnemy's jumping physics.
	var launch_speed: float = sqrt(
		2.0 * gravity * jump_height
	)

	# In Godot, negative Y means higher up.
	var height_difference: float = end_y - start_y

	# Solve the vertical motion equation.
	var discriminant: float = (
		launch_speed * launch_speed
		+ 2.0 * gravity * height_difference
	)

	# The jump cannot reach the required height.
	if discriminant < 0.0:
		return -1.0

	# Choose the descending solution.
	var landing_time: float = (
		launch_speed + sqrt(discriminant)
	) / gravity

	return landing_time


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


## Validates a jump using a vertical-first approach
## for elevated destinations.
func is_jump_arc_clear(
	start: Vector2,
	end: Vector2,
	gravity: float
) -> bool:
	if gravity <= 0.0 or debug_jump_height <= 0.0:
		return false

	var flight_time: float = estimate_jump_landing_time(
		start.y,
		end.y,
		debug_jump_height,
		gravity
	)

	if flight_time <= 0.0:
		return false

	var jump_speed: float = sqrt(
		2.0 * gravity * debug_jump_height
	)

	var horizontal_delay: float = 0.0

	# For higher platforms, wait until the enemy's
	# feet clear the landing surface before moving sideways.
	if end.y < start.y - 1.0:
		var required_rise: float = start.y - end.y + 1.0

		var discriminant: float = (
			jump_speed * jump_speed
			- 2.0 * gravity * required_rise
		)

		if discriminant < 0.0:
			return false

		# Time when the enemy first reaches this height.
		horizontal_delay = (
			jump_speed - sqrt(discriminant)
		) / gravity

	var horizontal_distance: float = absf(end.x - start.x)
	var horizontal_time: float = flight_time - horizontal_delay

	# Ensure sufficient time remains to move horizontally.
	if horizontal_distance > debug_move_speed * horizontal_time:
		return false

	var horizontal_direction: float = signf(end.x - start.x)

	# Sample the same vertical-first trajectory.
	var samples: int = 48

	for i in range(1, samples + 1):
		var time: float = (
			flight_time * float(i) / float(samples)
		)

		var moving_time: float = maxf(
			time - horizontal_delay,
			0.0
		)

		var distance_traveled: float = minf(
			horizontal_distance,
			debug_move_speed * moving_time
		)

		var position := Vector2(
			start.x + horizontal_direction * distance_traveled,
			start.y - jump_speed * time
				+ 0.5 * gravity * time * time
		)

		if is_position_blocked(position):
			print("Jump blocked at sample ", i, ": ", position)
			return false

	return true


## Checks whether an enemy can walk off an edge
## and fall safely toward a lower platform.
func is_drop_path_clear(
	start: Vector2,
	end: Vector2,
	gravity: float
) -> bool:
	if gravity <= 0.0 or debug_move_speed <= 0.0:
		return false

	# A drop must lead to a lower destination.
	if end.y <= start.y:
		return false

	var direction: float = signf(end.x - start.x)

	# Vertical drop-through movement will be handled separately.
	if direction == 0.0:
		return false

	var tile_width: float = float(
		room.solid_terrain.tile_set.tile_size.x
	)

	# Walk far enough that the enemy's entire collision box
	# is beyond the edge of the starting tile.
	var launch_distance: float = (
		tile_width / 2.0
		+ debug_enemy_half_width
		+ 1.0
	)

	var launch_position := Vector2(
		start.x + direction * launch_distance,
		start.y
	)

	# Horizontal distance remaining after leaving the edge.
	var remaining_distance: float = (
		(end.x - launch_position.x) * direction
	)

	if remaining_distance < 0.0:
		return false

	# Calculate falling time using gravity.
	var fall_height: float = end.y - start.y
	var fall_time: float = sqrt(
		2.0 * fall_height / gravity
	)

	# Reject destinations that cannot be reached horizontally.
	if remaining_distance > debug_move_speed * fall_time:
		return false

	# Check for obstacles while moving off the ledge.
	for i in range(1, 17):
		var fraction: float = float(i) / 16.0
		var position: Vector2 = start.lerp(
			launch_position,
			fraction
		)

		if is_position_blocked(position):
			return false

	# Simulate falling toward the lower platform.
	var samples: int = 48

	for i in range(1, samples + 1):
		var time: float = (
			fall_time * float(i) / float(samples)
		)

		var horizontal_movement: float = minf(
			remaining_distance,
			debug_move_speed * time
		)

		var position := Vector2(
			launch_position.x + direction * horizontal_movement,
			start.y + 0.5 * gravity * time * time
		)

		if is_position_blocked(position):
			print("Drop blocked at sample ", i, ": ", position)
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

			# Check whether this connection is a downward drop.
			if drop_connections.has(forward):
				movement = "drop"

			# Otherwise, check whether jumping is required.
			elif jump_connections.has(forward) or jump_connections.has(backward):
				movement = "jump"

			else:
				movement = "walk"


		steps.append({
			"position": astar.get_point_position(current_id),
			"movement": movement
		})

	return steps
