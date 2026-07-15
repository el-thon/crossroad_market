class_name StoreNPCPathGraph
extends RefCounted

const ENTRY: StringName = &"NPCPathEntry"
const EXIT: StringName = &"NPCPathExit"
const AISLE_RIGHT: StringName = &"NPCPathAisleRight"
const AISLE_MID: StringName = &"NPCPathAisleMid"
const AISLE_LEFT: StringName = &"NPCPathAisleLeft"
const CASHIER: StringName = &"NPCPathCashier"
const QUEUE_FRONT: StringName = &"NPCQueueFront"
const QUEUE_BACK_1: StringName = &"NPCQueueBack1"
const QUEUE_BACK_2: StringName = &"NPCQueueBack2"
const ACCESS_META: StringName = &"npc_access_point"
const ACCESS_NODE_META: StringName = &"npc_access_graph_node"
const ACCESS_OFFSETS: Array[Vector2] = [
	Vector2(0, 64),
	Vector2(-72, 0),
	Vector2(72, 0),
	Vector2(0, -64)
]
const STANDING_SHAPE_SIZE := Vector2(28, 12)
const STANDING_SHAPE_OFFSET := Vector2(0, -8)
const ROUTE_SAMPLE_STEP: float = 8.0
const ROUTE_CLEARANCE_EPSILON: float = 2.0

var _store: Node2D = null
var _markers: Node2D = null


func _init(store: Node2D = null, markers: Node2D = null) -> void:
	_store = store
	_markers = markers


func setup(store: Node2D, markers: Node2D) -> void:
	_store = store
	_markers = markers


func get_entry_route_to_shelf(shelf_position: Vector2, from_position: Vector2 = Vector2.INF) -> Array[Vector2]:
	var start: Dictionary = _find_nearest_graph_node(from_position) if from_position.is_finite() else {
		"valid": true,
		"node": ENTRY,
		"route": _build_route_from_graph_path([ENTRY])
	}

	if not bool(start.get("valid", false)):
		return _dedupe_route_points(_make_orthogonal_route(from_position, shelf_position, true))

	var path := _find_graph_path(start.get("node", ENTRY) as StringName, AISLE_RIGHT)
	var route := start.get("route", []) as Array[Vector2]
	route.append_array(_build_route_from_graph_path(path))
	_append_orthogonal_route_to(route, shelf_position, true, from_position)
	return _dedupe_route_points(route)


func get_shelf_access_position(shelf: Shelf) -> Vector2:
	if shelf == null:
		return Vector2.INF

	if shelf.has_meta(ACCESS_META):
		var access_point: Variant = shelf.get_meta(ACCESS_META)

		if access_point is Vector2:
			return access_point as Vector2

	var result := find_best_shelf_access(shelf.global_position, shelf)
	return result.get("access_point", Vector2.INF) as Vector2


func get_route_to_shelf_access(shelf: Shelf) -> Array[Vector2]:
	if shelf == null:
		return []

	var access_point := get_shelf_access_position(shelf)
	var graph_node := get_shelf_access_graph_node(shelf)

	if not access_point.is_finite() or graph_node == StringName():
		return []

	var path := _find_graph_path(ENTRY, graph_node)
	var route := _build_route_from_graph_path(path)
	_append_orthogonal_route_to(route, access_point, true)
	return _dedupe_route_points(route)


func get_route_to_cashier_from(from_position: Vector2) -> Array[Vector2]:
	var start := _find_nearest_graph_node(from_position)

	if not bool(start.get("valid", false)):
		return []

	var path := _find_graph_path(start.get("node", CASHIER) as StringName, QUEUE_FRONT)
	var route := start.get("route", []) as Array[Vector2]
	route.append_array(_build_route_from_graph_path(path))
	return _dedupe_route_points(route)


func get_route_from_shelf_to_cashier(shelf: Shelf) -> Array[Vector2]:
	if shelf == null:
		return []

	var access_point := get_shelf_access_position(shelf)
	var graph_node := get_shelf_access_graph_node(shelf)

	if not access_point.is_finite() or graph_node == StringName():
		return []

	var path := _find_graph_path(graph_node, QUEUE_FRONT)
	var route := _build_route_from_graph_path(path)
	route = _prepend_orthogonal_route(access_point, route, true)
	return _dedupe_route_points(route)


