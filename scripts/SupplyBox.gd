class_name SupplyBox
extends Node2D

@export var items_to_give: Array[String] = []
@export var one_time_only: bool = true

signal items_collected(item_ids: Array[String])
signal item_taken(item_id: String)

var _already_collected: bool = false
var _collected_items: Dictionary = {}
var _all_items_taken: bool = false  # item_id → how many times collected (for non one-time)

func get_available_items() -> Array[String]:
	if one_time_only and _already_collected:
		return []
	var available: Array[String] = []
	for item_id in items_to_give:
		if not one_time_only:
			available.append(item_id)
		elif not _collected_items.has(item_id):
			available.append(item_id)
	return available

func collect() -> Array[String]:
	if one_time_only and _already_collected:
		return []

	_already_collected = true

	for item_id in items_to_give:
		Inventory.add_item(item_id)

	items_collected.emit(items_to_give)
	return items_to_give

func collect_one(item_id: String) -> bool:
	"""Collect exactly one unit of the specified item."""
	if item_id not in items_to_give:
		return false

	if one_time_only and _collected_items.has(item_id):
		return false

	Inventory.add_item(item_id)
	_collected_items[item_id] = _collected_items.get(item_id, 0) + 1
	item_taken.emit(item_id)

	if one_time_only:
		var all_done := true
		for it in items_to_give:
			if not _collected_items.has(it):
				all_done = false
				break
		if all_done:
			_already_collected = true
			_all_items_taken = true
			items_collected.emit(items_to_give)

	return true

func is_empty() -> bool:
	if not one_time_only:
		return false
	if one_time_only and _already_collected:
		return true
	for item_id in items_to_give:
		if not _collected_items.has(item_id):
			return false
	return true

func is_all_taken() -> bool:
	return _all_items_taken
