extends Node

signal trust_changed(npc_id: String, new_trust: int, delta: int)

const MIN_TRUST: int = 0
const MAX_TRUST: int = 100

var _trust_by_npc: Dictionary[String, int] = {}


func set_trust(npc_id: String, value: int) -> void:
	if npc_id == "":
		return

	var previous := get_trust(npc_id)
	var next_value := clampi(value, MIN_TRUST, MAX_TRUST)

	if previous == next_value:
		return

	_trust_by_npc[npc_id] = next_value
	trust_changed.emit(npc_id, next_value, next_value - previous)


func add_trust(npc_id: String, amount: int) -> void:
	if amount == 0:
		return

	set_trust(npc_id, get_trust(npc_id) + amount)


func get_trust(npc_id: String) -> int:
	return int(_trust_by_npc.get(npc_id, 0))


func get_all_trust() -> Dictionary[String, int]:
	return _trust_by_npc.duplicate()


func reset_trust() -> void:
	_trust_by_npc.clear()
