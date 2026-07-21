class_name StoreShelfRoutePolicy
extends RefCounted

## Selects shelf-bound routes using the path that axis-locked NPC movement will
## visibly execute, rather than the Euclidean line originally scored by an
## any-angle planner.

const CASHIER_MARKER_NAME: StringName = &"StorePathCashier"
const QUEUE_FRONT_MARKER_NAME: StringName = &"StorePathQueueFront"
const QUEUE_BACK_MARKER_NAMES: Array[StringName] = [
	&"StorePathQueueBack1",
	&"StorePathQueueBack2"
]
const QUEUE_FRONT_RIGHT_MARKER_NAME: StringName = &"StorePathQueueFrontRight"

const FRONTAGE_TOP_PADDING: float = 8.0
const FRONTAGE_BOTTOM_PADDING: float = 10.0
const FRONTAGE_DEFAULT_HALF_WIDTH: float = 18.0
const FRONTAGE_MIN_HALF_WIDTH: float = 14.0
const FRONTAGE_MAX_HALF_WIDTH: float = 22.0
const FRONTAGE_LANE_WIDTH_SCALE: float = 0.35
const FRONTAGE_COST_PER_PIXEL: float = 8.0
const FRONTAGE_OVERLAP_EPSILON: float = 0.5
const ROUTE_EPSILON: float = 0.01

var _marker_root: Node2D = null


func setup(marker_root: Node2D) -> void:
	_marker_root = marker_root


func route_crosses_checkout_frontage(
	start_position: Vector2,
	route: Array[Vector2]
) -> bool:
	if route.is_empty() or not start_position.is_finite():
		return false
	var frontage := _get_checkout_frontage()
	if not frontage.has_area():
		return false
	return (
		_get_frontage_overlap(start_position, route, frontage)
		> FRONTAGE_OVERLAP_EPSILON
	)


func choose_preferred_route(
	start_position: Vector2,
	primary_route: Array[Vector2],
	alternative_route: Array[Vector2]
) -> Array[Vector2]:
	if primary_route.is_empty():
		return alternative_route.duplicate()
	if alternative_route.is_empty():
		return primary_route.duplicate()

	var frontage := _get_checkout_frontage()
	if not frontage.has_area():
		return _choose_shorter_route(
			start_position,
			primary_route,
			alternative_route
		)

	var primary_score := _get_route_score(
		start_position,
		primary_route,
		frontage
	)
	var alternative_score := _get_route_score(
		start_position,
		alternative_route,
		frontage
	)
	if alternative_score + ROUTE_EPSILON < primary_score:
		return alternative_route.duplicate()
	return primary_route.duplicate()


func _choose_shorter_route(
	start_position: Vector2,
	primary_route: Array[Vector2],
	alternative_route: Array[Vector2]
) -> Array[Vector2]:
	var primary_distance := _get_orthogonal_distance(
		start_position,
		primary_route
	)
	var alternative_distance := _get_orthogonal_distance(
		start_position,
		alternative_route
	)
	if alternative_distance + ROUTE_EPSILON < primary_distance:
		return alternative_route.duplicate()
	return primary_route.duplicate()


func _get_route_score(
	start_position: Vector2,
	route: Array[Vector2],
	frontage: Rect2
) -> float:
	return (
		_get_orthogonal_distance(start_position, route)
		+ _get_frontage_overlap(start_position, route, frontage)
		* FRONTAGE_COST_PER_PIXEL
	)


func _get_orthogonal_distance(
	start_position: Vector2,
	route: Array[Vector2]
) -> float:
	var total_distance: float = 0.0
	var current_position := start_position
	for target_position in route:
		if not target_position.is_finite():
			return INF
		var delta := target_position - current_position
		total_distance += absf(delta.x) + absf(delta.y)
		current_position = target_position
	return total_distance


