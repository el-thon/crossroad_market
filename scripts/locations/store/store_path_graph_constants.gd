extends RefCounted
class_name StorePathGraphConstants

## Constants for StorePathGraph
## Extracted for modularity - contains all constant definitions

const ENTRY: StringName = &"StorePathEntry"
const EXIT: StringName = &"StorePathExit"
const AISLE_RIGHT: StringName = &"StorePathAisleRight"
const CASHIER: StringName = &"StorePathCashier"
const QUEUE_FRONT: StringName = &"StorePathQueueFront"
const ACCESS_META: StringName = &"npc_access_point"
const ACCESS_NODE_META: StringName = &"npc_access_graph_node"
const ACCESS_ROUTE_META: StringName = &"npc_access_surface_route"
const ACCESS_SIDE_META: StringName = &"npc_access_side"
const ACCESS_CHECKOUT_SOURCE_META: StringName = &"npc_access_checkout_source"
const PATH_ROLE_META: StringName = &"store_path_role"
const SHELF_ANCHOR_META: StringName = &"store_path_allow_shelf_anchor"
const ROLE_ENTRY: StringName = &"entry"
const ROLE_EXIT: StringName = &"exit"
const ROLE_CASHIER: StringName = &"cashier"
const ROLE_QUEUE_FRONT: StringName = &"queue_front"
const ROLE_QUEUE_BACK: StringName = &"queue_back"
const ROLE_QUEUE_FRONT_RIGHT: StringName = &"queue_front_right"
const ROLE_QUEUE_BACK_RIGHT: StringName = &"queue_back_right"
const CHECKOUT_GOAL_ROLES: Array[StringName] = [ROLE_QUEUE_FRONT, ROLE_CASHIER]

## NPC Standing shape dimensions
const STANDING_SHAPE_SIZE := Vector2(21, 9)
const STANDING_SHAPE_OFFSET := Vector2(0, -8)

## Route sampling and clearance tolerances
const ROUTE_SAMPLE_STEP: float = 8.0
const ROUTE_CLEARANCE_EPSILON: float = 2.0
const MARKER_ALIGNMENT_EPSILON: float = 2.0

## Shelf access tolerances
const SHELF_ACCESS_COLUMN_EPSILON: float = 8.0
const SHELF_ACCESS_NEAR_COLUMN_EPSILON: float = 28.0
const MAX_SHELF_ACCESS_DISTANCE: float = 96.0
const MAX_VERTICAL_SHELF_ACCESS_DISTANCE: float = 32.0
const SHELF_ACCESS_STANDING_CLEARANCE: float = 1.0
const MAX_SHELF_ACCESS_CANDIDATES: int = 96
const MAX_ACCESS_GRAPH_NODE_CANDIDATES: int = 4

## Surface route settings
const SURFACE_CONNECTOR_LIMIT: int = 2
const MAX_SURFACE_ROUTE_SEARCHES: int = 8
const SURFACE_ALIGNMENT_EPSILON: float = 2.0
const SURFACE_NEIGHBOR_MAX_DISTANCE: float = 36.0

## Performance and debug settings
const PERF_SHELF_THRESHOLD_MSEC: float = 16.0
const DEBUG_SHELF_DISTANCE_THRESHOLD: float = 48.0
const SHELF_ACCESS_DISTANCE_SCORE_WEIGHT: float = 1000.0
const DEBUG_QUEUE_TO_CASHIER_ROUTE: bool = true
const DEBUG_SHELF_ENTRY_ROUTE: bool = true
const DEBUG_DIRECT_CHECKOUT_VERBOSE: bool = false
const DEBUG_QUEUE_GRAPH_CANDIDATES_VERBOSE: bool = false
