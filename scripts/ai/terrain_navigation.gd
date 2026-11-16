
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

# Navigation graph for enemies that cannot jump.
var no_jump_astar: AStar2D = AStar2D.new()

# Cached graphs for different enemy movement configurations.
var capability_graph_cache: Dictionary = {}

# Stores approved jump heights for each capability graph.
# Each jump is identified by its starting and ending point IDs.
var jump_heights_by_graph: Dictionary = {}

# Maps terrain cells to their navigation point IDs.
var point_ids_by_cell: Dictionary = {}

# Stores possible jump connections between navigation points.
var candidate_jumps: Array[Vector2i] = []

# Possible downward connections between platforms.
var candidate_drops: Array[Vector2i] = []

# Possible drops directly through one-way platforms.
var candidate_vertical_drops: Array[Vector2i] = []

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

@export_group("Debug")
@export var debug_logging: bool = false


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
	no_jump_astar.clear()
	point_ids_by_cell.clear()
	candidate_jumps.clear()
	jump_connections.clear()
	candidate_drops.clear()
	drop_connections.clear()
	candidate_vertical_drops.clear()
	capability_graph_cache.clear()
	jump_heights_by_graph.clear()

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
		no_jump_astar.add_point(point_id, world_position)

		# Remember which terrain cell produced this point.
		point_ids_by_cell[cell] = point_id

	# Find horizontal gaps that enemies may be able to jump across.
	for cell in point_ids_by_cell.keys():

		# Check landing positions from 2 to 5 tiles away.
		for distance in range(2, 6):

			var landing_cell: Vector2i = (
				cell + Vector2i(distance, 0)
			)

			# The destination must have a standing position.
			if not point_ids_by_cell.has(landing_cell):
				continue

			var gap_clear: bool = true

		# Check every intermediate tile for obstacles.
			for offset in range(1, distance):
				var gap_cell: Vector2i = (
					cell + Vector2i(offset, 0)
				)

				if (
					_is_occupied(gap_cell)
					or _is_occupied(gap_cell + Vector2i.UP)
				):
					gap_clear = false
					break

				if not gap_clear:
					continue

				var from_id: int = point_ids_by_cell[cell]
				var to_id: int = point_ids_by_cell[landing_cell]

				var connection := Vector2i(from_id, to_id)

				if not candidate_jumps.has(connection):
					candidate_jumps.append(connection)

	# Find potential upward jumps to nearby higher platforms.
	for cell in point_ids_by_cell.keys():
		# Consider jumps up to four tiles horizontally.
		# Each enemy's movement capabilities determine
		# whether these connections are actually usable.
		for horizontal_offset in range(-4, 5):

			# Look for platforms one or two tiles higher.
			for rise in [1, 2, 3]:
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

	# Find possible vertical drops through one-way platforms.
	for cell in point_ids_by_cell.keys():

		# Only one-way platforms can be dropped through.
		if not room.has_platform_tile(cell):
			continue

		# Look for standing positions below this platform.
		for depth in range(2, 7):
			var landing_cell: Vector2i = (
				cell + Vector2i(0, depth)
			)

			if not point_ids_by_cell.has(landing_cell):
				continue

			var from_id: int = point_ids_by_cell[cell]
			var to_id: int = point_ids_by_cell[landing_cell]

			var connection := Vector2i(from_id, to_id)

			if not candidate_vertical_drops.has(connection):
				candidate_vertical_drops.append(connection)

			# Use the nearest potential landing surface.
			break

	if debug_logging:
		print(
			"Vertical drop candidates: ",
			candidate_vertical_drops.size()
		)

	# Keep only vertical drops with a clear path.
	var valid_vertical_drops: Array[Vector2i] = []

	for connection in candidate_vertical_drops:
		var start: Vector2 = astar.get_point_position(
			connection.x
		)

		var destination: Vector2 = astar.get_point_position(
			connection.y
		)

		if is_vertical_drop_clear(start, destination):
			valid_vertical_drops.append(connection)

	candidate_vertical_drops = valid_vertical_drops

	if debug_logging:
		print(
			"Valid vertical drops: ",
			candidate_vertical_drops.size()
		)
		
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


	# Get the project's gravity for trajectory validation.
	var gravity: float = float(
		ProjectSettings.get_setting("physics/2d/default_gravity")
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

	if debug_logging:
		print("Provisional jump connections: ", jump_connections.size())

	# Add walking connections to both default graphs.
	var walking_connections: int = _connect_walking_connections(
		astar
	)

	_connect_walking_connections(no_jump_astar)

	if debug_logging:
		print("Walking connections: ", walking_connections)

	if debug_logging:
		print("Candidate drop connections: ", candidate_drops.size())

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

		# Non-jumping enemies can also drop downward.
		no_jump_astar.connect_points(
			connection.x,
			connection.y,
			false
		)

		drop_connections.append(connection)

	if debug_logging:
		print("Valid drop connections: ", drop_connections.size())

	# Connect validated vertical drops to the navigation graphs.
	for connection in candidate_vertical_drops:

		# Vertical drops only work downward.
		astar.connect_points(
			connection.x,
			connection.y,
			false
		)

		# Enemies without jumping abilities can also drop.
		no_jump_astar.connect_points(
			connection.x,
			connection.y,
			false
		)

	if debug_logging:
		print(
			"Vertical drop connections added: ",
			candidate_vertical_drops.size()
		)
		
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
				if debug_logging and step["movement"] == "jump":
					print("Navigation requires JUMP to: ", step["position"])


	if debug_logging:
		print("Path contains ", debug_path.size(), " points")

	queue_redraw()

	if debug_logging:
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


## Connects adjacent walkable terrain positions in the given graph.
## Returns the number of walking connections created.
func _connect_walking_connections(graph: AStar2D) -> int:
	var connection_count: int = 0

	for cell in point_ids_by_cell.keys():
		var neighbor_cell: Vector2i = cell + Vector2i.RIGHT

		# Both cells must have valid standing positions.
		if not point_ids_by_cell.has(neighbor_cell):
			continue

		var from_id: int = point_ids_by_cell[cell]
		var to_id: int = point_ids_by_cell[neighbor_cell]

		# Walking is allowed in both directions.
		graph.connect_points(from_id, to_id, true)
		connection_count += 1

	return connection_count


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
	# Include a small horizontal clearance margin.
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


## Validates a jump using configurable movement capabilities.
## Defaults to debug settings when no values are supplied.
func is_jump_arc_clear(
	start: Vector2,
	end: Vector2,
	gravity: float,
	move_speed: float = -1.0,
	jump_height: float = -1.0
) -> bool:
	# Preserve existing behavior for calls without overrides.
	var actual_speed: float = (
		debug_move_speed if move_speed < 0.0 else move_speed
	)

	var actual_jump_height: float = (
		debug_jump_height if jump_height < 0.0 else jump_height
	)

	if gravity <= 0.0 or actual_jump_height <= 0.0:
		return false

	if actual_speed <= 0.0:
		return false

	# Calculate the time available to reach the landing.
	var flight_time: float = estimate_jump_landing_time(
		start.y,
		end.y,
		actual_jump_height,
		gravity
	)

	if flight_time <= 0.0:
		return false

	var jump_speed: float = sqrt(
		2.0 * gravity * actual_jump_height
	)

	var horizontal_delay: float = 0.0

	# Higher platforms require vertical clearance first.
	if end.y < start.y - 1.0:
		var required_rise: float = start.y - end.y + 1.0

		var discriminant: float = (
			jump_speed * jump_speed
			- 2.0 * gravity * required_rise
		)

		if discriminant < 0.0:
			return false

		horizontal_delay = (
			jump_speed - sqrt(discriminant)
		) / gravity

	var horizontal_distance: float = absf(end.x - start.x)
	var horizontal_time: float = flight_time - horizontal_delay

	if horizontal_distance > actual_speed * horizontal_time:
		if debug_logging:
			print("--- JUMP DISTANCE FAILED ---")
			print("Jump height: ", actual_jump_height)
			print("Movement speed: ", actual_speed)
			print("Gravity: ", gravity)
			print("Required distance: ", horizontal_distance)
			print(
				"Maximum horizontal distance: ",
				actual_speed * horizontal_time
			)
			print("--- END JUMP DISTANCE ---")

		return false

	var horizontal_direction: float = signf(end.x - start.x)

	# Simulate the jump and check for obstacles.
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
			actual_speed * moving_time
		)

		var position := Vector2(
			start.x + horizontal_direction * distance_traveled,
			start.y - jump_speed * time
				+ 0.5 * gravity * time * time
		)

		if is_position_blocked(position):
			if debug_logging:
				print("--- JUMP COLLISION DETECTED ---")
				print("Jump start: ", start)
				print("Jump destination: ", end)
				print("Blocked position: ", position)
				print("Sample: ", i, "/", samples)
								# Identify which terrain tile blocks the jump.
				var corners: Array[Vector2] = [
					Vector2(-15.5, -15.5),
					Vector2(15.5, -15.5),
					Vector2(-15.5, 15.5),
					Vector2(15.5, 15.5)
				]

				var blocking_layers: Array[TileMapLayer] = [
					room.solid_terrain,
					room.destructible_terrain
				]

				for layer in blocking_layers:
					for corner in corners:
						var check_position: Vector2 = (
							position + corner
						)

						var local_position: Vector2 = (
							layer.to_local(check_position)
						)

						var cell: Vector2i = (
							layer.local_to_map(local_position)
						)

						if layer.get_cell_source_id(cell) != -1:
							print("Blocking layer: ", layer.name)
							print("Blocking tile: ", cell)
							print("Collision corner: ", corner)

				print("--- END JUMP COLLISION ---")

			return false

	return true


