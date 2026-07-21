extends "res://scripts/locations/store/StoreShelfPlacementController.gd"

const STORE_ENTRY_DROP_BLOCK_ROLES: Array[StringName] = [
	&"entry_exit",
	&"entry",
	&"exit",
	&"enter_store"
]
const QUEUE_DROP_BLOCK_ROLES: Array[StringName] = [
	&"queue_front",
	&"queue_back",
	&"queue_front_right",
	&"queue_back_right",
	&"queue_exit_right"
]
const STORE_ENTRY_DROP_BLOCK_SIZE := Vector2(88, 56)
const SHELF_ACCESS_GAP: float = 10.0
const SHELF_APPROACH_DISTANCE: float = 18.0
const NPC_HALF_HEIGHT_FALLBACK: float = 8.0
const SHELF_ACCESS_CORRIDOR_WIDTH: float = 16.0
const STORE_MIN_Y: float = 72.0
const STORE_MAX_Y: float = 246.0


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func evaluate_shelf_drop_restriction(
	object: Node2D,
	candidate: Vector2
) -> Dictionary:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var object_rect := get_object_body_rect_at(object, candidate)
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var entrance_restricted_rect := get_marker_drop_restricted_rect(
		object_rect,
		STORE_ENTRY_DROP_BLOCK_ROLES,
		STORE_ENTRY_DROP_BLOCK_SIZE
	)

	if rect_has_area(entrance_restricted_rect):
		return make_drop_restriction(
			true,
			DROP_REJECTION_CASHIER_FLOW,
			"Keep the store entrance clear.",
			entrance_restricted_rect,
			true
		)

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var queue_restricted_rect := get_queue_marker_drop_restricted_rect(
		object_rect
	)

	if rect_has_area(queue_restricted_rect):
		return make_drop_restriction(
			true,
			DROP_REJECTION_CASHIER_FLOW,
			"Keep the customer queue path clear.",
			queue_restricted_rect,
			true
		)

	if not is_drop_position_clear(object, candidate):
		return make_drop_restriction(
			true,
			DROP_REJECTION_COLLISION,
			"I can't place the shelf on another object.",
			object_rect,
			false
		)

	if not has_valid_shelf_access_after_drop(object, candidate):
		return make_drop_restriction(
			true,
			DROP_REJECTION_COLLISION,
			"Keep at least one customer access side clear.",
			object_rect,
			true
		)

	return make_drop_restriction()


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_queue_drop_block_markers() -> Array[Marker2D]:
	return get_drop_block_markers_for_roles(QUEUE_DROP_BLOCK_ROLES)


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_marker_drop_restricted_rect(
	object_rect: Rect2,
	roles: Array[StringName],
	block_size: Vector2
) -> Rect2:
	for marker in get_drop_block_markers_for_roles(roles):
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var marker_rect := Rect2(
			marker.global_position - block_size * 0.5,
			block_size
		)

		if object_rect.intersects(marker_rect):
			return marker_rect

	return Rect2()


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func get_drop_block_markers_for_roles(
	roles: Array[StringName]
) -> Array[Marker2D]:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var markers: Array[Marker2D] = []

	if store == null or store.store_path_markers == null:
		return markers

	for child in store.store_path_markers.get_children():
		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		@warning_ignore("shadowed_variable", "shadowed_variable_base_class")
		var marker_node := child as Marker2D
		if marker_node == null or not marker_node.has_meta("store_path_role"):
			continue

		@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
		var role := StringName(str(marker_node.get_meta("store_path_role")))
		if role in roles:
			markers.append(marker_node)

	return markers


