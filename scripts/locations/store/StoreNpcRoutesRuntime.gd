
class_name StoreNpcRoutesRuntime
extends Node

## Deterministic Store route provider.
##
## Shopping movement uses hand-authored aisle markers and orthogonal segments.
## Once an item has been taken, queue/cashier movement may use a direct segment.
## No navigation grid, path graph, runtime A*, Theta*, D* Lite, metadata job, or
## per-segment physics query is involved.

const READY: StringName = &"ready"
const INVALID: StringName = &"invalid"
const SHELF_ACCESS_OFFSET: float = 34.0
const ROUTE_POINT_EPSILON: float = 1.5
const STORE_MIN_Y: float = 72.0
const STORE_MAX_Y: float = 246.0

const ENTRY_MARKER: StringName = &"StorePathEntryExit"
const AISLE_MARKERS: Array[StringName] = [
    &"StorePathAisleLeft",
    &"StorePathAisleCenter",
    &"StorePathAisleRight"
]
const CASHIER_MARKER: StringName = &"StorePathCashier"
const QUEUE_MARKERS: Array[StringName] = [
    &"StorePathQueueFront",
    &"StorePathQueueBack1",
    &"StorePathQueueBack2"
]

var store: Node2D = null


func setup(store_node: Node) -> void:
    store = store_node as Node2D
    if store == null:
        return
    for shelf_variant in store.get_tree().get_nodes_in_group("shelves"):
        if shelf_variant is Shelf:
            mark_shelf_navigation_ready(shelf_variant as Shelf)


func mark_shelf_navigation_ready(shelf: Shelf) -> void:
    if shelf == null or not is_instance_valid(shelf):
        return
    shelf.set_meta("npc_path_ready", can_npc_visit_shelf(shelf))


func clear_shelf_navigation_ready(shelf: Shelf) -> void:
    if shelf == null or not is_instance_valid(shelf):
        return
    shelf.set_meta("npc_path_ready", false)


func can_npc_visit_shelf(shelf: Shelf) -> bool:
    if store == null or shelf == null or not is_instance_valid(shelf):
        return false
    if not shelf.is_in_group("shelves"):
        return false
    if not _is_descendant_of(shelf, store):
        return false
    if bool(shelf.get_meta("is_carried_storage_object", false)):
        return false
    return _choose_shelf_access_position(shelf).is_finite()


func request_npc_shelf_access_state(
    shelf: Shelf,
    _high_priority: bool = false
) -> StringName:
    mark_shelf_navigation_ready(shelf)
    return READY if can_npc_visit_shelf(shelf) else INVALID


func get_npc_shelf_access_state(shelf: Shelf) -> StringName:
    return request_npc_shelf_access_state(shelf)


func has_npc_shelf_access_metadata(shelf: Shelf) -> bool:
    return can_npc_visit_shelf(shelf)


func get_npc_shelf_access_position(shelf: Shelf) -> Vector2:
    if not can_npc_visit_shelf(shelf):
        return Vector2.INF
    return _choose_shelf_access_position(shelf)


func get_npc_shelf_visit_position(
    shelf: Shelf,
    _npc: Node = null
) -> Vector2:
    return get_npc_shelf_access_position(shelf)


func get_npc_entry_route_to_shelf(
    shelf_position: Vector2,
    from_position: Vector2 = Vector2.INF
) -> Array[Vector2]:
    var start: Vector2 = from_position
    if not start.is_finite():
        start = _marker_position(ENTRY_MARKER, NPC.entrance_position)
    return _build_orthogonal_shelf_route(start, shelf_position)


func get_npc_route_to_shelf_access(
    shelf: Shelf,
    from_position: Vector2 = Vector2.INF,
    _npc_node: Node = null
) -> Array[Vector2]:
    var access: Vector2 = get_npc_shelf_access_position(shelf)
    if not access.is_finite():
        return []
    var start: Vector2 = from_position
    if not start.is_finite():
        start = _marker_position(ENTRY_MARKER, NPC.entrance_position)
    return _build_orthogonal_shelf_route(start, access)


func get_npc_route_to_cashier_from(
    from_position: Vector2,
    _npc_node: Node = null
) -> Array[Vector2]:
    return _direct_route(from_position, get_npc_cashier_target(from_position))


func get_npc_route_to_queue_target_from(
    from_position: Vector2,
    queue_index: int,
    _npc_node: Node = null
) -> Array[Vector2]:
    var target: Vector2 = get_npc_queue_target(queue_index, from_position)
    return _direct_route(from_position, target)


func get_npc_route_from_shelf_to_queue_target(
    _shelf: Shelf,
    from_position: Vector2,
    queue_index: int,
    _npc_node: Node = null
) -> Array[Vector2]:
    return get_npc_route_to_queue_target_from(from_position, queue_index)


func get_npc_route_from_shelf_to_cashier(
    shelf: Shelf,
    _npc_node: Node = null
) -> Array[Vector2]:
    var start: Vector2 = get_npc_shelf_access_position(shelf)
    if not start.is_finite() and shelf != null and is_instance_valid(shelf):
        start = shelf.global_position
    return get_npc_route_to_cashier_from(start)


func get_npc_queue_target(
    queue_index: int,
    fallback_position: Vector2
) -> Vector2:
    var safe_index: int = clampi(queue_index, 0, QUEUE_MARKERS.size() - 1)
    return _marker_position(QUEUE_MARKERS[safe_index], fallback_position)