## Finds the lowest valid jump height for a connection.
## Returns -1 if no tested jump can reach the destination.
func find_valid_jump_height(
	start: Vector2,
	destination: Vector2,
	gravity: float,
	horizontal_speed: float,
	max_jump_height: float
) -> float:

	if max_jump_height <= 0.0:
		return -1.0

	# Test short jumps first, then progressively higher ones.
	var test_heights: Array[float] = [
		48.0,
		56.0,
		60.0,
		64.0,
		68.0,
		72.0,
		80.0,
		96.0,
		112.0,
		128.0
	]

	# Always include the enemy's maximum jump height.
	test_heights.append(max_jump_height)
	test_heights.sort()

	for test_height in test_heights:

		# Never exceed the enemy's configured jump height.
		if test_height > max_jump_height:
			continue

		if is_jump_arc_clear(
			start,
			destination,
			gravity,
			horizontal_speed,
			test_height
		):
			return test_height

	return -1.0


## Builds or retrieves a graph using an enemy's movement settings.
func get_capability_graph(
	move_speed: float,
	jump_height: float,
	jump_move_speed: float = -1.0
) -> AStar2D:
	# Enemies without usable jump capabilities can only
	# walk and follow existing drop connections.
	# An enemy with no movement speed cannot navigate.
	if move_speed <= 0.0:
		return AStar2D.new()

	var actual_jump_speed: float = (
		move_speed if jump_move_speed < 0.0 else jump_move_speed
	)

	var cache_key: String = str(
		move_speed, ":", jump_height, ":", actual_jump_speed
	)

	# Reuse an existing graph for matching configurations.
	if capability_graph_cache.has(cache_key):
		return capability_graph_cache[cache_key] as AStar2D

	var graph := AStar2D.new()

	# Copy the terrain's standing positions.
	for point_id in astar.get_point_ids():
		graph.add_point(
			point_id,
			astar.get_point_position(point_id)
		)

	# Walking connections are available to all enemies.
	_connect_walking_connections(graph)

	# Get the project's gravity for movement validation.
	var gravity: float = float(
		ProjectSettings.get_setting("physics/2d/default_gravity")
	)

	# Validate drops using this enemy's movement speed.
	for connection in candidate_drops:
		var start: Vector2 = astar.get_point_position(
			connection.x
		)

		var destination: Vector2 = astar.get_point_position(
			connection.y
		)

		# Reject drops this enemy cannot complete.
		if not is_drop_path_clear(
			start,
			destination,
			gravity,
			move_speed
		):
			continue

		# Connect valid drops in the downward direction only.
		graph.connect_points(
			connection.x,
			connection.y,
			false
		)

	# Vertical drops are available regardless of jump ability.
	for connection in candidate_vertical_drops:
		graph.connect_points(
			connection.x,
			connection.y,
			false
		)

	# Store validated heights for individual jump connections.
	var chosen_jump_heights: Dictionary = {}

	for connection in candidate_jumps:
		var start: Vector2 = astar.get_point_position(
			connection.x
		)

		var destination: Vector2 = astar.get_point_position(
			connection.y
		)

		# Downward movement uses drop connections.
		if destination.y > start.y + 1.0:
			continue

		# Preserve our existing takeoff clearance check.
		if destination.y < start.y - 1.0:
			var away_from_platform: float = -signf(
				destination.x - start.x
			)

			var safe_takeoff: Vector2 = start + Vector2(
				away_from_platform * 4.0,
				0.0
			)

			if is_position_blocked(safe_takeoff):
				continue

		var same_height: bool = (
			absf(destination.y - start.y) <= 1.0
		)

		# Find a jump height that clears the terrain.
		var forward_height: float = find_valid_jump_height(
			start,
			destination,
			gravity,
			actual_jump_speed,
			jump_height
		)

		var reverse_height: float = -1.0

		# Same-height jumps may be possible in both directions.
		if same_height:
			reverse_height = find_valid_jump_height(
				destination,
				start,
				gravity,
				actual_jump_speed,
				jump_height
			)

		# Connect only directions that passed validation.
		if forward_height > 0.0 and reverse_height > 0.0:
			graph.connect_points(
				connection.x,
				connection.y,
				true
			)

		elif forward_height > 0.0:
			graph.connect_points(
				connection.x,
				connection.y,
				false
			)

		elif reverse_height > 0.0:
			graph.connect_points(
				connection.y,
				connection.x,
				false
			)

		# Remember the selected height for each direction.
		if forward_height > 0.0:
			chosen_jump_heights[
				Vector2i(connection.x, connection.y)
			] = forward_height

		if reverse_height > 0.0:
			chosen_jump_heights[
				Vector2i(connection.y, connection.x)
			] = reverse_height

	# Keep jump heights associated with this particular graph.
	jump_heights_by_graph[graph.get_instance_id()] = (
		chosen_jump_heights
	)
	
	# Cache this configuration for future path requests.
	capability_graph_cache[cache_key] = graph

	return graph