@warning_ignore("unused_parameter", "shadowed_variable", "shadowed_variable_base_class")
func has_valid_shelf_access_after_drop(
	object: Node2D,
	candidate: Vector2
) -> bool:
	var candidate_rect := get_object_body_rect_at(object, candidate)

	if not _has_clear_access_corridor_for_rect(candidate_rect, object, Rect2()):
		return false

	for shelf_variant in store.get_tree().get_nodes_in_group("shelves"):
		var shelf := shelf_variant as Shelf
		if shelf == null or shelf == object:
			continue
		if not StoreShelfController.is_descendant_of(shelf, store):
			continue
		if bool(shelf.get_meta("is_carried_storage_object", false)):
			continue
		if _would_block_last_shelf_access(shelf, candidate_rect):
			return false

	return true


func _would_block_last_shelf_access(shelf: Shelf, candidate_rect: Rect2) -> bool:
	var shelf_rect := _get_shelf_body_rect(shelf)
	if not _has_clear_access_corridor_for_rect(shelf_rect, shelf, Rect2()):
		return false

	return not _has_clear_access_corridor_for_rect(
		shelf_rect,
		shelf,
		candidate_rect
	)


func _has_clear_access_corridor_for_rect(
	shelf_rect: Rect2,
	ignored_node: Node2D,
	extra_blocker: Rect2
) -> bool:
	for corridor in _get_shelf_access_corridors(shelf_rect):
		if _is_shelf_access_corridor_clear(corridor, ignored_node, extra_blocker):
			return true

	return false


func _get_shelf_access_corridors(shelf_rect: Rect2) -> Array[Rect2]:
	var center_x: float = shelf_rect.get_center().x
	var bottom_access := Vector2(
		center_x,
		shelf_rect.end.y + NPC_HALF_HEIGHT_FALLBACK + SHELF_ACCESS_GAP
	)
	var top_access := Vector2(
		center_x,
		shelf_rect.position.y - NPC_HALF_HEIGHT_FALLBACK - SHELF_ACCESS_GAP
	)
	return [
		_get_access_corridor_rect(
			bottom_access + Vector2(0.0, SHELF_APPROACH_DISTANCE),
			bottom_access
		),
		_get_access_corridor_rect(
			top_access - Vector2(0.0, SHELF_APPROACH_DISTANCE),
			top_access
		)
	]


func _is_shelf_access_corridor_clear(
	corridor: Rect2,
	ignored_node: Node2D,
	extra_blocker: Rect2
) -> bool:
	if not corridor.has_area():
		return false
	if corridor.position.y < STORE_MIN_Y or corridor.end.y > STORE_MAX_Y:
		return false
	if extra_blocker.has_area() and corridor.intersects(extra_blocker):
		return false

	for shelf_variant in store.get_tree().get_nodes_in_group("shelves"):
		var shelf := shelf_variant as Shelf
		if shelf == null:
			continue
		if shelf == ignored_node:
			continue
		if StoreShelfController.is_descendant_of(shelf, ignored_node):
			continue
		if not StoreShelfController.is_descendant_of(shelf, store):
			continue
		if bool(shelf.get_meta("is_carried_storage_object", false)):
			continue
		if corridor.intersects(_get_shelf_body_rect(shelf)):
			return false

	return true


func _get_shelf_body_rect(shelf: Shelf) -> Rect2:
	var collision_shape := get_object_collision_shape(shelf)
	if collision_shape == null:
		return Rect2(shelf.global_position - Vector2(32.0, 24.0), Vector2(64.0, 24.0))

	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle == null:
		return Rect2(shelf.global_position - Vector2(32.0, 24.0), Vector2(64.0, 24.0))

	return Rect2(collision_shape.global_position - rectangle.size * 0.5, rectangle.size)


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
	if size.x < SHELF_ACCESS_CORRIDOR_WIDTH:
		min_position.x -= SHELF_ACCESS_CORRIDOR_WIDTH * 0.5
		size.x = SHELF_ACCESS_CORRIDOR_WIDTH
	if size.y < SHELF_ACCESS_CORRIDOR_WIDTH:
		min_position.y -= SHELF_ACCESS_CORRIDOR_WIDTH * 0.5
		size.y = SHELF_ACCESS_CORRIDOR_WIDTH
	return Rect2(min_position, size)
