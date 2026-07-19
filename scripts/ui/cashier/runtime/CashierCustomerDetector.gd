class_name CashierCustomerDetector
extends RefCounted

const DEBUG_CASHIER_READY: bool = true

var cashier: Cashier = null


func setup(cashier_node: Cashier) -> void:
	cashier = cashier_node


func is_player_nearby() -> bool:
	if cashier.interaction_area == null:
		return false

	for body in cashier.interaction_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true

	for area in cashier.interaction_area.get_overlapping_areas():
		if area.is_in_group("player"):
			return true

		var parent: Node = area.get_parent()

		if parent != null and parent.is_in_group("player"):
			return true

	return false


func get_first_checkout_npc() -> NPC:
	NPCQueueSystem.prune_invalid(NPC.current_queue)

	if NPC.current_queue.is_empty():
		print_cashier_ready_debug(null, "empty_queue", false, false)
		return null

	var front_npc := NPC.current_queue[0]

	if not is_instance_valid(front_npc):
		print_cashier_ready_debug(front_npc, "invalid_front", false, false)
		return null

	if front_npc.has_method("is_ready_for_checkout_service"):
		var ready := bool(front_npc.call("is_ready_for_checkout_service"))
		print_cashier_ready_debug(front_npc, "checked_ready_api", ready, ready and front_npc.has_method("mark_checkout_ready"))
		if ready:
			if front_npc.has_method("mark_checkout_ready"):
				front_npc.call("mark_checkout_ready")
			return front_npc

	if front_npc.current_state != NPC.State.CHECKOUT:
		print_cashier_ready_debug(front_npc, "front_not_checkout", false, false)
		return null

	print_cashier_ready_debug(front_npc, "front_already_checkout", true, false)
	return front_npc


func has_customer_approaching_counter() -> bool:
	for npc in NPC.current_queue:
		if not is_instance_valid(npc):
			continue

		if npc.current_state == NPC.State.WAIT_IN_QUEUE or npc.current_state == NPC.State.CHECKOUT:
			return true

	return false


func print_cashier_ready_debug(front_npc: NPC, stage: String, ready: bool, will_mark_ready: bool) -> void:
	if not DEBUG_CASHIER_READY:
		return

	var queue_index := NPC.current_queue.find(front_npc) if front_npc != null else -1
	var cashier_target := Vector2.INF

	if front_npc != null and front_npc.has_method("_get_queue_target"):
		cashier_target = front_npc.target_position

	print(
		"[DEBUG][CASHIER_READY] stage=%s npc=%s state=%s queue_index=%d ready=%s will_mark_ready=%s pos=%s target=%s distance_to_target=%s moving_to_cashier=%s" % [
			stage,
			front_npc.name if front_npc != null else "<null>",
			str(front_npc.current_state) if front_npc != null else "<none>",
			queue_index,
			str(ready),
			str(will_mark_ready),
			str(front_npc.global_position if front_npc != null else Vector2.INF),
			str(cashier_target),
			str(front_npc.global_position.distance_to(cashier_target) if front_npc != null and cashier_target.is_finite() else INF),
			str(front_npc._is_moving_from_queue_to_cashier if front_npc != null else false)
		]
	)
