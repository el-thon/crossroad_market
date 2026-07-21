class_name NPCMovementReservationSystem
extends RefCounted


const CELL_SIZE: float = 16.0

static var _reservations: Dictionary = {}


static func reserve_next_position(npc: Node, position: Vector2) -> bool:
	if npc == null or not is_instance_valid(npc) or not position.is_finite():
		return false

	prune_invalid()
	var key: Vector2i = _position_key(position)
	var owner_id: int = int(_reservations.get(key, 0))
	var npc_id: int = npc.get_instance_id()

	if owner_id != 0 and owner_id != npc_id:
		return false

	if _is_position_occupied_by_other(npc, key):
		return false

	release_for(npc)
	_reservations[key] = npc_id
	npc.set_meta(&"npc_movement_reservation_key", key)
	return true


static func get_blocking_context(npc: Node, position: Vector2) -> Dictionary:
	if npc == null or not is_instance_valid(npc) or not position.is_finite():
		return {"blocked": true, "reason": "invalid_request"}

	prune_invalid()
	var key: Vector2i = _position_key(position)
	var owner_id: int = int(_reservations.get(key, 0))
	var npc_id: int = npc.get_instance_id()
	if owner_id != 0 and owner_id != npc_id:
		return {
			"blocked": true,
			"reason": "reserved",
			"cell": _format_cell(key),
			"owner_id": owner_id
		}

	var actor_context := _get_occupying_actor_context(npc, key)
	if bool(actor_context.get("blocked", false)):
		return actor_context

	return {
		"blocked": false,
		"reason": "clear",
		"cell": _format_cell(key)
	}


static func release_for(npc: Node) -> void:
	if npc == null or not is_instance_valid(npc):
		return

	if not npc.has_meta(&"npc_movement_reservation_key"):
		return

	var key_variant: Variant = npc.get_meta(&"npc_movement_reservation_key")
	if key_variant is Vector2i:
		var key := key_variant as Vector2i
		if int(_reservations.get(key, 0)) == npc.get_instance_id():
			_reservations.erase(key)

	npc.remove_meta(&"npc_movement_reservation_key")


static func prune_invalid() -> void:
	var live_owner_ids: Dictionary = {}
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		for npc_node in tree.get_nodes_in_group("npcs"):
			if npc_node != null and is_instance_valid(npc_node):
				live_owner_ids[npc_node.get_instance_id()] = true

	for key in _reservations.keys():
		var owner_id: int = int(_reservations[key])
		if not live_owner_ids.has(owner_id):
			_reservations.erase(key)


static func _position_key(position: Vector2) -> Vector2i:
	return Vector2i(
		roundi(position.x / CELL_SIZE),
		roundi(position.y / CELL_SIZE)
	)


static func _is_position_occupied_by_other(npc: Node, key: Vector2i) -> bool:
	return bool(_get_occupying_actor_context(npc, key).get("blocked", false))


static func _get_occupying_actor_context(npc: Node, key: Vector2i) -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return {"blocked": false, "reason": "clear", "cell": _format_cell(key)}

	var npc_id: int = npc.get_instance_id()
	for npc_node in tree.get_nodes_in_group("npcs"):
		if npc_node == null or not is_instance_valid(npc_node):
			continue

		if npc_node.get_instance_id() == npc_id:
			continue

		if not (npc_node is Node2D):
			continue

		var other_node := npc_node as Node2D
		if _position_key(other_node.global_position) == key:
			return {
				"blocked": true,
				"reason": "occupied",
				"cell": _format_cell(key),
				"owner_id": npc_node.get_instance_id(),
				"owner_name": String(npc_node.name),
				"owner_position": _format_vector(other_node.global_position)
			}

	return {"blocked": false, "reason": "clear", "cell": _format_cell(key)}


static func _format_cell(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func _format_vector(value: Vector2) -> String:
	return "%.1f,%.1f" % [value.x, value.y]
