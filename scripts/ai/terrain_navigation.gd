
class_name TerrainNavigation
extends Node2D

## Automatically detects potential standing positions
## using the room's existing terrain layers.

@export var enemy_half_height: float = 16.0
@export var debug_point_radius: float = 8.0

@onready var room: EditableRoom = get_parent() as EditableRoom

# World positions where an enemy could potentially stand.
var walkable_positions: Array[Vector2] = []
var _rebuild_queued: bool = false

# Stores our automatically generated navigation graph.
var astar: AStar2D = AStar2D.new()

# Maps terrain cells to their navigation point IDs.
var point_ids_by_cell: Dictionary = {}

# Temporary visualization of a calculated route.
var debug_path: PackedVector2Array = PackedVector2Array()



func _ready() -> void:
	# Listen for edits made through EditableRoom.
	room.terrain_changed.connect(_request_rebuild)

	# Generate navigation for any existing terrain.
	_request_rebuild()


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
