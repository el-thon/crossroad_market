class_name StoreRuntimeSemanticGraph
extends "res://scripts/navigation/store/StoreSemanticGraph.gd"


func get_edge_cost(
	from_node: StringName,
	to_node: StringName,
	context: Dictionary = {}
) -> float:
	var blocked_variant: Variant = context.get("blocked_edges", {})
	if blocked_variant is Dictionary:
		var blocked_edges := blocked_variant as Dictionary
		if blocked_edges.has(make_edge_key(from_node, to_node)):
			return INF
	return super.get_edge_cost(from_node, to_node, context)


func make_edge_key(
	from_node: StringName,
	to_node: StringName
) -> String:
	var first := String(from_node)
	var second := String(to_node)
	if first > second:
		var swap := first
		first = second
		second = swap
	return "%s<->%s" % [first, second]
