from __future__ import annotations

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def write(path: str, content: str) -> None:
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content.rstrip() + "\n", encoding="utf-8")


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def replace_required(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count == 0:
        raise RuntimeError(f"Missing required replacement in {label}: {old!r}")
    return text.replace(old, new)


def function_spans(text: str) -> list[tuple[str, int, int]]:
    matches = list(re.finditer(r"(?m)^func\s+([A-Za-z0-9_]+)\s*\(", text))
    spans: list[tuple[str, int, int]] = []
    for index, match in enumerate(matches):
        start = match.start()
        # Include immediately preceding warning annotations and blank lines.
        line_start = text.rfind("\n", 0, start) + 1
        probe = line_start
        while probe > 0:
            previous_end = probe - 1
            previous_start = text.rfind("\n", 0, previous_end) + 1
            previous = text[previous_start:previous_end].strip()
            if previous == "" or previous.startswith("@warning_ignore"):
                probe = previous_start
                continue
            break
        start = probe
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        spans.append((match.group(1), start, end))
    return spans


def replace_function(text: str, name: str, replacement: str) -> str:
    for function_name, start, end in function_spans(text):
        if function_name == name:
            return text[:start] + "\n\n" + replacement.rstrip() + "\n\n" + text[end:]
    raise RuntimeError(f"Function {name} not found")


def remove_functions_containing(text: str, tokens: tuple[str, ...]) -> str:
    spans = function_spans(text)
    removals: list[tuple[int, int]] = []
    for _name, start, end in spans:
        block = text[start:end]
        if any(token in block for token in tokens):
            removals.append((start, end))
    for start, end in reversed(removals):
        text = text[:start] + "\n" + text[end:]
    return text


ROUTES_RUNTIME = r'''
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
'''

NPC_RUNTIME = r'''
class_name StoreNpcRuntime
extends Node

const NPCRouteControllerScript = preload(
    "res://scripts/npc/runtime/NPCRouteController.gd"
)
const NPCLiveQueueStateFlowScript = preload(
    "res://scripts/npc/runtime/NPCLiveQueueStateFlow.gd"
)
const NPCCheckoutLaneQueueFlowScript = preload(
    "res://scripts/npc/runtime/NPCCheckoutLaneQueueFlow.gd"
)
const CUSTOMER_INTAKE_CLOSED_META: StringName = &"customer_intake_closed_today"

var store: Node = null


func setup(store_node: Node) -> void:
    store = store_node


func setup_static_data() -> void:
    if store == null:
        return
    if store.npc_queue_marker != null:
        NPC.counter_position = store.npc_queue_marker.global_position
    elif store.counter_pos != null:
        NPC.counter_position = store.counter_pos.global_position
    if store.npc_enter_store_marker != null:
        NPC.entrance_position = store.npc_enter_store_marker.global_position
    elif store.entrance_pos != null:
        NPC.entrance_position = store.entrance_pos.global_position
    if store.npc_exit_marker != null:
        NPC.exit_position = store.npc_exit_marker.global_position
    else:
        NPC.exit_position = NPC.entrance_position
    if store.npc_store_path_marker != null:
        NPC.store_path_position = store.npc_store_path_marker.global_position
    else:
        NPC.store_path_position = Vector2.INF


func on_npc_spawn_requested(npc_data: NPCData) -> void:
    if store == null or not is_store_world_available_for_customer_spawn():
        return
    if not store._store_open or bool(store.get_meta(CUSTOMER_INTAKE_CLOSED_META, false)):
        return
    var npc: NPC = StoreNpcSpawner.spawn_npc(
        store,
        store.npc_scene,
        get_npc_spawn_marker(),
        npc_data,
        Callable(self, "on_npc_purchase"),
        Callable(self, "on_npc_exited")
    )
    if npc == null:
        return
    install_store_controllers(npc)
    var route_ready_callable: Callable = Callable(self, "on_npc_shelf_route_ready")
    if not npc.shelf_route_ready.is_connected(route_ready_callable):
        npc.shelf_route_ready.connect(route_ready_callable)


func is_store_world_available_for_customer_spawn() -> bool:
    return (
        bool(store._is_store_world_active)
        and not bool(store._is_transitioning)
        and store._current_storage == null
        and store._current_yard == null
        and store._current_home == null
    )


func install_store_controllers(npc: NPC) -> void:
    if npc == null or not is_instance_valid(npc):
        return
    npc._route_controller = NPCRouteControllerScript.new()
    npc._route_controller.setup(npc)
    npc._state_flow = NPCLiveQueueStateFlowScript.new()
    npc._state_flow.setup(npc)
    # Keep the standard NPCShoppingFlow created by NPC._ready(). It already
    # filters shelves through npc_path_ready and asks Store for the visit point.
    npc._queue_flow = NPCCheckoutLaneQueueFlowScript.new()
    npc._queue_flow.setup(npc)


func get_npc_spawn_marker() -> Marker2D:
    if store == null:
        return null
    if store.npc_enter_store_marker != null:
        return store.npc_enter_store_marker
    if store.npc_entry_marker != null:
        return store.npc_entry_marker
    return store.entrance_pos


func on_npc_purchase(_npc: NPC, _item_id: String, price: int) -> void:
    if store == null:
        return
    EconomyManager.add_gold(price)
    if price > 0:
        store._show_task_complete_notice(
            "normal_customer_served",
            "First customer served."
        )


func on_npc_exited(_npc: NPC) -> void:
    if store != null:
        store._update_end_day_tax_flow()


func on_npc_shelf_route_ready(npc: NPC, travel_seconds: float) -> void:
    NPCScheduler.notify_npc_shelf_route_ready(npc, travel_seconds)
'''

MARKERS_SCENE = r'''
[gd_scene format=3 uid="uid://ck4oyd6i35v14"]

[node name="StorePathMarkers" type="Node2D" unique_id=241050301]
position = Vector2(-14, -39)

[node name="StorePathEntryExit" type="Marker2D" parent="."]
position = Vector2(254, 277)
metadata/store_path_role = "entry_exit"

[node name="StorePathAisleLeft" type="Marker2D" parent="."]
position = Vector2(124, 249)
metadata/store_path_role = "aisle_left"

[node name="StorePathAisleCenter" type="Marker2D" parent="."]
position = Vector2(254, 249)
metadata/store_path_role = "aisle_center"

[node name="StorePathAisleRight" type="Marker2D" parent="."]
position = Vector2(384, 249)
metadata/store_path_role = "aisle_right"

[node name="StorePathCashier" type="Marker2D" parent="."]
position = Vector2(254, 168)
metadata/store_path_role = "cashier"

[node name="StorePathQueueFront" type="Marker2D" parent="."]
position = Vector2(254, 178)
metadata/store_path_role = "queue_front"
metadata/store_queue_index = 0

[node name="StorePathQueueBack1" type="Marker2D" parent="."]
position = Vector2(254, 190)
metadata/store_path_role = "queue_back"
metadata/store_queue_index = 1

[node name="StorePathQueueBack2" type="Marker2D" parent="."]
position = Vector2(254, 202)
metadata/store_path_role = "queue_back"
metadata/store_queue_index = 2
'''

PROGRESSION_CONTROLLER = r'''
class_name StoreProgressionController
extends RefCounted


static func can_unlock_mystery_phase(
    human_stock_count: int,
    required_stock: int,
    human_shelf_installed: bool,
    already_unlocked: bool
) -> bool:
    return (
        human_stock_count >= required_stock
        and human_shelf_installed
        and not already_unlocked
    )


static func can_unlock_customer_spawning(
    already_unlocked: bool,
    ghost_shelf_installed: bool,
    ghost_shelf: Shelf
) -> bool:
    if already_unlocked:
        return true
    if not ghost_shelf_installed:
        return false
    if ghost_shelf == null or not is_instance_valid(ghost_shelf):
        return false
    var tree: SceneTree = ghost_shelf.get_tree()
    if tree == null:
        return false
    var store: Node = tree.get_first_node_in_group("store")
    if store == null:
        return false
    var routes: Node = store.get("npc_routes") as Node
    if routes == null or not routes.has_method("can_npc_visit_shelf"):
        return false
    routes.call("mark_shelf_navigation_ready", ghost_shelf)
    return ghost_shelf.has_stock() and bool(
        routes.call("can_npc_visit_shelf", ghost_shelf)
    )


static func should_start_day_one_customers_now() -> bool:
    return (
        TimeManager.current_day == 1
        and TimeManager.current_phase != TimeManager.Phase.NIGHT
    )
'''


def patch_store() -> None:
    path = "scripts/locations/store/Store.gd"
    text = read(path)
    text = text.replace("const SHELF_ACCESS_WARMUP_DELAY: float = 1.0\n", "")
    text = replace_required(
        text,
        '@onready var npc_entry_marker: Marker2D = _get_store_path_marker_by_role(&"entry", NodePath("StorePathMarkers/StorePathEntry"), NodePath("NPCEntryMarker"))',
        '@onready var npc_entry_marker: Marker2D = get_node_or_null("StorePathMarkers/StorePathEntryExit") as Marker2D',
        path,
    )
    text = replace_required(
        text,
        '@onready var npc_enter_store_marker: Marker2D = _get_store_path_marker_by_role(&"enter_store", NodePath("StorePathMarkers/StorePathEnterStore"), NodePath("NPCEnterStoreMarker"))',
        '@onready var npc_enter_store_marker: Marker2D = get_node_or_null("StorePathMarkers/StorePathEntryExit") as Marker2D',
        path,
    )
    text = replace_required(
        text,
        '@onready var npc_exit_marker: Marker2D = _get_store_path_marker_by_role(&"exit", NodePath("StorePathMarkers/StorePathExit"), NodePath("NPCExitMarker"))',
        '@onready var npc_exit_marker: Marker2D = get_node_or_null("StorePathMarkers/StorePathEntryExit") as Marker2D',
        path,
    )
    text = text.replace(
        '@onready var storage_return_pos: Marker2D = _get_store_path_marker_by_role(&"storage_return", NodePath("StorePathMarkers/StorePathStorageReturn"), NodePath("StorageReturnPos"))',
        '@onready var storage_return_pos: Marker2D = get_node_or_null("StorageReturnPos") as Marker2D',
    )
    text = re.sub(
        r'(?m)^@warning_ignore\("unused_private_class_variable"\)\nvar _store_path_graph: StorePathGraph = null\n',
        "",
        text,
    )
    text = re.sub(
        r'(?m)^@warning_ignore\("unused_private_class_variable"\)\nvar _shelf_access_(?:metadata_update|warmup)_token: int = 0\n',
        "",
        text,
    )
    text = text.replace("\t_store_path_graph = StorePathGraph.new(self, store_path_markers)\n", "")
    text = text.replace("\t_schedule_shelf_access_warmup(0.8)\n", "")
    text = remove_functions_containing(
        text,
        (
            "StorePathGraph",
            "_store_path_graph",
            "_shelf_access_metadata_update_token",
            "_shelf_access_warmup_token",
        ),
    )
    for name in (
        "_schedule_shelf_access_warmup",
        "_schedule_shelf_access_metadata_update",
        "_update_shelf_access_metadata",
        "_invalidate_store_navigation",
    ):
        try:
            text = replace_function(text, name, "")
        except RuntimeError:
            pass
    write(path, text)


def patch_placement_controller() -> None:
    path = "scripts/locations/store/StoreShelfPlacementController.gd"
    text = read(path)
    text = re.sub(r'(?m)^const PENDING_ACCESS_UPDATE_META:.*\n', "", text)
    text = re.sub(r'(?m)^const SHELF_ACCESS_WARMUP_DELAY:.*\n', "", text)
    text = replace_function(
        text,
        "store_shelf_access_metadata",
        '''func store_shelf_access_metadata(object: Node2D, _drop_position: Vector2) -> void:
\tif object is Shelf and store.npc_routes != null:
\t\tstore.npc_routes.mark_shelf_navigation_ready(object as Shelf)''',
    )
    text = replace_function(
        text,
        "schedule_post_shelf_drop_update",
        '''func schedule_post_shelf_drop_update(object: Node2D, drop_position: Vector2) -> void:
\tif object == null or not is_instance_valid(object):
\t\treturn
\tstore_shelf_access_metadata(object, drop_position)
\tstore._register_installed_shelf(object)''',
    )
    for name, body in {
        "defer_post_shelf_drop_update": '''func defer_post_shelf_drop_update(
\tobject: Node2D,
\tdrop_position: Vector2,
\t_update_token: int
) -> void:
\tschedule_post_shelf_drop_update(object, drop_position)''',
        "schedule_shelf_access_warmup": '''func schedule_shelf_access_warmup(_delay: float = 0.0) -> void:
\tif store == null or store.npc_routes == null:
\t\treturn
\tfor shelf_variant in store.get_tree().get_nodes_in_group("shelves"):
\t\tif shelf_variant is Shelf:
\t\t\tstore.npc_routes.mark_shelf_navigation_ready(shelf_variant as Shelf)''',
        "defer_shelf_access_warmup": '''func defer_shelf_access_warmup(_warmup_token: int, _delay: float) -> void:
\tschedule_shelf_access_warmup()''',
        "can_run_shelf_access_warmup": '''func can_run_shelf_access_warmup() -> bool:
\treturn store != null''',
        "clear_shelf_access_metadata": '''func clear_shelf_access_metadata(object: Node2D) -> void:
\tif object is Shelf and store.npc_routes != null:
\t\tstore.npc_routes.clear_shelf_navigation_ready(object as Shelf)''',
    }.items():
        text = replace_function(text, name, body)
    write(path, text)


def patch_route_controller() -> None:
    path = "scripts/npc/runtime/NPCRouteController.gd"
    text = read(path)
    text = text.replace(
        'const StoreRouteSafetyScript = preload("res://scripts/npc/runtime/StoreRouteSafety.gd")\n',
        "",
    )
    text = re.sub(
        r'(?m)^@warning_ignore\("unused_private_class_variable"\)\nvar _route_safety = null\n',
        "",
        text,
    )
    text = text.replace(
        '''\tif _route_safety == null:
\t\t_route_safety = StoreRouteSafetyScript.new()
\t_route_safety.setup(npc)
''',
        "",
    )
    text = text.replace(
        '''\t\tif _route_safety != null:
\t\t\troute = _route_safety.sanitize_store_route(route)
''',
        "",
    )
    text = replace_function(
        text,
        "get_shelf_egress_queue_route",
        '''func get_shelf_egress_queue_route(
\tstore: Node,
\tqueue_index: int,
\tdestination: Vector2
) -> Array[Vector2]:
\tif (
\t\tstore == null
\t\tor npc._queue_entry_shelf == null
\t\tor not is_instance_valid(npc._queue_entry_shelf)
\t):
\t\treturn []
\tvar route: Array[Vector2] = call_store_route(
\t\tstore,
\t\t&"get_npc_route_from_shelf_to_queue_target",
\t\t[
\t\t\tnpc._queue_entry_shelf,
\t\t\tnpc.global_position,
\t\t\tqueue_index,
\t\t\tnpc
\t\t]
\t)
\tif (
\t\tnot route.is_empty()
\t\tand route.back().distance_to(destination) > npc.ARRIVAL_THRESHOLD
\t):
\t\troute.append(destination)
\treturn dedupe_route_points(route)''',
    )
    write(path, text)


def patch_scene() -> None:
    path = "scenes/locations/Store.tscn"
    text = read(path)
    text = replace_required(
        text,
        "res://scripts/locations/store/StoreBudgetedShelfPlacementController.gd",
        "res://scripts/locations/store/StoreShelfPlacementController.gd",
        path,
    )
    write(path, text)


def delete_legacy_files() -> None:
    navigation_dir = ROOT / "scripts/navigation/store"
    if navigation_dir.exists():
        shutil.rmtree(navigation_dir)
    data_file = ROOT / "data/navigation/store_navigation_cost_policy.tres"
    if data_file.exists():
        data_file.unlink()
    exact = [
        "scripts/locations/store/StoreNpcRoutes.gd",
        "scripts/locations/store/StoreRuntimePathGraph.gd",
        "scripts/locations/store/StoreShelfAccessRuntimeGraph.gd",
        "scripts/locations/store/OptimizedStorePathGraph.gd",
        "scripts/locations/store/StoreBudgetedShelfPlacementController.gd",
        "scripts/npc/runtime/NPCLayeredNavigationRouteController.gd",
        "scripts/npc/runtime/NPCResolvedExitRouteController.gd",
        "scripts/npc/runtime/NPCTargetArrivalRouteController.gd",
        "scripts/npc/runtime/NPCReachableShelfShoppingFlow.gd",
        "scripts/npc/runtime/StoreRouteSafety.gd",
    ]
    for relative in exact:
        path = ROOT / relative
        if path.exists():
            path.unlink()
    for pattern in (
        "scripts/locations/store/StorePathGraph*.gd",
        "scripts/locations/store/store_path_graph_*.gd",
    ):
        for path in ROOT.glob(pattern):
            path.unlink()


def verify_no_legacy_references() -> None:
    forbidden = (
        "StorePathGraph",
        "StoreNavigationService",
        "StoreShelfAccessCoordinator",
        "NPCLayeredNavigationRouteController",
        "NPCReachableShelfShoppingFlow",
        "StoreRouteSafety.gd",
        "StoreBudgetedShelfPlacementController.gd",
        "scripts/navigation/store/",
    )
    failures: list[str] = []
    for root_name in ("scripts", "scenes", "data"):
        root = ROOT / root_name
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in {".gd", ".tscn", ".tres"}:
                continue
            text = path.read_text(encoding="utf-8")
            for token in forbidden:
                if token in text:
                    failures.append(f"{path.relative_to(ROOT)} contains {token}")
    if failures:
        raise RuntimeError("Legacy references remain:\n" + "\n".join(failures))


write("scripts/locations/store/StoreNpcRoutesRuntime.gd", ROUTES_RUNTIME)
write("scripts/locations/store/StoreNpcRuntime.gd", NPC_RUNTIME)
write("scenes/locations/store/StorePathMarkers.tscn", MARKERS_SCENE)
write("scripts/locations/store/StoreProgressionController.gd", PROGRESSION_CONTROLLER)
patch_store()
patch_placement_controller()
patch_route_controller()
patch_scene()
delete_legacy_files()
verify_no_legacy_references()
print("Marker-only Store navigation migration completed.")
