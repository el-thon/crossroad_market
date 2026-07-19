extends RefCounted
class_name StorePathGraphRoutes

## Route building functions for StorePathGraph
## Contains orthogonal and direct route builders

## Reference to constants (set by parent)
var _constants: StorePathGraphConstants

func _init(consts: StorePathGraphConstants = null) -> void:
	_constants = consts


## Creates an orthogonal (L-shaped) route between two points
## horizontal_first: if true, goes horizontal then vertical; otherwise vertical then horizontal
func make_orthogonal_route(from_pos: Vector2, to_pos: Vector2, horizontal_first: bool = true) -> Array[Vector2]:
	var route: Array[Vector2] = []

	if from_pos.distance_to(to_pos) <= 2.0:
		return route

	var corner := Vector2(to_pos.x, from_pos.y) if horizontal_first else Vector2(from_pos.x, to_pos.y)

	if from_pos.distance_to(corner) > 2.0:
		route.append(corner)

	if corner.distance_to(to_pos) > 2.0:
		route.append(to_pos)

	return route


## Creates a direct (diagonal) route between two points
## Returns a single waypoint: from_pos -> to_pos
func make_direct_route(from_pos: Vector2, to_pos: Vector2) -> Array[Vector2]:
	if not from_pos.is_finite() or not to_pos.is_finite():
		return []

	if from_pos.distance_to(to_pos) <= _constants.ROUTE_CLEARANCE_EPSILON:
		return []

	return [to_pos]


## Removes duplicate points that are too close together
func dedupe_route_points(route: Array[Vector2]) -> Array[Vector2]:
	var deduped: Array[Vector2] = []

	for point in route:
		if not point.is_finite():
			continue

		if not deduped.is_empty() and deduped[deduped.size() - 1].distance_to(point) <= 2.0:
			continue

		deduped.append(point)

	return deduped


## Appends an orthogonal route to an existing route array
func append_orthogonal_route_to(
	route: Array[Vector2],
	to_pos: Vector2,
	horizontal_first: bool = true,
	fallback_from_pos: Vector2 = Vector2.INF
) -> void:
	var from_pos := fallback_from_pos

	if not route.is_empty():
		from_pos = route[route.size() - 1]

	if not from_pos.is_finite():
		route.append(to_pos)
		return

	route.append_array(make_orthogonal_route(from_pos, to_pos, horizontal_first))


## Appends an orthogonal route to an existing route array, checking if clear first
func append_clear_orthogonal_route_to(
	route: Array[Vector2],
	to_pos: Vector2,
	horizontal_first: bool = true,
	fallback_from_pos: Vector2 = Vector2.INF,
	is_clear_func: Callable = Callable()
) -> bool:
	var from_pos := fallback_from_pos

	if not route.is_empty():
		from_pos = route[route.size() - 1]

	if not from_pos.is_finite():
		route.append(to_pos)
		return true

	var addition := make_orthogonal_route(from_pos, to_pos, horizontal_first)

	if not is_clear_func.call(from_pos, addition):
		return false

	route.append_array(addition)
	return true


## Appends a direct route to queue target
func append_clear_queue_target_route_to(
	route: Array[Vector2],
	to_pos: Vector2,
	horizontal_first: bool = true,
	fallback_from_pos: Vector2 = Vector2.INF,
	is_queue_clear_func: Callable = Callable()
) -> bool:
	var from_pos := fallback_from_pos

	if not route.is_empty():
		from_pos = route[route.size() - 1]

	if not from_pos.is_finite():
		route.append(to_pos)
		return true

	var addition: Array[Vector2] = [to_pos]

	if not is_queue_clear_func.call(from_pos, addition):
		return false

	route.append_array(addition)
	return true


## Prepends an orthogonal route to the beginning of a route
func prepend_orthogonal_route(from_pos: Vector2, route: Array[Vector2], horizontal_first: bool = true) -> Array[Vector2]:
	if route.is_empty():
		return []

	var result := make_orthogonal_route(from_pos, route[0], horizontal_first)
	result.append_array(route)
	return dedupe_route_points(result)


## Calculates total distance of a route
func get_route_distance(start: Vector2, route: Array[Vector2]) -> float:
	var distance := 0.0
	var cursor := start

	for point in route:
		distance += cursor.distance_to(point)
		cursor = point

	return distance