func get_exit_route_from(from_position: Vector2, fallback_exit_position: Vector2) -> Array[Vector2]:
	var start := _find_nearest_graph_node(from_position)

	if not bool(start.get("valid", false)):
		return _dedupe_route_points(_make_orthogonal_route(from_position, fallback_exit_position, true))

	var path := _find_graph_path(start.get("node", ENTRY) as StringName, EXIT)
	var route := start.get("route", []) as Array[Vector2]
	route.append_array(_build_route_from_graph_path(path))
	return _dedupe_route_points(route)


func has_reachable_shelf_access(object: Node2D, candidate: Vector2) -> bool:
	return bool(find_best_shelf_access(candidate, object).get("valid", false))


func find_best_shelf_access(candidate_position: Vector2, shelf_object: Node2D) -> Dictionary:
	var best_result := {"valid": false}
	var best_score := INF

	for offset in ACCESS_OFFSETS:
		var access_point := candidate_position + offset

		if not _is_npc_access_point_clear(access_point, shelf_object, candidate_position):
			continue

		var nearest := _find_nearest_reachable_graph_node(access_point, shelf_object, candidate_position)

		if not bool(nearest.get("valid", false)):
			continue

		var graph_node := nearest.get("node", StringName()) as StringName
		var graph_path := _find_graph_path(graph_node, QUEUE_FRONT)

		if graph_path.is_empty():
			continue

		var access_route := nearest.get("route", []) as Array[Vector2]
		var full_route := access_route.duplicate()
		full_route.append_array(_build_route_from_graph_path(graph_path))

		if not _is_route_clear(access_point, full_route, shelf_object, candidate_position):
			continue

		var score := float(nearest.get("distance", 0.0)) + _get_graph_path_cost(graph_path)

		if score < best_score:
			best_score = score
			best_result = {
				"valid": true,
				"access_point": access_point,
				"graph_node": graph_node,
				"score": score
			}

	return best_result


func store_shelf_access_metadata(object: Node2D, drop_position: Vector2) -> void:
	var result := find_best_shelf_access(drop_position, object)

	if not bool(result.get("valid", false)):
		clear_shelf_access_metadata(object)
		return

	object.set_meta(ACCESS_META, result.get("access_point", Vector2.INF))
	object.set_meta(ACCESS_NODE_META, result.get("graph_node", StringName()))


func clear_shelf_access_metadata(object: Node2D) -> void:
	if object == null:
		return

	if object.has_meta(ACCESS_META):
		object.remove_meta(ACCESS_META)

	if object.has_meta(ACCESS_NODE_META):
		object.remove_meta(ACCESS_NODE_META)


func get_shelf_access_graph_node(shelf: Shelf) -> StringName:
	if shelf == null:
		return StringName()

	if shelf.has_meta(ACCESS_NODE_META):
		var graph_node: Variant = shelf.get_meta(ACCESS_NODE_META)

		if graph_node is StringName:
			return graph_node as StringName

		if graph_node is String:
			return StringName(graph_node)

	var result := find_best_shelf_access(shelf.global_position, shelf)
	return result.get("graph_node", StringName()) as StringName


func _find_nearest_reachable_graph_node(
	access_point: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF
) -> Dictionary:
	var best_result := {"valid": false}
	var best_score := INF

	for node_name in _get_graph_node_names():
		var marker := _get_graph_marker(node_name)

		if marker == null:
			continue

		var route := _make_orthogonal_route(access_point, marker.global_position, true)

		if not _is_route_clear(access_point, route, shelf_object, shelf_position):
			continue

		var distance := _get_manhattan_distance(access_point, marker.global_position)

		if distance < best_score:
			best_score = distance
			best_result = {
				"valid": true,
				"node": node_name,
				"route": route,
				"distance": distance
			}

	return best_result


func _find_nearest_graph_node(position: Vector2) -> Dictionary:
	var best_result := {"valid": false}
	var best_score := INF

	for node_name in _get_graph_node_names():
		var marker := _get_graph_marker(node_name)

		if marker == null:
			continue

		var distance := _get_manhattan_distance(position, marker.global_position)

		if distance < best_score:
			best_score = distance
			best_result = {
				"valid": true,
				"node": node_name,
				"route": _make_orthogonal_route(position, marker.global_position, true),
				"distance": distance
			}

	return best_result


