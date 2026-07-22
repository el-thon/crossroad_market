extends RefCounted
class_name StorePathGraphClearance

## Clearance checking functions for StorePathGraph.
## Handles collision detection along routes and physics queries.

@warning_ignore("unused_private_class_variable")
var _graph  # StorePathGraph – untyped to avoid cyclic class_name reference

const ROUTE_CLEARANCE_SCORE_SAMPLE_STEP: float = 12.0
const ROUTE_CLEARANCE_TEST_MARGINS: Array[float] = [14.0, 10.0, 6.0, 2.0]


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func _init(graph = null) -> void:
	_graph = graph


# ---------------------------------------------------------------------------
#  Route-level clearance
# ---------------------------------------------------------------------------

@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_route_clear(
	start: Vector2,
	route: Array[Vector2],
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF,
	npc_node: Node = null
) -> bool:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var current := start

	for point in route:
		if not is_route_segment_clear(
			current,
			point,
			shelf_object,
			shelf_position,
			npc_node
		):
			return false

		current = point

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_checkout_route_from_access_clear(
	start: Vector2,
	route: Array[Vector2],
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF
) -> bool:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var current := start

	for index in range(route.size()):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := route[index]

		if index == 0:
			if not is_route_segment_clear_except_start(current, point, shelf_object, shelf_position):
				return false
		elif not is_route_segment_clear(current, point, shelf_object, shelf_position):
			return false

		current = point

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_queue_route_clear(start: Vector2, route: Array[Vector2]) -> bool:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var current := start

	for index in range(route.size()):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := route[index]
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var allow_blocked_endpoint := index == route.size() - 1

		if allow_blocked_endpoint:
			if not is_route_segment_clear_except_endpoint(current, point):
				return false
		elif not is_route_segment_clear(current, point):
			return false

		current = point

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_queue_route_clear_from_current_position(start: Vector2, route: Array[Vector2]) -> bool:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var current := start

	for index in range(route.size()):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := route[index]
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var allow_blocked_endpoint := index == route.size() - 1

		var segment_clear := false
		if index == 0:
			if allow_blocked_endpoint:
				segment_clear = is_route_segment_clear_except_start_and_endpoint(current, point)
			else:
				segment_clear = is_route_segment_clear_except_start(current, point)
		elif allow_blocked_endpoint:
			segment_clear = is_route_segment_clear_except_endpoint(current, point)
		else:
			segment_clear = is_route_segment_clear(current, point)

		if not segment_clear:
			return false

		current = point

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_route_clear_from_current_position(start: Vector2, route: Array[Vector2]) -> bool:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var current := start

	for index in range(route.size()):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := route[index]

		if index == 0:
			if not is_route_segment_clear_except_start(current, point):
				return false
		elif not is_route_segment_clear(current, point):
			return false

		current = point

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_route_to_access_clear(start: Vector2, route: Array[Vector2], shelf: Shelf, npc_node: Node = null) -> bool:
	if route.is_empty():
		return true

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var current := start
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var shelf_position: Vector2 = shelf.global_position if shelf != null else Vector2.INF

	for index in range(route.size()):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := route[index]
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var is_last_segment := index == route.size() - 1

		if index == 0 and is_last_segment:
			if not is_route_segment_clear_except_start_and_endpoint(current, point, shelf, shelf_position, npc_node):
				return false
		elif index == 0:
			if not is_route_segment_clear_except_start(current, point, shelf, shelf_position, npc_node):
				return false
		elif is_last_segment:
			if not is_route_segment_clear_except_endpoint(current, point, shelf, shelf_position, npc_node):
				return false
		elif not is_route_segment_clear(current, point, shelf, shelf_position, npc_node):
			return false

		current = point

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_route_to_access_reject_context(
	start: Vector2,
	route: Array[Vector2],
	shelf: Shelf,
	npc_node: Node = null
) -> Dictionary:
	if route.is_empty():
		return {}

	var current := start
	var shelf_position: Vector2 = shelf.global_position if shelf != null else Vector2.INF
	for index in range(route.size()):
		var point := route[index]
		var is_last_segment := index == route.size() - 1
		var ignore_start := index == 0
		var ignore_endpoint := is_last_segment
		var segment_context := _get_access_segment_reject_context(
			current,
			point,
			shelf,
			shelf_position,
			npc_node,
			ignore_start,
			ignore_endpoint
		)
		if not segment_context.is_empty():
			segment_context["failed_segment_index"] = index
			segment_context["failed_from"] = _format_vector(current)
			segment_context["failed_to"] = _format_vector(point)
			segment_context["ignore_start"] = ignore_start
			segment_context["ignore_endpoint"] = ignore_endpoint
			return segment_context

		current = point

	return {}


# ---------------------------------------------------------------------------
#  Segment-level clearance (bool variants)
# ---------------------------------------------------------------------------

