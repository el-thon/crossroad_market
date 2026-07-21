class_name NPCMovement
extends RefCounted


static func move_to(npc: CharacterBody2D, target: Vector2, speed: float, arrival_threshold: float) -> bool:
	if npc == null:
		return true

	@warning_ignore("unused_variable", "shadowed_variable", "incompatible_ternary")
	var distance := npc.global_position.distance_to(target)

	if distance <= arrival_threshold:
		npc.velocity = Vector2.ZERO
		npc.move_and_slide()
		return true

	npc.velocity = npc.global_position.direction_to(target) * speed
	npc.move_and_slide()
	return false


static func move_to_orthogonal(
	npc: CharacterBody2D,
	target: Vector2,
	speed: float,
	arrival_threshold: float,
	preferred_axis: Vector2
) -> bool:
	if npc == null:
		return true

	var delta: Vector2 = target - npc.global_position

	if (
		absf(delta.x) <= arrival_threshold
		and absf(delta.y) <= arrival_threshold
	):
		npc.velocity = Vector2.ZERO
		npc.move_and_slide()
		return true

	var axis: Vector2 = preferred_axis
	if axis == Vector2.ZERO:
		axis = Vector2.RIGHT if absf(delta.x) >= absf(delta.y) else Vector2.DOWN

	if axis.x != 0.0 and absf(delta.x) > arrival_threshold:
		npc.velocity = Vector2(signf(delta.x) * speed, 0.0)
	elif axis.y != 0.0 and absf(delta.y) > arrival_threshold:
		npc.velocity = Vector2(0.0, signf(delta.y) * speed)
	elif absf(delta.x) > arrival_threshold:
		npc.velocity = Vector2(signf(delta.x) * speed, 0.0)
	else:
		npc.velocity = Vector2(0.0, signf(delta.y) * speed)

	npc.move_and_slide()
	return false