func is_drop_path_clear(
	start: Vector2,
	end: Vector2,
	gravity: float,
	move_speed: float = -1.0
) -> bool:
	# Use the enemy's movement speed when provided.
	# Otherwise, use the default debug speed.
	var actual_speed: float = (
		debug_move_speed if move_speed < 0.0 else move_speed
	)

	if gravity <= 0.0 or actual_speed <= 0.0:
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

	# Allow the one-pixel clearance margin to place the
	# enemy slightly beyond the landing tile's center.
	# The enemy can still land safely at this position.
	if remaining_distance < -1.0:
		return false

	# No additional horizontal movement is needed when
	# the launch position is already over the landing tile.
	remaining_distance = maxf(remaining_distance, 0.0)

	# Calculate falling time using gravity.
	var fall_height: float = end.y - start.y
	var fall_time: float = sqrt(
		2.0 * fall_height / gravity
	)

	# Reject destinations that cannot be reached horizontally.
	if remaining_distance > actual_speed * fall_time:
		if debug_logging:
			print(
				"DROP REJECTED - insufficient horizontal reach: ",
				start, " -> ", end,
				" | Needed: ", remaining_distance,
				" | Available: ", actual_speed * fall_time
			)
		return false


	# Check for obstacles while moving off the ledge.
	for i in range(1, 17):
		var fraction: float = float(i) / 16.0
		var position: Vector2 = start.lerp(
			launch_position,
			fraction
		)

		if is_position_blocked(position):
			if debug_logging:
				print(
					"DROP REJECTED - blocked during launch: ",
					start, " -> ", end,
					" | Position: ", position
				)
			return false


	# Simulate falling toward the lower platform.
	var samples: int = 48

	for i in range(1, samples + 1):
		var time: float = (
			fall_time * float(i) / float(samples)
		)

		var horizontal_movement: float = minf(
			remaining_distance,
			actual_speed * time
		)

		var position := Vector2(
			launch_position.x + direction * horizontal_movement,
			start.y + 0.5 * gravity * time * time
		)

		if is_position_blocked(position):
			if debug_logging:
				print("Drop blocked at sample ", i, ": ", position)
			return false


	return true


