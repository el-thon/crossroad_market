class_name CashierCheckoutHistory
extends RefCounted


static func add_entry(history: Array[Dictionary], npc: NPC, item_label: String, total: int, status: String) -> void:
	history.append({
		"day": TimeManager.current_day,
		"time": TimeManager.get_time_display(),
		"npc": npc.npc_data.display_name if npc != null and npc.npc_data != null else "Customer",
		"items": item_label,
		"total": total,
		"status": status
	})

	if history.size() > 20:
		history.pop_front()
