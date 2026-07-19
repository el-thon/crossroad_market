extends "res://scripts/locations/store/StoreShelfPlacementController.gd"

const QUEUE_DROP_BLOCK_ROLES: Array[StringName] = [
	&"queue_front",
	&"queue_back",
	&"queue_front_right",
	&"queue_back_right",
	&"queue_exit_right"
]


func evaluate_shelf_drop_restriction(
	object: Node2D,
	candidate: Vector2
) -> Dictionary:
	var object_rect := get_object_body_rect_at(object, candidate)
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

	return make_drop_restriction()


func get_queue_drop_block_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []

	if store == null or store.store_path_markers == null:
		return markers

	for child in store.store_path_markers.get_children():
		var marker := child as Marker2D
		if marker == null or not marker.has_meta("store_path_role"):
			continue

		var role := StringName(str(marker.get_meta("store_path_role")))
		if role in QUEUE_DROP_BLOCK_ROLES:
			markers.append(marker)

	return markers
