extends RefCounted
class_name StorePathGraphShelfAccess

## Shelf access functions for StorePathGraph
## Handles shelf access point finding and management

## Reference to constants (set by parent)
var _constants: StorePathGraphConstants

func _init(consts: StorePathGraphConstants = null) -> void:
	_constants = consts


## Gets shelf access candidates for a shelf position
func get_shelf_access_candidates(
	shelf_position: Vector2,
	vertical_only: bool = false,
	get_graph_node_names_func: Callable = Callable(),
	is_shelf_access_marker_func: Callable = Callable(),
	get_object_body_rect_func: Callable = Callable(),
	append_shelf_access_candidate_func: Callable = Callable()
) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []

	if vertical_only:
		_append_rect_vertical_shelf_access_candidates(candidates, shelf_position, get_object_body_rect_func)

	for node_name in get_graph_node_names_func.call():
		var marker = null
		if get_graph_node_names_func.get_object() != null:
			var markers = get_graph_node_names_func.get_object().get("_markers")
			if markers:
				marker = (markers as Node2D).get_node_or_null(String(node_name))

		if marker == null:
			continue

		if not is_shelf_access_marker_func.call(marker):
			continue

		append_shelf_access_candidate_func.call(candidates, marker.global_position, shelf_position, node_name, vertical_only)

	return candidates


## Appends vertical shelf access candidates (above and below shelf)
func _append_rect_vertical_shelf_access_candidates(
	candidates: Array[Dictionary],
	shelf_position: Vector2,
	get_object_body_rect_func: Callable = Callable()
) -> void:
	var shelf_object = null
	# Try to find shelf object at position
	var store = null
	if get_object_body_rect_func.get_object() != null:
		store = get_object_body_rect_func.get_object().get("_store")

	var shelf_rect := Rect2()

	if store != null:
		for node in store.get_tree().get_nodes_in_group("shelves"):
			var shelf := node as Node2D

			if shelf == null:
				continue

			if shelf.global_position.distance_to(shelf_position) <= _constants.MAX_VERTICAL_SHELF_ACCESS_DISTANCE:
				shelf_object = shelf
				shelf_rect = get_object_body_rect_func.call(shelf, shelf_position)
				break

	if not _rect_has_area(shelf_rect):
		shelf_rect = Rect2(shelf_position - Vector2(32, 24), Vector2(64, 48))

	var standing_half_height := _constants.STANDING_SHAPE_SIZE.y * 0.5
	var standing_offset_y := _constants.STANDING_SHAPE_OFFSET.y
	var standing_center_above_y := shelf_rect.position.y - _constants.SHELF_ACCESS_STANDING_CLEARANCE - standing_half_height - standing_offset_y
	var standing_center_below_y := shelf_rect.position.y + shelf_rect.size.y + _constants.SHELF_ACCESS_STANDING_CLEARANCE + standing_half_height - standing_offset_y
	var x_positions: Array[float] = [
		shelf_position.x
	]

	for x_position in x_positions:
		_append_rect_shelf_access_candidate(candidates, Vector2(x_position, standing_center_above_y), shelf_position, "above")
		_append_rect_shelf_access_candidate(candidates, Vector2(x_position, standing_center_below_y), shelf_position, "below")


## Appends a single rect-based shelf access candidate
func _append_rect_shelf_access_candidate(
	candidates: Array[Dictionary],
	access_point: Vector2,
	shelf_position: Vector2,
	access_side: String
) -> void:
	if not access_point.is_finite():
		return

	var horizontal_distance := absf(access_point.x - shelf_position.x)
	var vertical_distance := absf(access_point.y - shelf_position.y)
	var direct_distance := access_point.distance_to(shelf_position)

	if direct_distance <= _constants.MARKER_ALIGNMENT_EPSILON or direct_distance > _constants.MAX_SHELF_ACCESS_DISTANCE:
		return

	if horizontal_distance > _constants.SHELF_ACCESS_COLUMN_EPSILON:
		return

	if vertical_distance > _constants.MAX_VERTICAL_SHELF_ACCESS_DISTANCE:
		return

	for candidate in candidates:
		var candidate_point := candidate.get("access_point", Vector2.INF) as Vector2

		if candidate_point.distance_to(access_point) <= _constants.MARKER_ALIGNMENT_EPSILON:
			return

	candidates.append({
		"access_point": access_point,
		"graph_node": StringName(),
		"vertical_access": true,
		"access_side": access_side,
		"tier": 0,
		"horizontal_distance": horizontal_distance,
		"vertical_distance": vertical_distance,
		"direct_distance": direct_distance
	})


## Appends a shelf access candidate from a marker or point
func append_shelf_access_candidate(
	candidates: Array[Dictionary],
	access_point: Vector2,
	shelf_position: Vector2,
	graph_node: StringName,
	vertical_only: bool = false
) -> void:
	if not access_point.is_finite():
		return

	var horizontal_distance := absf(access_point.x - shelf_position.x)
	var vertical_distance := absf(access_point.y - shelf_position.y)
	var direct_distance := access_point.distance_to(shelf_position)
	var access_side := "below" if access_point.y >= shelf_position.y else "above"

	if direct_distance <= _constants.MARKER_ALIGNMENT_EPSILON or direct_distance > _constants.MAX_SHELF_ACCESS_DISTANCE:
		return

	var vertical_access := horizontal_distance <= _constants.SHELF_ACCESS_COLUMN_EPSILON and vertical_distance > _constants.MARKER_ALIGNMENT_EPSILON

	if vertical_only and not vertical_access:
		return

	if vertical_access and vertical_distance > _constants.MAX_VERTICAL_SHELF_ACCESS_DISTANCE:
		return

	var tier := 2

	if vertical_access:
		tier = 0
	elif horizontal_distance <= _constants.SHELF_ACCESS_NEAR_COLUMN_EPSILON and vertical_distance > _constants.MARKER_ALIGNMENT_EPSILON:
		tier = 1

	candidates.append({
		"access_point": access_point,
		"graph_node": graph_node,
		"vertical_access": vertical_access,
		"access_side": access_side,
		"tier": tier,
		"horizontal_distance": horizontal_distance,
		"vertical_distance": vertical_distance,
		"direct_distance": direct_distance
	})


## Sorts shelf access candidates by tier and distance
func sort_shelf_access_candidates(candidates: Array[Dictionary]) -> void:
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var tier_a := int(a.get("tier", 2))
		var tier_b := int(b.get("tier", 2))

		if tier_a != tier_b:
			return tier_a < tier_b

		var point_a := a.get("access_point", Vector2.INF) as Vector2
		var point_b := b.get("access_point", Vector2.INF) as Vector2

		var horizontal_a := float(a.get("horizontal_distance", INF))
		var horizontal_b := float(b.get("horizontal_distance", INF))

		if not is_equal_approx(horizontal_a, horizontal_b):
			return horizontal_a < horizontal_b

		var vertical_a := float(a.get("vertical_distance", INF))
		var vertical_b := float(b.get("vertical_distance", INF))

		if not is_equal_approx(vertical_a, vertical_b):
			return vertical_a < vertical_b

		return float(a.get("direct_distance", INF)) < float(b.get("direct_distance", INF))
	)


func _rect_has_area(rect: Rect2) -> bool:
	return rect.size.x > 0.0 and rect.size.y > 0.0
