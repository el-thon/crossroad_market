class_name Cashier
extends StaticBody2D

@onready var interaction_area: Area2D = $InteractionArea

signal checkout_done(npc: NPC, item_id: String, price: int)

func try_checkout() -> void:
	if not _is_player_nearby():
		return

	# Find first NPC in queue ready for checkout
	var first_npc: NPC = _get_first_checkout_npc()
	if first_npc == null:
		print("No customer waiting at counter.")
		return

	_process_checkout(first_npc)

func _is_player_nearby() -> bool:
	return get_tree().get_first_node_in_group("player") != null

func _get_first_checkout_npc() -> NPC:
	for npc in NPC.current_queue:
		if npc.current_state == NPC.State.CHECKOUT:
			return npc
	return null

func _process_checkout(npc: NPC) -> void:
	var item_id := npc.item_to_buy
	var item_data: ItemData = ItemDatabase.get_item(item_id)

	if item_data == null:
		push_error("Cashier: item '%s' not found" % item_id)
		return

	var price: int = item_data.sell_price
	print("Scanning: %s — %dG" % [item_data.display_name, price])

	# Complete transaction
	EconomyManager.add_gold(price)
	npc.complete_checkout()
	checkout_done.emit(npc, item_id, price)

	print("Checkout complete: %s for %dG | Total Gold: %dG" % [item_data.display_name, price, EconomyManager.gold])
