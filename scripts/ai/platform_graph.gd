
class_name PlatformGraph
extends Node2D

## Prototype navigation graph.
## Points are Marker2D children in scene-tree order.

@export var connections: Array[Vector2i] = [
	Vector2i(0, 1),
	Vector2i(1, 2),
	Vector2i(2, 3)
]

# Connections that require jumping instead of walking.
@export var jump_connections: Array[Vector2i] = [
	Vector2i(1, 2)
]


var astar: AStar2D = AStar2D.new()
var markers: Array[Marker2D] = []

func _ready() -> void:
	# Collect navigation points.
	for child in get_children():
		if child is Marker2D:
			markers.append(child)

	# Register each point in world coordinates.
	for i in range(markers.size()):
		astar.add_point(i, markers[i].global_position)

	# Connect neighboring points.
	for connection in connections:
		var from_id: int = connection.x
		var to_id: int = connection.y

		if astar.has_point(from_id) and astar.has_point(to_id):
			astar.connect_points(from_id, to_id)

	# Test whether the graph can calculate a route.
	if astar.has_point(0) and astar.has_point(3):
		print("Navigation route: ", astar.get_point_path(0, 3))

	# Debug the different movement types.
	var route_ids := get_route_ids(
		markers[0].global_position,
		markers[3].global_position
	)

	for i in range(route_ids.size() - 1):
		var from_id: int = route_ids[i]
		var to_id: int = route_ids[i + 1]

		if is_jump_connection(from_id, to_id):
			print("Jump: ", from_id, " -> ", to_id)
		else:
			print("Walk: ", from_id, " -> ", to_id)



func get_route(
	from_position: Vector2,
	to_position: Vector2
) -> PackedVector2Array:
	if astar.get_point_count() == 0:
		return PackedVector2Array()

	var start_id: int = astar.get_closest_point(from_position)
	var end_id: int = astar.get_closest_point(to_position)

	return astar.get_point_path(start_id, end_id)


## Returns navigation point IDs for a route.
func get_route_ids(
	from_position: Vector2,
	to_position: Vector2
) -> PackedInt64Array:
	if astar.get_point_count() == 0:
		return PackedInt64Array()

	var start_id: int = astar.get_closest_point(from_position)
	var end_id: int = astar.get_closest_point(to_position)

	return astar.get_id_path(start_id, end_id)


## Checks whether movement between two points requires jumping.
func is_jump_connection(from_id: int, to_id: int) -> bool:
	return (
		jump_connections.has(Vector2i(from_id, to_id))
		or jump_connections.has(Vector2i(to_id, from_id))
	)