func _find_graph_path(start_node: StringName, goal_node: StringName) -> Array[StringName]:
	var result: Array[StringName] = []

	if start_node == StringName() or goal_node == StringName():
		return result

	if _get_graph_marker(start_node) == null or _get_graph_marker(goal_node) == null:
		return result

	var frontier: Array[StringName] = [start_node]
	var distances := {start_node: 0.0}
	var previous := {}
	var visited := {}

	while not frontier.is_empty():
		var current := _pop_lowest_cost_node(frontier, distances)

		if visited.has(current):
			continue

		visited[current] = true

		if current == goal_node:
			break

		for neighbor in _get_graph_neighbors(current):
			if visited.has(neighbor):
				continue

			var edge_cost := _get_graph_edge_cost(current, neighbor)

			if edge_cost >= INF:
				continue

			var next_cost := float(distances[current]) + edge_cost

			if not distances.has(neighbor) or next_cost < float(distances[neighbor]):
				distances[neighbor] = next_cost
				previous[neighbor] = current

				if neighbor not in frontier:
					frontier.append(neighbor)

	if not distances.has(goal_node):
		return result

	var cursor := goal_node

	while cursor != start_node:
		result.push_front(cursor)
		cursor = previous.get(cursor, StringName()) as StringName

		if cursor == StringName():
			result.clear()
			return result

	result.push_front(start_node)
	return result


func _build_route_from_graph_path(path: Array[StringName]) -> Array[Vector2]:
	var route: Array[Vector2] = []

	for node_name in path:
		var marker := _get_graph_marker(node_name)

		if marker != null:
			route.append(marker.global_position)

	return _dedupe_route_points(route)


func _append_orthogonal_route_to(
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

	route.append_array(_make_orthogonal_route(from_pos, to_pos, horizontal_first))


func _prepend_orthogonal_route(from_pos: Vector2, route: Array[Vector2], horizontal_first: bool = true) -> Array[Vector2]:
	if route.is_empty():
		return []

	var result := _make_orthogonal_route(from_pos, route[0], horizontal_first)
	result.append_array(route)
	return _dedupe_route_points(result)


func _make_orthogonal_route(from_pos: Vector2, to_pos: Vector2, horizontal_first: bool = true) -> Array[Vector2]:
	var route: Array[Vector2] = []

	if from_pos.distance_to(to_pos) <= 2.0:
		return route

	var corner := Vector2(to_pos.x, from_pos.y) if horizontal_first else Vector2(from_pos.x, to_pos.y)

	if from_pos.distance_to(corner) > 2.0:
		route.append(corner)

	if corner.distance_to(to_pos) > 2.0:
		route.append(to_pos)

	return route


func _dedupe_route_points(route: Array[Vector2]) -> Array[Vector2]:
	var deduped: Array[Vector2] = []

	for point in route:
		if not point.is_finite():
			continue

		if not deduped.is_empty() and deduped[deduped.size() - 1].distance_to(point) <= 2.0:
			continue

		deduped.append(point)

	return deduped


func _is_route_clear(
	start: Vector2,
	route: Array[Vector2],
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF
) -> bool:
	var current := start

	for point in route:
		if not _is_route_segment_clear(current, point, shelf_object, shelf_position):
			return false

		current = point

	return true


func _is_route_segment_clear(
	from_pos: Vector2,
	to_pos: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF
) -> bool:
	if from_pos.distance_to(to_pos) <= ROUTE_CLEARANCE_EPSILON:
		return true

	if not is_equal_approx(from_pos.x, to_pos.x) and not is_equal_approx(from_pos.y, to_pos.y):
		return false

	var distance := from_pos.distance_to(to_pos)
	var steps := maxi(1, int(ceil(distance / ROUTE_SAMPLE_STEP)))

	for index in range(steps + 1):
		var point := from_pos.lerp(to_pos, float(index) / float(steps))

		if not _is_npc_access_point_clear(point, shelf_object, shelf_position):
			return false

	return true


func _is_npc_access_point_clear(
	position: Vector2,
	shelf_object: Node2D = null,
	shelf_position: Vector2 = Vector2.INF
) -> bool:
	if shelf_object != null and shelf_position.is_finite():
		var shelf_rect := _get_object_body_rect_at(shelf_object, shelf_position)

		if _rect_has_area(shelf_rect) and _get_npc_standing_rect(position).intersects(shelf_rect):
			return false

	return _is_npc_standing_position_clear(position)


func _is_npc_standing_position_clear(position: Vector2, npc: Node = null) -> bool:
	if _store == null:
		return false

	var shape := RectangleShape2D.new()
	shape.size = STANDING_SHAPE_SIZE

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, position + STANDING_SHAPE_OFFSET)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 1

	if npc is CollisionObject2D:
		query.exclude = [(npc as CollisionObject2D).get_rid()]

	var hits := _store.get_world_2d().direct_space_state.intersect_shape(query, 16)
	return hits.is_empty()


