extends CharacterBody2D

@export var speed: float = 150.0
@export var interaction_distance: float = 20.0

@onready var interaction_area: Area2D = $InteractionArea

var facing_direction: Vector2 = Vector2.DOWN
var _discovered_ghost_shelf: bool = false
var _supply_box_cursor: int = 0
var _wrong_shelf_attempts: Dictionary = {}

const MAX_WRONG_ATTEMPTS: int = 3


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	_update_interaction_area_position()


func _physics_process(_delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if input_dir != Vector2.ZERO:
		facing_direction = input_dir.normalized()
		_update_interaction_area_position()

	velocity = input_dir * speed
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()


func _update_interaction_area_position() -> void:
	if interaction_area == null:
		return

	interaction_area.position = facing_direction * interaction_distance


func _try_interact() -> void:
	var areas: Array[Area2D] = interaction_area.get_overlapping_areas()

	if areas.is_empty():
		return

	var best_target: Node = null
	var best_priority: int = 999
	var best_distance: float = INF

	for area in areas:
		var parent: Node = area.get_parent()

		if parent == null:
			continue

		var priority: int = _get_interaction_priority(parent)

		if priority == 999:
			continue

		var distance: float = global_position.distance_squared_to(area.global_position)

		if priority < best_priority:
			best_target = parent
			best_priority = priority
			best_distance = distance
		elif priority == best_priority and distance < best_distance:
			best_target = parent
			best_distance = distance

	if best_target == null:
		return

	if best_target is NPC:
		_interact_with_npc(best_target as NPC)
		return

	if best_target is Cashier:
		_interact_with_cashier(best_target as Cashier)
		return

	if best_target is SupplyBox:
		_interact_with_supply_box(best_target as SupplyBox)
		return

	if best_target is Shelf:
		_interact_with_shelf(best_target as Shelf)
		return


func _get_interaction_priority(target: Node) -> int:
	if target is NPC:
		return 0

	if target is Cashier:
		return 1

	if target is SupplyBox:
		return 2

	if target is Shelf:
		return 3

	return 999


func _interact_with_npc(npc: NPC) -> void:
	if npc.current_state != NPC.State.CHECKOUT:
		return

	var item_id: String = npc.item_to_buy
	var item: ItemData = ItemDatabase.get_item(item_id)

	npc.complete_checkout()

	if item != null:
		_show_notification("Checked out: %s" % item.display_name)


func _interact_with_shelf(shelf: Shelf) -> void:
	var inventory_items: Dictionary = Inventory.get_all()

	if inventory_items.is_empty():
		_show_notification("Inventory is empty.")
		return

	var item_id: String = str(inventory_items.keys()[0])
	var item: ItemData = ItemDatabase.get_item(item_id)

	if item == null:
		return

	var result: int = shelf.place_item(item_id)

	if result >= 0:
		_wrong_shelf_attempts.erase(_get_wrong_shelf_key(item_id, shelf))

		_show_notification("Placed %s on the shelf." % item.display_name)

		if item.shelf_type != ItemData.ShelfType.GHOST:
			_notify_human_item_placed()

		if shelf.shelf_type == ItemData.ShelfType.GHOST and not _discovered_ghost_shelf:
			_discovered_ghost_shelf = true
			await _show_notification_sequence([
				"Huh... so it only stays on this shelf?",
				"This shelf looks different too...",
				"What was Grandma keeping here?"
			])

		return

	if item.shelf_type != shelf.shelf_type:
		_handle_wrong_shelf_attempt(item_id, item, shelf)
	else:
		_show_notification("Could not place %s on this shelf." % item.display_name)


func _handle_wrong_shelf_attempt(
	item_id: String,
	item: ItemData,
	shelf: Shelf
) -> void:
	var attempt_key: String = _get_wrong_shelf_key(item_id, shelf)
	var attempts: int = int(_wrong_shelf_attempts.get(attempt_key, 0))

	if attempts >= MAX_WRONG_ATTEMPTS:
		return

	attempts += 1
	_wrong_shelf_attempts[attempt_key] = attempts

	if attempts >= MAX_WRONG_ATTEMPTS:
		await _show_notification_sequence([
			"Huh? It keeps falling off from the shelf...",
			"Maybe I should try the other shelf..."
		])
	else:
		_show_notification(
			"The item fell off the shelf... (%d/%d)" %
			[attempts, MAX_WRONG_ATTEMPTS]
		)


func _get_wrong_shelf_key(item_id: String, shelf: Shelf) -> String:
	return "%s_%s" % [item_id, str(shelf.get_instance_id())]


func _interact_with_supply_box(box: SupplyBox) -> void:
	var available: Array = box.get_available_items()

	if available.is_empty():
		_show_notification("This box is already empty.")
		return

	_supply_box_cursor = _supply_box_cursor % available.size()

	var item_id: String = str(available[_supply_box_cursor])

	if box.collect_one(item_id):
		var item: ItemData = ItemDatabase.get_item(item_id)

		if item != null:
			_show_pickup_notification(item.display_name)
		else:
			_show_pickup_notification(item_id)

		if not (box is MysterySupplyBox):
			_notify_mystery_taken()

	if available.size() > 0:
		_supply_box_cursor = (_supply_box_cursor + 1) % available.size()
	else:
		_supply_box_cursor = 0


func _notify_mystery_taken() -> void:
	var world: Node = get_tree().get_first_node_in_group("world")

	if world == null:
		return

	if world.has_method("on_normal_item_taken"):
		world.on_normal_item_taken()


func _notify_human_item_placed() -> void:
	var world: Node = get_tree().get_first_node_in_group("world")

	if world == null:
		return

	if world.has_method("on_human_item_placed"):
		world.on_human_item_placed()


func _show_pickup_notification(item_name: String) -> void:
	_show_notification("+ %s" % item_name)


func _show_notification(text: String, duration: float = 2.0) -> void:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null:
		return

	if hud.has_method("show_notification"):
		hud.call("show_notification", text, duration)


func _show_notification_sequence(messages: Array[String]) -> void:
	for message in messages:
		_show_notification(message, 2.5)
		await get_tree().create_timer(2.65).timeout


func _interact_with_cashier(cashier: Cashier) -> void:
	cashier.try_checkout()
