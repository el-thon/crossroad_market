extends "res://scripts/npc/runtime/NPCShoppingFlow.gd"


func choose_available_item_to_buy() -> void:
	if npc.npc_data == null:
		return

	# Story customers keep their scripted shopping list and favorite behavior.
	# Generic customers choose from stock that is physically available and
	# reachable when they enter the store.
	if npc.npc_data.npc_category != NPCData.NPCCategory.GENERIC:
		super.choose_available_item_to_buy()
		return

	var available_item_ids := _get_available_generic_item_ids()
	if available_item_ids.is_empty():
		return

	var selected_index := randi_range(0, available_item_ids.size() - 1)
	set_requested_item(available_item_ids[selected_index])


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
		if not _ensure_shelf_path_ready(shelf):
			continue

		if shelf.has_item(npc.item_to_buy):
			stocked_shelves.append(shelf)
		else:
			fallback_shelves.append(shelf)

	stocked_shelves.append_array(fallback_shelves)
	return stocked_shelves


func _get_available_generic_item_ids() -> Array[String]:
	var available_item_ids: Array[String] = []
	var target_shelf_type := ItemData.ShelfType.HUMAN

	if npc.npc_data.visit_phase == NPCData.VisitPhase.NIGHT:
		target_shelf_type = ItemData.ShelfType.GHOST

	for shelf_node in npc.get_tree().get_nodes_in_group("shelves"):
		var shelf := shelf_node as Shelf

		if shelf == null or not is_instance_valid(shelf):
			continue
		if shelf.shelf_type != target_shelf_type:
			continue
		if (
			shelf.has_meta("is_carried_storage_object")
			and bool(shelf.get_meta("is_carried_storage_object"))
		):
			continue
		if not _ensure_shelf_path_ready(shelf):
			continue

		for slot_index in shelf.max_slots:
			var item_id: String = shelf.get_slot_content(slot_index)
			if item_id == "" or item_id in available_item_ids:
				continue

			var item: ItemData = ItemDatabase.get_item(item_id)
			if item == null or item.shelf_type != target_shelf_type:
				continue

			available_item_ids.append(item_id)

	return available_item_ids


func _ensure_shelf_path_ready(shelf: Shelf) -> bool:
	if shelf == null or not is_instance_valid(shelf):
		return false

	if bool(shelf.get_meta("npc_path_ready", false)):
		return get_shelf_visit_position(shelf).is_finite()

	var store: Node = npc._get_store_route_provider()
	if store == null or not store.has_method("_get_store_path_graph"):
		return false

	var graph_variant: Variant = store.call("_get_store_path_graph")
	if not (graph_variant is StorePathGraph):
		return false

	var graph := graph_variant as StorePathGraph
	graph.store_shelf_access_metadata(shelf, shelf.global_position)

	return (
		bool(shelf.get_meta("npc_path_ready", false))
		and get_shelf_visit_position(shelf).is_finite()
	)