func _get_npc_standing_rect(position: Vector2) -> Rect2:
	var center := position + STANDING_SHAPE_OFFSET
	return Rect2(center - STANDING_SHAPE_SIZE * 0.5, STANDING_SHAPE_SIZE)


func _get_object_body_rect_at(object: Node2D, candidate: Vector2) -> Rect2:
	var collision_shape := _get_object_collision_shape(object)

	if collision_shape == null:
		return Rect2(candidate - Vector2(32, 24), Vector2(64, 48))

	var rectangle := collision_shape.shape as RectangleShape2D

	if rectangle == null:
		return Rect2(candidate - Vector2(32, 24), Vector2(64, 48))

	var center := candidate + collision_shape.position
	return Rect2(center - rectangle.size * 0.5, rectangle.size)


func _get_object_collision_shape(object: Node2D) -> CollisionShape2D:
	if object == null:
		return null

	return object.get_node_or_null("PhysicsBody/CollisionShape2D") as CollisionShape2D


func _rect_has_area(rect: Rect2) -> bool:
	return rect.size.x > 0.0 and rect.size.y > 0.0


func _get_graph_marker(node_name: StringName) -> Marker2D:
	if _markers == null:
		return null

	return _markers.get_node_or_null(String(node_name)) as Marker2D


func _get_graph_node_names() -> Array[StringName]:
	return [
		ENTRY,
		EXIT,
		AISLE_RIGHT,
		AISLE_MID,
		AISLE_LEFT,
		CASHIER,
		QUEUE_FRONT,
		QUEUE_BACK_1,
		QUEUE_BACK_2
	]


func _get_graph_neighbors(node_name: StringName) -> Array[StringName]:
	match node_name:
		ENTRY:
			return [AISLE_RIGHT, EXIT]
		EXIT:
			return [ENTRY]
		AISLE_RIGHT:
			return [ENTRY, AISLE_MID]
		AISLE_MID:
			return [AISLE_RIGHT, AISLE_LEFT]
		AISLE_LEFT:
			return [AISLE_MID, CASHIER]
		CASHIER:
			return [AISLE_LEFT, QUEUE_BACK_2]
		QUEUE_BACK_2:
			return [CASHIER, QUEUE_BACK_1]
		QUEUE_BACK_1:
			return [QUEUE_BACK_2, QUEUE_FRONT]
		QUEUE_FRONT:
			return [QUEUE_BACK_1]

	return []


func _get_graph_edge_cost(from_node: StringName, to_node: StringName) -> float:
	var from_marker := _get_graph_marker(from_node)
	var to_marker := _get_graph_marker(to_node)

	if from_marker == null or to_marker == null:
		return INF

	return _get_manhattan_distance(from_marker.global_position, to_marker.global_position)


func _get_graph_path_cost(path: Array[StringName]) -> float:
	var cost := 0.0

	for index in range(1, path.size()):
		cost += _get_graph_edge_cost(path[index - 1], path[index])

	return cost


func _pop_lowest_cost_node(frontier: Array[StringName], distances: Dictionary) -> StringName:
	var best_index := 0
	var best_cost := INF

	for index in range(frontier.size()):
		var node_name := frontier[index]
		var cost := float(distances.get(node_name, INF))

		if cost < best_cost:
			best_cost = cost
			best_index = index

	return frontier.pop_at(best_index)


func _get_manhattan_distance(from_pos: Vector2, to_pos: Vector2) -> float:
	return absf(from_pos.x - to_pos.x) + absf(from_pos.y - to_pos.y)