@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_route_segment_clear(
	from_pos: Vector2,
	to_pos: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF,
	npc_node: Node = null
) -> bool:
	if from_pos.distance_to(to_pos) <= _graph.ROUTE_CLEARANCE_EPSILON:
		return true

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var distance := from_pos.distance_to(to_pos)
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var steps: int = maxi(1, int(ceil(distance / _graph.ROUTE_SAMPLE_STEP)))

	for index in range(steps + 1):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := from_pos.lerp(to_pos, float(index) / float(steps))

		if not is_npc_access_point_clear(point, shelf_object, shelf_position, npc_node):
			return false

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_route_segment_clear_except_endpoint(
	from_pos: Vector2,
	to_pos: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF,
	npc_node: Node = null
) -> bool:
	if from_pos.distance_to(to_pos) <= _graph.ROUTE_CLEARANCE_EPSILON:
		return true

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var distance := from_pos.distance_to(to_pos)
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var steps: int = maxi(1, int(ceil(distance / _graph.ROUTE_SAMPLE_STEP)))

	for index in range(steps):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := from_pos.lerp(to_pos, float(index) / float(steps))

		if not is_npc_access_point_clear(point, shelf_object, shelf_position, npc_node):
			return false

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_route_segment_clear_except_start(
	from_pos: Vector2,
	to_pos: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF,
	npc_node: Node = null
) -> bool:
	if from_pos.distance_to(to_pos) <= _graph.ROUTE_CLEARANCE_EPSILON:
		return true

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var distance := from_pos.distance_to(to_pos)
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var steps: int = maxi(1, int(ceil(distance / _graph.ROUTE_SAMPLE_STEP)))

	for index in range(1, steps + 1):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := from_pos.lerp(to_pos, float(index) / float(steps))

		if not is_npc_access_point_clear(point, shelf_object, shelf_position, npc_node):
			return false

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_route_segment_clear_except_start_and_endpoint(
	from_pos: Vector2,
	to_pos: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF,
	npc_node: Node = null
) -> bool:
	if from_pos.distance_to(to_pos) <= _graph.ROUTE_CLEARANCE_EPSILON:
		return true

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var distance := from_pos.distance_to(to_pos)
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var steps: int = maxi(1, int(ceil(distance / _graph.ROUTE_SAMPLE_STEP)))

	for index in range(1, steps):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := from_pos.lerp(to_pos, float(index) / float(steps))

		if not is_npc_access_point_clear(point, shelf_object, shelf_position, npc_node):
			return false

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_any_direction_segment_clear(
	from_pos: Vector2,
	to_pos: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF,
	npc_node: Node = null,
	ignore_start: bool = false,
	ignore_endpoint: bool = false
) -> bool:
	if not from_pos.is_finite() or not to_pos.is_finite():
		return false

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var distance := from_pos.distance_to(to_pos)

	if distance <= _graph.ROUTE_CLEARANCE_EPSILON:
		return true

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var steps := maxi(
		1,
		int(ceil(distance / _graph.ROUTE_SAMPLE_STEP))
	)

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var first_index := 1 if ignore_start else 0
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var last_index := steps - 1 if ignore_endpoint else steps

	if first_index > last_index:
		return true

	for index in range(first_index, last_index + 1):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var progress := float(index) / float(steps)
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var point := from_pos.lerp(to_pos, progress)

		if not is_npc_access_point_clear(
			point,
			shelf_object,
			shelf_position,
			npc_node
		):
			return false

	return true


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func _get_access_segment_reject_context(
	from_pos: Vector2,
	to_pos: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF,
	npc_node: Node = null,
	ignore_start: bool = false,
	ignore_endpoint: bool = false
) -> Dictionary:
	if not from_pos.is_finite() or not to_pos.is_finite():
		return {"reason": "invalid_segment"}

	var distance := from_pos.distance_to(to_pos)
	if distance <= _graph.ROUTE_CLEARANCE_EPSILON:
		return {}

	var steps := maxi(
		1,
		int(ceil(distance / _graph.ROUTE_SAMPLE_STEP))
	)
	var first_index := 1 if ignore_start else 0
	var last_index := steps - 1 if ignore_endpoint else steps
	if first_index > last_index:
		return {}

	for index in range(first_index, last_index + 1):
		var progress := float(index) / float(steps)
		var point := from_pos.lerp(to_pos, progress)
		var point_context := _get_access_point_reject_context(
			point,
			shelf_object,
			shelf_position,
			npc_node
		)
		if point_context.is_empty():
			continue
		point_context["sample_point"] = _format_vector(point)
		point_context["sample_index"] = index
		point_context["sample_steps"] = steps
		return point_context

	return {}


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func _get_access_point_reject_context(
	position: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF,
	npc_node: Node = null
) -> Dictionary:
	if shelf_object != null and shelf_position.is_finite():
		var shelf_rect := get_object_body_rect_at(shelf_object, shelf_position)
		if (
			_rect_has_area(shelf_rect)
			and get_npc_standing_rect(position).intersects(shelf_rect)
		):
			return {
				"reason": "target_shelf_body",
				"collider_name": shelf_object.name,
				"collider_path": str(shelf_object.get_path()),
				"collider_owner": shelf_object.get_parent().name if shelf_object.get_parent() != null else "",
				"standing_rect": str(get_npc_standing_rect(position)),
				"shelf_rect": str(shelf_rect)
			}

	var collider := _get_first_blocking_collider(position, npc_node)
	if collider == null:
		return {}

	return {
		"reason": "physics_blocked",
		"collider_name": collider.name,
		"collider_path": str(collider.get_path()),
		"collider_owner": collider.get_parent().name if collider.get_parent() != null else ""
	}