func get_npc_cashier_target(fallback_position: Vector2) -> Vector2:
    return get_npc_queue_target(0, fallback_position)


func get_npc_cashier_face_target(fallback_position: Vector2) -> Vector2:
    return _marker_position(CASHIER_MARKER, fallback_position)


func get_npc_exit_route_from(
    from_position: Vector2,
    _npc_node: Node = null
) -> Array[Vector2]:
    return _direct_route(
        from_position,
        _marker_position(ENTRY_MARKER, NPC.exit_position)
    )


func get_npc_single_customer_exit_route(
    from_position: Vector2,
    npc_node: Node = null
) -> Array[Vector2]:
    return get_npc_exit_route_from_cashier(from_position, npc_node)


func get_npc_exit_route_from_shelf(
    _shelf: Shelf,
    from_position: Vector2,
    npc_node: Node = null
) -> Array[Vector2]:
    return get_npc_exit_route_from(from_position, npc_node)


func get_npc_exit_route_from_cashier(
    from_position: Vector2,
    _npc_node: Node = null
) -> Array[Vector2]:
    var route: Array[Vector2] = []
    var aisle_right: Vector2 = _marker_position(
        &"StorePathAisleRight",
        Vector2.INF
    )
    if aisle_right.is_finite():
        _append_unique(route, aisle_right)
    _append_unique(route, _marker_position(ENTRY_MARKER, NPC.exit_position))
    return route


func get_npc_shelf_wait_position(index: int = 0) -> Vector2:
    var marker_name: StringName = AISLE_MARKERS[clampi(index, 0, AISLE_MARKERS.size() - 1)]
    return _marker_position(marker_name, NPC.entrance_position)


func get_npc_local_avoidance_adjustment(
    _npc: NPC,
    desired_target: Vector2
) -> Dictionary:
    return {"target": desired_target, "wait": false}


func invalidate_npc_shelf_access(shelf: Shelf) -> void:
    clear_shelf_navigation_ready(shelf)


func invalidate_navigation() -> void:
    pass


func _choose_shelf_access_position(shelf: Shelf) -> Vector2:
    if shelf == null or not is_instance_valid(shelf):
        return Vector2.INF
    var candidates: Array[Vector2] = [
        shelf.global_position + Vector2(0.0, SHELF_ACCESS_OFFSET),
        shelf.global_position - Vector2(0.0, SHELF_ACCESS_OFFSET)
    ]
    var best: Vector2 = Vector2.INF
    var best_score: float = INF
    for candidate: Vector2 in candidates:
        if candidate.y < STORE_MIN_Y or candidate.y > STORE_MAX_Y:
            continue
        var aisle: Marker2D = _nearest_aisle_marker(candidate)
        if aisle == null:
            continue
        var score: float = _manhattan(candidate, aisle.global_position)
        if score < best_score:
            best_score = score
            best = candidate
    return best


func _build_orthogonal_shelf_route(
    from_position: Vector2,
    access_position: Vector2
) -> Array[Vector2]:
    if not from_position.is_finite() or not access_position.is_finite():
        return []
    var aisle: Marker2D = _nearest_aisle_marker(access_position)
    if aisle == null:
        return []
    var route: Array[Vector2] = []
    _append_orthogonal(route, from_position, aisle.global_position)
    var segment_start: Vector2 = from_position if route.is_empty() else route.back()
    _append_orthogonal(route, segment_start, access_position)
    return route


func _append_orthogonal(
    route: Array[Vector2],
    from_position: Vector2,
    to_position: Vector2
) -> void:
    if from_position.distance_to(to_position) <= ROUTE_POINT_EPSILON:
        return
    var corner: Vector2 = Vector2(to_position.x, from_position.y)
    if corner.distance_to(from_position) > ROUTE_POINT_EPSILON:
        _append_unique(route, corner)
    _append_unique(route, to_position)


func _direct_route(
    from_position: Vector2,
    to_position: Vector2
) -> Array[Vector2]:
    if not from_position.is_finite() or not to_position.is_finite():
        return []
    if from_position.distance_to(to_position) <= ROUTE_POINT_EPSILON:
        return []
    return [to_position]


func _nearest_aisle_marker(position: Vector2) -> Marker2D:
    var best: Marker2D = null
    var best_distance: float = INF
    for marker_name: StringName in AISLE_MARKERS:
        var marker: Marker2D = _get_marker(marker_name)
        if marker == null:
            continue
        var distance: float = _manhattan(position, marker.global_position)
        if distance < best_distance:
            best_distance = distance
            best = marker
    return best


func _get_marker(marker_name: StringName) -> Marker2D:
    if store == null:
        return null
    var root: Node = store.get_node_or_null("StorePathMarkers")
    if root == null:
        return null
    return root.get_node_or_null(String(marker_name)) as Marker2D


func _marker_position(
    marker_name: StringName,
    fallback: Vector2
) -> Vector2:
    var marker: Marker2D = _get_marker(marker_name)
    return marker.global_position if marker != null else fallback


func _append_unique(route: Array[Vector2], point: Vector2) -> void:
    if not point.is_finite():
        return
    if not route.is_empty() and route.back().distance_to(point) <= ROUTE_POINT_EPSILON:
        return
    route.append(point)


func _manhattan(a: Vector2, b: Vector2) -> float:
    return absf(a.x - b.x) + absf(a.y - b.y)


func _is_descendant_of(node: Node, ancestor: Node) -> bool:
    var current: Node = node
    while current != null:
        if current == ancestor:
            return true
        current = current.get_parent()
    return false
