extends StorePathGraphSurface
class_name StorePathGraphSurfaceGrid

## Surface-grid implementation with stable row/column topology.
##
## The previous cache builder compared every anchor with every other anchor and
## performed physics queries while constructing the cache. With 525 placement
## points this produced more than one million comparisons and could bake a
## temporary NPC/player position into the cached graph. This implementation
## groups anchors by row/column and connects only adjacent geometric neighbors.
## Collision remains evaluated dynamically by _find_surface_anchor_path().


func _ensure_surface_neighbor_cache() -> void:
	var signature: String = _graph._get_surface_points_signature(
		_graph._shelf_access_points
	)
	if _graph._surface_neighbor_signature == signature:
		return

	_graph._surface_neighbor_cache.clear()
	_graph._surface_neighbor_signature = signature

	for index in range(_graph._shelf_access_points.size()):
		_graph._surface_neighbor_cache[index] = []

	var row_buckets := _build_axis_buckets(true)
	var column_buckets := _build_axis_buckets(false)
	_connect_axis_buckets(row_buckets, true)
	_connect_axis_buckets(column_buckets, false)


func _build_axis_buckets(horizontal: bool) -> Dictionary:
	var buckets: Dictionary = {}
	for index in range(_graph._shelf_access_points.size()):
		var point: Vector2 = _graph._shelf_access_points[index]
		var axis_value := point.y if horizontal else point.x
		# Placement anchors use a stable 12px grid. Three decimals preserve exact
		# rows and columns without merging neighboring grid lines.
		var bucket_key := "%.3f" % axis_value
		var indices: Array = buckets.get(bucket_key, [])
		indices.append(index)
		buckets[bucket_key] = indices
	return buckets


func _connect_axis_buckets(
	buckets: Dictionary,
	horizontal: bool
) -> void:
	for bucket_variant in buckets.values():
		if not (bucket_variant is Array):
			continue

		var ordered_indices: Array = bucket_variant
		ordered_indices.sort_custom(func(a: Variant, b: Variant) -> bool:
			var point_a: Vector2 = _graph._shelf_access_points[int(a)]
			var point_b: Vector2 = _graph._shelf_access_points[int(b)]
			return (
				point_a.x < point_b.x
				if horizontal
				else point_a.y < point_b.y
			)
		)

		for ordered_index in range(ordered_indices.size()):
			_append_adjacent_axis_neighbor(
				ordered_indices,
				ordered_index,
				-1,
				horizontal
			)
			_append_adjacent_axis_neighbor(
				ordered_indices,
				ordered_index,
				1,
				horizontal
			)


func _append_adjacent_axis_neighbor(
	ordered_indices: Array,
	ordered_index: int,
	step: int,
	horizontal: bool
) -> void:
	var candidate_ordered_index := ordered_index + step
	if (
		candidate_ordered_index < 0
		or candidate_ordered_index >= ordered_indices.size()
	):
		return

	var source_index := int(ordered_indices[ordered_index])
	var candidate_index := int(
		ordered_indices[candidate_ordered_index]
	)
	var source_position: Vector2 = _graph._shelf_access_points[source_index]
	var candidate_position: Vector2 = _graph._shelf_access_points[
		candidate_index
	]
	var distance := (
		absf(candidate_position.x - source_position.x)
		if horizontal
		else absf(candidate_position.y - source_position.y)
	)
	if (
		distance <= _graph.SURFACE_ALIGNMENT_EPSILON
		or distance > _graph.SURFACE_NEIGHBOR_MAX_DISTANCE
	):
		return

	var neighbors: Array = _graph._surface_neighbor_cache.get(
		source_index,
		[]
	)
	if candidate_index in neighbors:
		return

	neighbors.append(candidate_index)
	_graph._surface_neighbor_cache[source_index] = neighbors
