extends "res://scripts/npc/runtime/NPCShoppingFlow.gd"


func get_matching_shelf_candidates() -> Array[Shelf]:
	var stocked_shelves: Array[Shelf] = []
	var fallback_shelves: Array[Shelf] = []
	var item: ItemData = ItemDatabase.get_item(npc.item_to_buy)

	if item == null:
		return []

	for shelf_node in npc.get_tree().get_nodes_in_group("shelves"):
		var shelf := shelf_node as Shelf

		if shelf == null or not is_instance_valid(shelf):
			continue
		if shelf.shelf_type != item.shelf_type:
			continue

		# Shelf access metadata can be cleared while the shelf is carried and may
		# still be pending when a customer session begins. Refresh it on demand
		# before excluding the shelf from shopping candidates.
		var path_ready := bool(shelf.get_meta("npc_path_ready", false))
		if not path_ready:
			var refreshed_visit_position: Vector2 = get_shelf_visit_position(shelf)
			path_ready = refreshed_visit_position.is_finite()

		if not path_ready:
			continue

		if shelf.has_item(npc.item_to_buy):
			stocked_shelves.append(shelf)
		else:
			fallback_shelves.append(shelf)

	stocked_shelves.append_array(fallback_shelves)
	return stocked_shelves