## Checks whether an enemy can drop vertically
## through a one-way platform to a lower surface.
func is_vertical_drop_clear(
	start: Vector2,
	destination: Vector2
) -> bool:

	# Destination must be below the starting position.
	if destination.y <= start.y:
		return false

	# Check the vertical path for solid obstacles.
	var tile_size: Vector2i = room.solid_terrain.tile_set.tile_size

	var start_local: Vector2 = room.solid_terrain.to_local(start)
	var end_local: Vector2 = room.solid_terrain.to_local(destination)

	var start_cell: Vector2i = room.solid_terrain.local_to_map(start_local)
	var end_cell: Vector2i = room.solid_terrain.local_to_map(end_local)

	# Examine the tile rows between the two surfaces.
	for y in range(start_cell.y + 1, end_cell.y):

		var cell := Vector2i(start_cell.x, y)

		# Solid and destructible terrain block dropping.
		if room.has_solid_tile(cell):
			return false

		if room.has_destructible_tile(cell):
			return false

	return true


## Returns a route using the enemy's movement capabilities.
func get_navigation_steps(
	from_position: Vector2,
	to_position: Vector2,
	can_jump: bool = true,
	move_speed: float = -1.0,
	jump_height: float = -1.0,
	jump_move_speed: float = -1.0
) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []

	# Choose a graph based on the enemy's capabilities.
	var path_graph: AStar2D = astar

	if move_speed >= 0.0:
		if not can_jump:
			# Disable jumping, but retain speed-aware drops.
			path_graph = get_capability_graph(
				move_speed,
				0.0,
				jump_move_speed
			)
		elif jump_height >= 0.0:
			path_graph = get_capability_graph(
				move_speed,
				jump_height,
				jump_move_speed
			)

	elif not can_jump:
		# Compatibility with older calls without speed values.
		path_graph = no_jump_astar

	if path_graph.get_point_count() == 0:
		return steps

	var start_id: int = path_graph.get_closest_point(
		from_position
	)

	var end_id: int = path_graph.get_closest_point(
		to_position
	)

	if start_id == -1 or end_id == -1:
		return steps

	var path_ids: PackedInt64Array = path_graph.get_id_path(
		start_id,
		end_id
	)

	if path_ids.is_empty() and debug_logging:
		debug_disconnected_route(
			path_graph,
			start_id,
			end_id
		)
		
	# Check whether the route works in the opposite direction.
	if path_ids.is_empty() and debug_logging:
		var reverse_path: PackedInt64Array = (
			path_graph.get_id_path(end_id, start_id)
		)

		print("--- REVERSE PATH TEST ---")
		print("Forward path length: ", path_ids.size())
		print("Reverse path length: ", reverse_path.size())

		if not reverse_path.is_empty():
			print("Reverse route exists!")
			print("Reverse path IDs: ", reverse_path)
		else:
			print("Neither direction has a valid route.")

		print("--- END REVERSE PATH TEST ---")

	# Debug why A* cannot find a route.
	if path_ids.is_empty() and debug_logging:
		print("--- NAVIGATION PATH FAILED ---")
		print("Enemy position: ", from_position)
		print("Player position: ", to_position)

		print(
			"Start navigation point: ",
			path_graph.get_point_position(start_id)
		)

		print(
			"End navigation point: ",
			path_graph.get_point_position(end_id)
		)

		print(
			"Start connections: ",
			path_graph.get_point_connections(start_id)
		)

		print(
			"End connections: ",
			path_graph.get_point_connections(end_id)
		)

		print(
			"Total navigation points: ",
			path_graph.get_point_count()
		)

		print("--- END NAVIGATION DEBUG ---")
		# Diagnose the missing connection near the corridor.
		var point_a: Vector2 = Vector2(784.0, -48.0)
		var point_b: Vector2 = Vector2(880.0, -48.0)

		var id_a: int = path_graph.get_closest_point(point_a)
		var id_b: int = path_graph.get_closest_point(point_b)

		if id_a != -1 and id_b != -1:
			var forward := Vector2i(id_a, id_b)
			var backward := Vector2i(id_b, id_a)

			var gravity: float = float(
				ProjectSettings.get_setting(
					"physics/2d/default_gravity"
				)
			)

			print("--- MISSING JUMP DEBUG ---")

			print("Point A: ", path_graph.get_point_position(id_a))
			print("Point B: ", path_graph.get_point_position(id_b))

			print(
				"Jump candidate exists: ",
				candidate_jumps.has(forward)
				or candidate_jumps.has(backward)
			)

			print(
				"Jump arc valid: ",
				is_jump_arc_clear(
					point_a,
					point_b,
					gravity,
					move_speed,
					jump_height
				)
			)
			
			# Test whether a shorter jump clears the ceiling.
			print("--- SHORT JUMP TEST ---")

			for test_height in [60.0, 64.0, 68.0, 72.0]:
				var valid: bool = is_jump_arc_clear(
					point_a,
					point_b,
					gravity,
					150.0,
					test_height
				)

				print(
					"Jump height ",
					test_height,
					": ",
					valid
				)

			print("--- END SHORT JUMP TEST ---")

			print(
				"Graph connection exists: ",
				path_graph.are_points_connected(
					id_a,
					id_b,
					false
				)
			)

			print("--- END MISSING JUMP DEBUG ---")

	# Retrieve the approved heights for this capability graph.
	var chosen_heights: Dictionary = jump_heights_by_graph.get(
		path_graph.get_instance_id(),
		{}
	)
	
	for i in range(path_ids.size()):
		var current_id: int = path_ids[i]
		var movement: String = "start"

		if i > 0:
			var previous_id: int = path_ids[i - 1]

			var forward := Vector2i(
				previous_id,
				current_id
			)

			var backward := Vector2i(
				current_id,
				previous_id
			)

			# Determine which movement the enemy needs.
			if candidate_vertical_drops.has(forward):
				movement = "drop_through"

			elif candidate_drops.has(forward):
				movement = "drop"

			elif (
				candidate_jumps.has(forward)
				or candidate_jumps.has(backward)
			):
				movement = "jump"

			else:
				movement = "walk"

		# Create the navigation instruction.
		var navigation_step: Dictionary = {
			"position": path_graph.get_point_position(current_id),
			"movement": movement
		}

		# Include the selected trajectory for jump instructions.
		if movement == "jump" and i > 0:
			var jump_connection := Vector2i(
				path_ids[i - 1],
				current_id
			)

			navigation_step["jump_height"] = float(
				chosen_heights.get(
					jump_connection,
					jump_height if jump_height > 0.0 else debug_jump_height
				)
			)

			navigation_step["jump_speed"] = (
				jump_move_speed
				if jump_move_speed >= 0.0
				else move_speed
			)

		steps.append(navigation_step)

	return steps
