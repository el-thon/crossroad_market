class_name PersistentStorage
extends "res://scripts/locations/Storage.gd"

const STORED_IN_STORAGE_META: StringName = &"stored_in_storage"
const STORAGE_POSITION_META: StringName = &"stored_storage_position"


func _ready() -> void:
	super._ready()
	_restore_persisted_store_shelves()
	# The base _ready() connected signals before persisted shelves were restored.
	# Re-run the guarded connection pass so a restored Ghost Shelf emits its
	# storage placement events normally.
	_connect_signals()


func prepare_for_scene_exit() -> void:
	var store := _get_store()
	if store == null:
		return

	_park_store_shelf(store, store.get("human_shelf") as Shelf)
	_park_store_shelf(store, store.get("ghost_shelf") as Shelf)


func _restore_persisted_store_shelves() -> void:
	var store := _get_store()
	if store == null:
		return

	var persisted_human := store.get("human_shelf") as Shelf
	if _can_restore_shelf(store, persisted_human):
		if shelf_human != null and shelf_human != persisted_human:
			shelf_human.queue_free()
		shelf_human = persisted_human
		_restore_shelf_to_storage(persisted_human)

	var persisted_ghost := store.get("ghost_shelf") as Shelf
	if _can_restore_shelf(store, persisted_ghost):
		if shelf_ghost != null and shelf_ghost != persisted_ghost:
			shelf_ghost.queue_free()
		shelf_ghost = persisted_ghost
		_restore_shelf_to_storage(persisted_ghost)


func _can_restore_shelf(store: Node, shelf: Shelf) -> bool:
	if shelf == null or not is_instance_valid(shelf):
		return false
	if shelf.get_parent() != store:
		return false
	if not bool(shelf.get_meta(STORED_IN_STORAGE_META, false)):
		return false
	if bool(shelf.get_meta("is_installed_in_store", false)):
		return false
	if bool(shelf.get_meta("is_carried_storage_object", false)):
		return false
	return true


func _restore_shelf_to_storage(shelf: Shelf) -> void:
	var shelf_root := get_node_or_null("StorageShelves")
	if shelf_root == null:
		shelf_root = self

	var saved_position := shelf.global_position
	var saved_variant: Variant = shelf.get_meta(
		STORAGE_POSITION_META,
		saved_position
	)
	if saved_variant is Vector2:
		saved_position = saved_variant as Vector2

	shelf.reparent(shelf_root, true)
	shelf.global_position = saved_position
	shelf.z_index = 0
	shelf.visible = true
	shelf.set_meta("is_carried_storage_object", false)
	shelf.set_meta("is_installed_in_store", false)
	shelf.set_meta("is_carryable_storage_object", true)
	shelf.set_meta(STORED_IN_STORAGE_META, true)
	shelf.remove_from_group("shelves")
	_set_node_enabled_recursive(shelf, true)


func _park_store_shelf(store: Node, shelf: Shelf) -> void:
	if shelf == null or not is_instance_valid(shelf):
		return
	if not _is_descendant_of(shelf, self):
		return
	if _player != null and _is_descendant_of(shelf, _player):
		return

	shelf.set_meta(STORAGE_POSITION_META, shelf.global_position)
	shelf.set_meta(STORED_IN_STORAGE_META, true)
	shelf.set_meta("is_carried_storage_object", false)
	shelf.set_meta("is_installed_in_store", false)
	shelf.remove_from_group("shelves")
	shelf.reparent(store, true)
	shelf.visible = false
	shelf.z_index = 0
	_set_node_enabled_recursive(shelf, false)


func _get_store() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("store")


func _is_descendant_of(node: Node, ancestor: Node) -> bool:
	var current := node
	while current != null:
		if current == ancestor:
			return true
		current = current.get_parent()
	return false
