class_name CashierCheckoutService
extends RefCounted


static func selection_matches_customer(selected_item_ids: Array[String], target_item_ids: Array[String]) -> bool:
	if selected_item_ids.size() != target_item_ids.size():
		return false

	var expected := target_item_ids.duplicate()

	for item_id in selected_item_ids:
		if item_id not in expected:
			return false

		expected.erase(item_id)

	return expected.is_empty()


static func calculate_total(item_ids: Array[String]) -> int:
	var total := 0

	for item_id in item_ids:
		var item: ItemData = ItemDatabase.get_item(item_id)

		if item != null:
			total += item.sell_price

	return total


static func get_item_label(item_ids: Array[String]) -> String:
	var labels: Array[String] = []

	for item_id in item_ids:
		var item: ItemData = ItemDatabase.get_item(item_id)
		labels.append(item.display_name if item != null else item_id)

	return ", ".join(labels)