## Diagnoses disconnected navigation regions.
func debug_disconnected_route(
	graph: AStar2D,
	start_id: int,
	end_id: int
) -> void:

	var visited: Dictionary = {}
	var queue: Array[int] = [start_id]
	var index: int = 0

	visited[start_id] = true

	# Explore all points reachable from the enemy.
	while index < queue.size():
		var current_id: int = queue[index]
		index += 1

		for neighbor_id in graph.get_point_connections(current_id):
			if not graph.are_points_connected(
				current_id, neighbor_id, false
			):
				continue

			if visited.has(neighbor_id):
				continue

			visited[neighbor_id] = true
			queue.append(neighbor_id)

	print("--- GRAPH CONNECTIVITY DEBUG ---")
	print("Reachable points: ", visited.size())
	print("Total points: ", graph.get_point_count())
	print("Destination reachable: ", visited.has(end_id))

	# Find the nearest pair of points separated
	# by the unreachable graph boundary.
	var closest_distance: float = INF
	var closest_from: Vector2 = Vector2.ZERO
	var closest_to: Vector2 = Vector2.ZERO

	for reachable_id in visited.keys():
		var from_position: Vector2 = graph.get_point_position(
			reachable_id
		)

		for other_id in graph.get_point_ids():
			if visited.has(other_id):
				continue

			var to_position: Vector2 = graph.get_point_position(
				other_id
			)

			var distance: float = from_position.distance_to(
				to_position
			)

			if distance < closest_distance:
				closest_distance = distance
				closest_from = from_position
				closest_to = to_position

	print("Closest disconnected points:")
	print("From: ", closest_from)
	print("To: ", closest_to)
	print("Distance: ", closest_distance)
	print("--- END GRAPH DEBUG ---")
