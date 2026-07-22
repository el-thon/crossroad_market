class_name CashierConversationResolver
extends RefCounted

const CONVERSATION_ROOT := "res://data/cashier/conversations"


static func get_conversation(day: int, customer_id: String) -> CashierConversationData:
	var normalized_customer_id := customer_id.strip_edges().to_lower()
	if (
		day < 1
		or normalized_customer_id.is_empty()
		or normalized_customer_id.contains("/")
		or normalized_customer_id.contains("\\")
		or normalized_customer_id.contains("..")
	):
		return null

	var resource_path := "%s/day_%d/%s.tres" % [
		CONVERSATION_ROOT,
		day,
		normalized_customer_id,
	]
	if not ResourceLoader.exists(resource_path):
		return null

	var conversation := load(resource_path) as CashierConversationData
	if conversation == null:
		return null
	if conversation.day != day or conversation.customer_id != normalized_customer_id:
		push_warning(
			"Cashier conversation metadata does not match its path: %s" % resource_path
		)
		return null
	return conversation
