class_name StoreThetaStarRuntimePlanner
extends "res://scripts/navigation/store/StoreThetaStarPlanner.gd"


func _is_segment_clear(
	from_position: Vector2,
	to_position: Vector2,
	context: Dictionary,
	ignore_start: bool,
	ignore_endpoint: bool
) -> bool:
	if from_position.distance_to(to_position) <= DIRECT_EPSILON:
		return true

	var cache_key := _make_line_cache_key(
		from_position,
		to_position,
		context,
		ignore_start,
		ignore_endpoint
	)
	if _line_cache.has(cache_key):
		return bool(_line_cache[cache_key])

	var source_shelf: Shelf = null
	var source_variant: Variant = context.get("ignored_shelf", null)
	if (
		ignore_start
		and is_instance_valid(source_variant)
		and source_variant is Shelf
	):
		source_shelf = source_variant as Shelf

	var agent_margin := float(context.get("agent_radius", 10.5))
	if (
		_obstacles != null
		and _obstacles.is_segment_blocked(
			from_position,
			to_position,
			source_shelf,
			agent_margin
		)
	):
		_line_cache[cache_key] = false
		return false

	var clear := _physics_segment_clear(
		from_position,
		to_position,
		context,
		ignore_start,
		ignore_endpoint,
		source_shelf
	)
	_line_cache[cache_key] = clear
	return clear


func _physics_segment_clear(
	from_position: Vector2,
	to_position: Vector2,
	context: Dictionary,
	ignore_start: bool,
	ignore_endpoint: bool,
	ignored_shelf: Shelf
) -> bool:
	if _store == null or _store.get_world_2d() == null:
		return false
	var distance := from_position.distance_to(to_position)
	var steps := maxi(1, int(ceil(distance / ROUTE_SAMPLE_STEP)))
	var first_index := 1 if ignore_start else 0
	var last_index := steps - 1 if ignore_endpoint else steps
	if first_index > last_index:
		return true

	var standing_shape := RectangleShape2D.new()
	standing_shape.size = DEFAULT_STANDING_SIZE
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = standing_shape
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 1

	var npc_variant: Variant = context.get("npc", null)
	if is_instance_valid(npc_variant) and npc_variant is CollisionObject2D:
		query.exclude = [(npc_variant as CollisionObject2D).get_rid()]

	for index in range(first_index, last_index + 1):
		var progress := float(index) / float(steps)
		var point := from_position.lerp(to_position, progress)
		query.transform = Transform2D(0.0, point + DEFAULT_STANDING_OFFSET)
		var hits: Array[Dictionary] = (
			_store.get_world_2d().direct_space_state.intersect_shape(query, 16)
		)
		for hit in hits:
			var collider_variant: Variant = hit.get("collider", null)
			if not is_instance_valid(collider_variant):
				continue
			var collider := collider_variant as Node
			if collider == null:
				continue
			if ignored_shelf != null and _is_descendant_of(collider, ignored_shelf):
				continue
			if collider is NPC or collider.is_in_group("npcs"):
				continue
			if String(collider.name).to_lower().contains("player"):
				continue
			return false
	return true


func _make_line_cache_key(
	from_position: Vector2,
	to_position: Vector2,
	context: Dictionary,
	ignore_start: bool,
	ignore_endpoint: bool
) -> String:
	var revision := 0
	if _obstacles != null:
		revision = _obstacles.get_revision()
	var shelf_id := 0
	var shelf_variant: Variant = context.get("ignored_shelf", null)
	if (
		ignore_start
		and is_instance_valid(shelf_variant)
		and shelf_variant is Shelf
	):
		shelf_id = (shelf_variant as Shelf).get_instance_id()
	var radius_key := roundi(float(context.get("agent_radius", 10.5)) * 10.0)
	return "%d:%d,%d:%d,%d:%d:%d:%d:r%d" % [
		revision,
		roundi(from_position.x),
		roundi(from_position.y),
		roundi(to_position.x),
		roundi(to_position.y),
		shelf_id,
		int(ignore_start),
		int(ignore_endpoint),
		radius_key
	]