# ---------------------------------------------------------------------------
#  Point-level clearance
# ---------------------------------------------------------------------------

@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_npc_access_point_clear(
	position: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF,
	npc_node: Node = null
) -> bool:
	if shelf_object != null and shelf_position.is_finite():
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var shelf_rect := get_object_body_rect_at(shelf_object, shelf_position)

		if _rect_has_area(shelf_rect) and get_npc_standing_rect(position).intersects(shelf_rect):
			return false

	return is_npc_standing_position_clear(position, npc_node)


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_npc_standing_position_clear(position: Vector2, npc: Node = null) -> bool:
	return is_npc_standing_position_clear_with_margin(position, 0.0, npc)


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func is_npc_standing_position_clear_with_margin(
	position: Vector2,
	margin: float,
	npc: Node = null
) -> bool:
	if _graph._store == null:
		return false

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var shape := RectangleShape2D.new()
	var extra_size := Vector2(maxf(0.0, margin), maxf(0.0, margin)) * 2.0
	shape.size = _graph.STANDING_SHAPE_SIZE + extra_size

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, position + _graph.STANDING_SHAPE_OFFSET)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 1

	if npc is CollisionObject2D:
		query.exclude = [(npc as CollisionObject2D).get_rid()]

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var hits: Array[Dictionary] = _graph._store.get_world_2d().direct_space_state.intersect_shape(query, 16)
	return hits.is_empty()


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func _get_first_blocking_collider(position: Vector2, npc: Node = null) -> Node:
	if _graph._store == null:
		return null

	var shape := RectangleShape2D.new()
	shape.size = _graph.STANDING_SHAPE_SIZE

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, position + _graph.STANDING_SHAPE_OFFSET)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 1

	if npc is CollisionObject2D:
		query.exclude = [(npc as CollisionObject2D).get_rid()]

	var hits: Array[Dictionary] = _graph._store.get_world_2d().direct_space_state.intersect_shape(query, 16)
	if hits.is_empty():
		return null

	var collider_variant: Variant = hits.front().get("collider", null)
	if collider_variant is Node:
		return collider_variant as Node
	return null


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_route_clearance_score(
	start: Vector2,
	route: Array[Vector2],
	npc_node: Node = null
) -> float:
	if route.is_empty():
		return 0.0

	var tested_points := 0
	var total_margin := 0.0
	var worst_margin := INF
	var current := start
	for target in route:
		if not target.is_finite():
			return 0.0

		var distance := current.distance_to(target)
		var steps: int = maxi(
			1,
			int(ceil(distance / ROUTE_CLEARANCE_SCORE_SAMPLE_STEP))
		)
		for index in range(1, steps + 1):
			var point := current.lerp(target, float(index) / float(steps))
			var point_margin := _get_clearance_margin_at(point, npc_node)
			total_margin += point_margin
			worst_margin = minf(worst_margin, point_margin)
			tested_points += 1
		current = target

	if tested_points <= 0:
		return 0.0

	var average_margin := total_margin / float(tested_points)
	return average_margin + worst_margin * 2.0


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func _get_clearance_margin_at(position: Vector2, npc_node: Node = null) -> float:
	for margin in ROUTE_CLEARANCE_TEST_MARGINS:
		if is_npc_standing_position_clear_with_margin(
			position,
			margin,
			npc_node
		):
			return margin
	return 0.0


func _format_vector(value: Vector2) -> String:
	if not value.is_finite():
		return "inf,inf"
	return "%.1f,%.1f" % [value.x, value.y]


# ---------------------------------------------------------------------------
#  Geometry helpers
# ---------------------------------------------------------------------------

@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_npc_standing_rect(position: Vector2) -> Rect2:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var center: Vector2 = position + _graph.STANDING_SHAPE_OFFSET
	return Rect2(center - _graph.STANDING_SHAPE_SIZE * 0.5, _graph.STANDING_SHAPE_SIZE)


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_object_body_rect_at(object: Node2D, candidate: Vector2) -> Rect2:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var collision_shape := _get_object_collision_shape(object)

	if collision_shape == null:
		return Rect2(candidate - Vector2(32, 24), Vector2(64, 48))

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var rectangle := collision_shape.shape as RectangleShape2D

	if rectangle == null:
		return Rect2(candidate - Vector2(32, 24), Vector2(64, 48))

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var center := candidate + collision_shape.position
	return Rect2(center - rectangle.size * 0.5, rectangle.size)


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func _get_object_collision_shape(object: Node2D) -> CollisionShape2D:
	if object == null:
		return null

	return object.get_node_or_null("PhysicsBody/CollisionShape2D") as CollisionShape2D


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func _rect_has_area(rect: Rect2) -> bool:
	return rect.size.x > 0.0 and rect.size.y > 0.0
