extends RefCounted
class_name StorePathGraphClearance

## Clearance checking functions for StorePathGraph.
## Handles collision detection along routes and physics queries.

@warning_ignore("unused_private_class_variable")
var _graph  # StorePathGraph – untyped to avoid cyclic class_name reference


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
	if _graph._store == null:
		return false

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var shape := RectangleShape2D.new()
	shape.size = _graph.STANDING_SHAPE_SIZE

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
