extends "res://scripts/npc/runtime/NPCStableShelfStateFlow.gd"


func finish_checkout_and_exit() -> void:
	# The exit lane must reflect the queue at checkout completion, not the
	# snapshot taken when this NPC first started moving toward the cashier.
	# A customer may join while the checkout dialog is still running.
	_capture_solo_checkout_fallback()
	super.finish_checkout_and_exit()
