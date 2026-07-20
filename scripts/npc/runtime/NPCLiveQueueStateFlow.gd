extends "res://scripts/npc/runtime/NPCStableShelfStateFlow.gd"


func finish_checkout_and_exit() -> void:
	# The exit lane must reflect the queue at checkout completion, not the
	# snapshot taken when this NPC first started moving toward the cashier.
	# A customer may join while the checkout dialog is still running.
	_capture_solo_checkout_fallback()
	super.finish_checkout_and_exit()


func _begin_wait_for_shelf(reason: String) -> void:
	super._begin_wait_for_shelf(reason)

	# Some store layouts do not define a dedicated shelf-wait marker. Never
	# leave the NPC with Vector2.INF as a movement target; wait in place instead.
	if (
		npc.current_state == NPC.State.WAIT_FOR_SHELF
		and not npc.target_position.is_finite()
	):
		npc.target_position = npc.global_position
		npc._movement_route.clear()
		npc._movement_route_destination = Vector2.INF


func process_wait_for_shelf(delta: float) -> void:
	super.process_wait_for_shelf(delta)

	# WAIT_FOR_SHELF is an intentional pause, not a movement failure. Prevent
	# the stuck watchdog from forcing the NPC into EXIT while access metadata is
	# being refreshed or the player is repositioning/restocking the shelf.
	if npc.current_state == NPC.State.WAIT_FOR_SHELF:
		npc._reset_stuck_watchdog()