func _get_frontage_overlap(
	start_position: Vector2,
	route: Array[Vector2],
	frontage: Rect2
) -> float:
	var overlap: float = 0.0
	var current_position := start_position
	for target_position in route:
		if not target_position.is_finite():
			return INF

		var corner := _get_axis_locked_corner(
			current_position,
			target_position
		)
		if (
			corner.distance_to(current_position) > ROUTE_EPSILON
			and corner.distance_to(target_position) > ROUTE_EPSILON
		):
			overlap += _get_segment_overlap(
				current_position,
				corner,
				frontage
			)
			current_position = corner

		overlap += _get_segment_overlap(
			current_position,
			target_position,
			frontage
		)
		current_position = target_position
	return overlap


func _get_axis_locked_corner(
	start_position: Vector2,
	target_position: Vector2
) -> Vector2:
	var delta := target_position - start_position
	if absf(delta.x) <= ROUTE_EPSILON or absf(delta.y) <= ROUTE_EPSILON:
		return start_position
	if absf(delta.x) >= absf(delta.y):
		return Vector2(target_position.x, start_position.y)
	return Vector2(start_position.x, target_position.y)


func _get_segment_overlap(
	segment_start: Vector2,
	segment_end: Vector2,
	frontage: Rect2
) -> float:
	var frontage_end := frontage.end
	if absf(segment_start.x - segment_end.x) <= ROUTE_EPSILON:
		var segment_x := segment_start.x
		if (
			segment_x < frontage.position.x - ROUTE_EPSILON
			or segment_x > frontage_end.x + ROUTE_EPSILON
		):
			return 0.0
		var segment_top := minf(segment_start.y, segment_end.y)
		var segment_bottom := maxf(segment_start.y, segment_end.y)
		return maxf(
			0.0,
			minf(segment_bottom, frontage_end.y)
			- maxf(segment_top, frontage.position.y)
		)

	if absf(segment_start.y - segment_end.y) <= ROUTE_EPSILON:
		var segment_y := segment_start.y
		if (
			segment_y < frontage.position.y - ROUTE_EPSILON
			or segment_y > frontage_end.y + ROUTE_EPSILON
		):
			return 0.0
		var segment_left := minf(segment_start.x, segment_end.x)
		var segment_right := maxf(segment_start.x, segment_end.x)
		return maxf(
			0.0,
			minf(segment_right, frontage_end.x)
			- maxf(segment_left, frontage.position.x)
		)

	return 0.0


func _get_checkout_frontage() -> Rect2:
	var cashier_marker := _get_marker(CASHIER_MARKER_NAME)
	var queue_front_marker := _get_marker(QUEUE_FRONT_MARKER_NAME)
	if cashier_marker == null or queue_front_marker == null:
		return Rect2()

	var frontage_top := minf(
		cashier_marker.global_position.y,
		queue_front_marker.global_position.y
	) - FRONTAGE_TOP_PADDING
	var frontage_bottom := maxf(
		cashier_marker.global_position.y,
		queue_front_marker.global_position.y
	)
	for marker_name in QUEUE_BACK_MARKER_NAMES:
		var queue_marker := _get_marker(marker_name)
		if queue_marker != null:
			frontage_bottom = maxf(
				frontage_bottom,
				queue_marker.global_position.y
			)
	frontage_bottom += FRONTAGE_BOTTOM_PADDING

	var center_x := queue_front_marker.global_position.x
	var half_width := FRONTAGE_DEFAULT_HALF_WIDTH
	var right_marker := _get_marker(QUEUE_FRONT_RIGHT_MARKER_NAME)
	if right_marker != null:
		var lane_width := absf(right_marker.global_position.x - center_x)
		half_width = clampf(
			lane_width * FRONTAGE_LANE_WIDTH_SCALE,
			FRONTAGE_MIN_HALF_WIDTH,
			FRONTAGE_MAX_HALF_WIDTH
		)

	return Rect2(
		Vector2(center_x - half_width, frontage_top),
		Vector2(half_width * 2.0, frontage_bottom - frontage_top)
	)


func _get_marker(marker_name: StringName) -> Marker2D:
	if _marker_root == null or not is_instance_valid(_marker_root):
		return null
	return _marker_root.get_node_or_null(String(marker_name)) as Marker2D
