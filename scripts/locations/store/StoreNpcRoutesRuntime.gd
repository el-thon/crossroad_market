
class_name StoreNpcRoutesRuntime
extends Node

## Deterministic Store route provider.
##
## Shopping, queue, cashier, and exit movement use hand-authored markers and
## orthogonal segments.
## No navigation grid, path graph, runtime A*, Theta*, D* Lite, metadata job, or
## per-segment physics query is involved.

const READY: StringName = &"ready"
const INVALID: StringName = &"invalid"
const ROUTE_POINT_EPSILON: float = 1.5
const STORE_MIN_Y: float = 72.0
const STORE_MAX_Y: float = 246.0
const SHELF_ACCESS_GAP: float = 10.0
const SHELF_APPROACH_DISTANCE: float = 18.0
const NPC_HALF_HEIGHT_FALLBACK: float = 8.0

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
const QUEUE_RIGHT_MARKERS: Array[StringName] = [
    &"StorePathQueueFrontRight",
    &"StorePathQueueBack1Right",
    &"StorePathQueueBack2Right"
]
const QUEUE_EXIT_RIGHT_MARKER: StringName = &"StorePathQueueExitRight"

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
    return not resolve_npc_shelf_access(shelf, Vector2.INF).is_empty()


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
    var result: Dictionary = resolve_npc_shelf_access(shelf, Vector2.INF)
    if result.is_empty():
        return Vector2.INF
    return result["access"] as Vector2


func get_npc_shelf_visit_position(
    shelf: Shelf,
    npc_node: Node = null
) -> Vector2:
    var npc: NPC = npc_node as NPC
    var from_position: Vector2 = npc.global_position if npc != null else Vector2.INF
    var access_result: Dictionary = resolve_npc_shelf_access(shelf, from_position)

    if access_result.is_empty():
        return Vector2.INF

    if npc != null:
        npc._target_shelf_access_position = access_result["access"] as Vector2
        npc._target_shelf_access_approach = access_result["approach"] as Vector2
        npc._target_shelf_access_side = access_result["side"] as StringName

    return access_result["access"] as Vector2


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
    npc_node: Node = null
) -> Array[Vector2]:
    var npc: NPC = npc_node as NPC
    var access: Vector2 = Vector2.INF
    var approach: Vector2 = Vector2.INF

    if npc != null and npc._target_shelf_access_position.is_finite():
        access = npc._target_shelf_access_position
        approach = npc._target_shelf_access_approach
    else:
        var access_result: Dictionary = resolve_npc_shelf_access(
            shelf,
            from_position
        )
        if access_result.is_empty():
            return []
        access = access_result["access"] as Vector2
        approach = access_result["approach"] as Vector2
        if npc != null:
            npc._target_shelf_access_position = access
            npc._target_shelf_access_approach = approach
            npc._target_shelf_access_side = access_result["side"] as StringName

    if not access.is_finite() or not approach.is_finite():
        return []
    var start: Vector2 = from_position
    if not start.is_finite():
        start = _marker_position(ENTRY_MARKER, NPC.entrance_position)
    var aisle: Marker2D = _nearest_aisle_marker(approach)
    return _build_orthogonal_route_via(
        start,
        [
            aisle.global_position if aisle != null else Vector2.INF,
            approach,
            access
        ]
    )


func get_npc_route_to_cashier_from(
    from_position: Vector2,
    _npc_node: Node = null
) -> Array[Vector2]:
    var front: Vector2 = get_npc_cashier_target(from_position)
    if from_position.is_finite() and from_position.distance_to(front) <= ROUTE_POINT_EPSILON:
        return []

    return _build_orthogonal_route_via(
        from_position,
        [
            _marker_position(&"StorePathQueueFrontRight", Vector2.INF),
            front
        ]
    )


func get_npc_route_to_queue_target_from(
    from_position: Vector2,
    queue_index: int,
    _npc_node: Node = null
) -> Array[Vector2]:
    var target: Vector2 = get_npc_queue_target(queue_index, from_position)
    return _build_orthogonal_route(from_position, target, false)


