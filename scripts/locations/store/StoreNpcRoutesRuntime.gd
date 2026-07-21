class_name StoreNpcRoutesRuntime
extends "res://scripts/locations/store/StoreNpcRoutes.gd"

const StrictPathGraphScript = preload(
	"res://scripts/locations/store/StoreOrthogonalShelfRuntimeGraph.gd"
)
const StrictNavigationServiceScript = preload(
	"res://scripts/navigation/store/StoreAccessAwareNavigationService.gd"
)
const ShelfRoutePolicyScript = preload(
	"res://scripts/locations/store/StoreShelfRoutePolicy.gd"
)

var _shelf_route_policy: StoreShelfRoutePolicy = null


func _process(_delta: float) -> void:
	if store == null or _shelf_access_coordinator == null:
		return
	if (
		not bool(store._is_store_world_active)
		or bool(store._is_transitioning)
		or store._current_storage != null
		or store._current_yard != null
		or store._current_home != null
	):
		return
	_shelf_access_coordinator.process_pending_jobs()


func get_npc_route_to_shelf_access(
	shelf: Shelf,
	from_position: Vector2 = Vector2.INF,
	npc_node: Node = null
) -> Array[Vector2]:
	if (
		request_npc_shelf_access_state(shelf, true)
		!= StoreShelfAccessCoordinator.READY
	):
		return []

	var service_route: Array[Vector2] = []
	var service := get_navigation_service()
	if service != null:
		service_route = service.plan_to_shelf(
			shelf,
			from_position,
			npc_node
		)

	var route_policy := _get_shelf_route_policy()
	if (
		not service_route.is_empty()
		and (
			route_policy == null
			or not route_policy.route_crosses_checkout_frontage(
				from_position,
				service_route
			)
		)
	):
		return service_route

	var graph_route: Array[Vector2] = []
	var graph := get_store_path_graph()
	if graph != null:
		graph_route = graph.get_route_to_shelf_access(
			shelf,
			from_position,
			npc_node
		)

	if service_route.is_empty():
		return graph_route
	if graph_route.is_empty() or route_policy == null:
		return service_route
	return route_policy.choose_preferred_route(
		from_position,
		service_route,
		graph_route
	)


func get_store_path_graph() -> StorePathGraph:
	var store_node: Node2D = store as Node2D
	if store_node == null:
		return null

	var marker_root: Node2D = store.store_path_markers as Node2D
	if marker_root == null:
		return null

	var needs_runtime_graph: bool = (
		store._store_path_graph == null
		or store._store_path_graph.get_script() != StrictPathGraphScript
	)
	if needs_runtime_graph:
		store._store_path_graph = StrictPathGraphScript.new(
			store_node,
			marker_root
		)
	else:
		store._store_path_graph.setup(store_node, marker_root)

	if not _anchors_initialized:
		_navigation_anchors = store._get_shelf_placement_grid_positions()
		_anchors_initialized = true
	store._store_path_graph.set_shelf_access_points(_navigation_anchors)

	var layout_signature: String = _get_shelf_layout_signature()
	var layout_changed: bool = (
		_has_shelf_layout_signature
		and layout_signature != _last_shelf_layout_signature
	)
	if (
		layout_changed
		and not needs_runtime_graph
		and store._store_path_graph.has_method("invalidate_dynamic_navigation")
	):
		store._store_path_graph.call("invalidate_dynamic_navigation")

	_last_shelf_layout_signature = layout_signature
	_has_shelf_layout_signature = true
	_ensure_shelf_access_coordinator(store._store_path_graph)
	if layout_changed and _shelf_access_coordinator != null:
		_shelf_access_coordinator.invalidate_all(false)
	_ensure_navigation_service(store._store_path_graph, _navigation_anchors)
	return store._store_path_graph


func _ensure_navigation_service(
	graph: StorePathGraph,
	anchors: Array[Vector2]
) -> void:
	var store_node: Node2D = store as Node2D
	if store_node == null or graph == null:
		return
	var marker_root: Node2D = store.store_path_markers as Node2D
	if marker_root == null:
		return
	if (
		_navigation_service == null
		or _navigation_service.get_script() != StrictNavigationServiceScript
	):
		_navigation_service = StrictNavigationServiceScript.new()
	_navigation_service.setup(
		store_node,
		marker_root,
		graph,
		anchors
	)


func _ensure_shelf_access_coordinator(graph: StorePathGraph) -> void:
	var store_node: Node2D = store as Node2D
	if store_node == null or graph == null:
		return
	if _shelf_access_coordinator == null:
		_shelf_access_coordinator = ShelfAccessCoordinatorScript.new()
	_shelf_access_coordinator.setup(store_node, graph)


func _get_shelf_route_policy() -> StoreShelfRoutePolicy:
	if store == null:
		return null
	var marker_root: Node2D = store.store_path_markers as Node2D
	if marker_root == null:
		return null
	if _shelf_route_policy == null:
		_shelf_route_policy = (
			ShelfRoutePolicyScript.new() as StoreShelfRoutePolicy
		)
	_shelf_route_policy.setup(marker_root)
	return _shelf_route_policy
