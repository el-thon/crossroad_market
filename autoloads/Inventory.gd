extends Node
signal inventory_changed(item_id: String, new_quantity: int)

var _items: Dictionary = {}

func add_item(item_id: String, amount: int = 1) -> void:
	_items[item_id] = get_quantity(item_id) + amount
	inventory_changed.emit(item_id, _items[item_id])

func remove_item(item_id: String, amount: int = 1) -> bool:
	var current: int = get_quantity(item_id)
	if current < amount:
		return false
	_items[item_id] = current - amount
	if _items[item_id] == 0:
		_items.erase(item_id)
	inventory_changed.emit(item_id, get_quantity(item_id))
	return true
	
func get_quantity(item_id: String) -> int:
	return _items.get(item_id, 0)

func has_item(item_id: String) -> bool:
	return get_quantity(item_id) > 0

func get_all() -> Dictionary:
	return _items.duplicate()