func get_npc_route_from_shelf_to_queue_target(
    shelf: Shelf,
    from_position: Vector2,
    queue_index: int,
    npc_node: Node = null
) -> Array[Vector2]:
    var safe_index: int = clampi(queue_index, 0, QUEUE_MARKERS.size() - 1)
    var start: Vector2 = from_position
    var npc: NPC = npc_node as NPC

    if not start.is_finite() and npc != null:
        start = npc.global_position
    if not start.is_finite() and shelf != null and is_instance_valid(shelf):
        start = get_npc_shelf_access_position(shelf)

    return _build_orthogonal_route_via(
        start,
        [
            _marker_position(QUEUE_EXIT_RIGHT_MARKER, Vector2.INF),
            _marker_position(QUEUE_RIGHT_MARKERS[safe_index], Vector2.INF),
            _marker_position(QUEUE_MARKERS[safe_index], Vector2.INF)
        ]
    )


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
    var aisle: Marker2D = _nearest_aisle_marker(from_position)
    return _build_orthogonal_route_via(
        from_position,
        [
            aisle.global_position if aisle != null else Vector2.INF,
            _marker_position(ENTRY_MARKER, NPC.exit_position)
        ]
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
    return _build_orthogonal_route_via(
        from_position,
        [
            _marker_position(&"StorePathQueueFrontRight", Vector2.INF),
            _marker_position(QUEUE_EXIT_RIGHT_MARKER, Vector2.INF),
            _marker_position(ENTRY_MARKER, NPC.exit_position)
        ]
    )


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


func resolve_npc_shelf_access(
    shelf: Shelf,
    from_position: Vector2,
    excluded_side: StringName = &""
) -> Dictionary:
    if shelf == null or not is_instance_valid(shelf):
        return {}
    if store == null:
        return {}
    if not shelf.is_in_group("shelves"):
        return {}
    if not _is_descendant_of(shelf, store):
        return {}
    if bool(shelf.get_meta("is_carried_storage_object", false)):
        return {}

    var body_rect: Rect2 = _get_shelf_body_rect(shelf)
    var center_x: float = body_rect.get_center().x
    var bottom_access := Vector2(
        center_x,
        body_rect.end.y + NPC_HALF_HEIGHT_FALLBACK + SHELF_ACCESS_GAP
    )
    var top_access := Vector2(
        center_x,
        body_rect.position.y - NPC_HALF_HEIGHT_FALLBACK - SHELF_ACCESS_GAP
    )
    var candidates: Array[Dictionary] = [
        {
            "side": &"bottom",
            "access": bottom_access,
            "approach": bottom_access + Vector2(0.0, SHELF_APPROACH_DISTANCE)
        },
        {
            "side": &"top",
            "access": top_access,
            "approach": top_access - Vector2(0.0, SHELF_APPROACH_DISTANCE)
        }
    ]

    var best: Dictionary = {}
    var best_score: float = INF
    for candidate: Dictionary in candidates:
        if candidate["side"] == excluded_side:
            continue

        var access: Vector2 = candidate["access"] as Vector2
        var approach: Vector2 = candidate["approach"] as Vector2
        if not _is_store_position_valid(access):
            continue
        if not _is_store_position_valid(approach):
            continue
        if not _is_shelf_access_corridor_clear(shelf, approach, access):
            continue

        var aisle: Marker2D = _nearest_aisle_marker(approach)
        if aisle == null:
            continue

        var start: Vector2 = from_position
        if not start.is_finite():
            start = _marker_position(ENTRY_MARKER, NPC.entrance_position)
        var score: float = (
            _manhattan(start, aisle.global_position)
            + _manhattan(aisle.global_position, approach)
            + _manhattan(approach, access)
        )
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


func _build_orthogonal_route(
    from_position: Vector2,
    to_position: Vector2,
    horizontal_first: bool = true
) -> Array[Vector2]:
    var route: Array[Vector2] = []

    if (
        not from_position.is_finite()
        or not to_position.is_finite()
        or from_position.distance_to(to_position) <= ROUTE_POINT_EPSILON
    ):
        return route

    var corner: Vector2 = (
        Vector2(to_position.x, from_position.y)
        if horizontal_first
        else Vector2(from_position.x, to_position.y)
    )

    _append_unique(route, corner)
    _append_unique(route, to_position)
    return route


func _build_orthogonal_route_via(
    from_position: Vector2,
    waypoints: Array[Vector2]
) -> Array[Vector2]:
    var route: Array[Vector2] = []
    var segment_start: Vector2 = from_position

    for waypoint: Vector2 in waypoints:
        if not waypoint.is_finite():
            continue

        var segment: Array[Vector2] = _build_orthogonal_route(
            segment_start,
            waypoint,
            true
        )

        for point: Vector2 in segment:
            _append_unique(route, point)

        segment_start = waypoint

    return route


func _append_orthogonal(
    route: Array[Vector2],
    from_position: Vector2,
    to_position: Vector2
) -> void:
    if from_position.distance_to(to_position) <= ROUTE_POINT_EPSILON:
        return
    for point: Vector2 in _build_orthogonal_route(from_position, to_position):
        _append_unique(route, point)


func _get_shelf_body_rect(shelf: Shelf) -> Rect2:
    var collision: CollisionShape2D = shelf.get_node_or_null(
        "PhysicsBody/CollisionShape2D"
    ) as CollisionShape2D

    if collision == null:
        return Rect2(
            shelf.global_position - Vector2(32.0, 24.0),
            Vector2(64.0, 24.0)
        )

    var rectangle: RectangleShape2D = collision.shape as RectangleShape2D
    if rectangle == null:
        return Rect2(
            shelf.global_position - Vector2(32.0, 24.0),
            Vector2(64.0, 24.0)
        )

    return Rect2(
        collision.global_position - rectangle.size * 0.5,
        rectangle.size
    )


func _is_store_position_valid(position: Vector2) -> bool:
    return (
        position.is_finite()
        and position.y >= STORE_MIN_Y
        and position.y <= STORE_MAX_Y
    )


func _is_shelf_access_corridor_clear(
    shelf: Shelf,
    approach: Vector2,
    access: Vector2
) -> bool:
    var corridor: Rect2 = _get_access_corridor_rect(approach, access)
    if not corridor.has_area():
        return false

    for shelf_variant in store.get_tree().get_nodes_in_group("shelves"):
        var other_shelf := shelf_variant as Shelf
        if other_shelf == null:
            continue
        if other_shelf == shelf:
            continue
        if not _is_descendant_of(other_shelf, store):
            continue
        if bool(other_shelf.get_meta("is_carried_storage_object", false)):
            continue
        if corridor.intersects(_get_shelf_body_rect(other_shelf)):
            return false

    return true


func _get_access_corridor_rect(from_position: Vector2, to_position: Vector2) -> Rect2:
    var min_position := Vector2(
        minf(from_position.x, to_position.x),
        minf(from_position.y, to_position.y)
    )
    var max_position := Vector2(
        maxf(from_position.x, to_position.x),
        maxf(from_position.y, to_position.y)
    )
    var size := max_position - min_position
    if size.x < 16.0:
        min_position.x -= 8.0
        size.x = 16.0
    if size.y < 16.0:
        min_position.y -= 8.0
        size.y = 16.0
    return Rect2(min_position, size)


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
