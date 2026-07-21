class_name ShelfItemIndex
extends RefCounted


static var _shelves_by_item: Dictionary = {}


static func register_shelf_item(shelf: Shelf, item_id: String) -> void:
	if shelf == null or not is_instance_valid(shelf) or item_id == "":
		return

	var shelves: Array = _shelves_by_item.get(item_id, [])
	if shelf not in shelves:
		shelves.append(shelf)
	_shelves_by_item[item_id] = shelves


static func unregister_shelf_item(shelf: Shelf, item_id: String) -> void:
	if item_id == "" or not _shelves_by_item.has(item_id):
		return

	var shelves: Array = _shelves_by_item[item_id]
	shelves.erase(shelf)
	if shelves.is_empty():
		_shelves_by_item.erase(item_id)
	else:
		_shelves_by_item[item_id] = shelves


static func get_shelves_with_item(item_id: String) -> Array[Shelf]:
	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var result: Array[Shelf] = []
	if item_id == "" or not _shelves_by_item.has(item_id):
		return result

	var shelves: Array = _shelves_by_item[item_id]
	for shelf_variant in shelves.duplicate():
		var shelf := shelf_variant as Shelf
		if (
			shelf == null
			or not is_instance_valid(shelf)
			or not shelf.is_in_group("shelves")
		):
			unregister_shelf_item(shelf, item_id)
			continue

		if shelf.has_item(item_id):
			result.append(shelf)

	return result


static func clear() -> void:
	_shelves_by_item.clear()
