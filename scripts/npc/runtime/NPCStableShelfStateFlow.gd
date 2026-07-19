extends "res://scripts/npc/runtime/NPCStateFlow.gd"


func _find_reachable_stocked_shelf() -> Shelf:
	var requested_items: Array[String] = npc._get_requested_items()
	var current_shelf := npc._target_shelf as Shelf
	var interaction_tolerance := maxf(
		npc.SHELF_ACTION_DISTANCE,
		npc.ARRIVAL_THRESHOLD + 2.0
	)

	# Once the NPC is already standing at its assigned shelf, do not make item
	# pickup depend on another route/access lookup. Placement metadata can be
	# refreshed after a shelf drop and briefly invalidate that lookup even
	# though the NPC and stocked shelf are already correctly aligned.
	if (
		current_shelf != null
		and is_instance_valid(current_shelf)
		and current_shelf.is_in_group("shelves")
		and npc.global_position.distance_to(npc.target_position)
		<= interaction_tolerance
		and _shelf_has_requested_stock(current_shelf, requested_items)
	):
		return current_shelf

	for shelf in npc._get_matching_shelf_candidates():
		if shelf == null or not is_instance_valid(shelf):
			continue
		if not _shelf_has_requested_stock(shelf, requested_items):
			continue

		var visit_position: Vector2 = npc._get_shelf_visit_position(shelf)
		if visit_position.is_finite():
			return shelf

	return null


func _shelf_has_requested_stock(
	shelf: Shelf,
	requested_items: Array[String]
) -> bool:
	for item_id in requested_items:
		if shelf.has_item(item_id):
			return true

	return false
