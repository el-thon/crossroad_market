class_name StoreOrthogonalShelfRuntimeGraph
extends "res://scripts/locations/store/StoreShelfAccessRuntimeGraph.gd"

## Shelf-bound compatibility graph for axis-locked NPC movement.
##
## The general navigation service may return a single any-angle destination.
## NPCMovement executes that destination one axis at a time, so the visually
## travelled route can differ from the route that was scored by the planner.
## This graph keeps the collision-tested fallback explicit: horizontal-first
## and vertical-first L routes only.


func _append_access_route_variants(
	candidates: Array[Dictionary],
	from_position: Vector2,
	access_position: Vector2,
	shelf: Shelf,
	npc_node: Node
) -> void:
	for horizontal_first in [true, false]:
		var route := _routes.make_orthogonal_route(
			from_position,
			access_position,
			horizontal_first
		)
		if _clearance.is_route_to_access_clear(
			from_position,
			route,
			shelf,
			npc_node
		):
			_append_route_candidate(candidates, from_position, route)


func _append_clear_route_variants(
	candidates: Array[Dictionary],
	from_position: Vector2,
	target_position: Vector2,
	shelf_object: Node2D,
	shelf_position: Vector2,
	_ignore_endpoint: bool
) -> void:
	for horizontal_first in [true, false]:
		var route := _routes.make_orthogonal_route(
			from_position,
			target_position,
			horizontal_first
		)
		if _clearance.is_route_clear(
			from_position,
			route,
			shelf_object,
			shelf_position
		):
			_append_route_candidate(candidates, from_position, route)
