class_name NPC
extends CharacterBody2D

enum State {
	ENTER,
	WALK_TO_SHELF,
	SEARCH_ITEM,
	BROWSE_ITEM,
	TAKE_ITEM,
	WAIT_IN_QUEUE,
	CHECKOUT,
	EXIT
}

const SPEED: float = 80.0
const ARRIVAL_THRESHOLD: float = 5.0
const ENTER_PAUSE: float = 1.5
const DIALOG_DURATION: float = 2.5
const CHECKOUT_PATIENCE: float = 20.0
const SEARCH_PATIENCE: float = 15.0
const SHELF_VISIT_OFFSET: Vector2 = Vector2(0, 34)
const SHELF_ACTION_DISTANCE: float = 28.0
const QUEUE_ACTION_DISTANCE: float = 14.0

static var current_queue: Array[NPC] = []
static var counter_position: Vector2 = Vector2.ZERO
static var entrance_position: Vector2 = Vector2.ZERO

signal purchase_completed(npc: NPC, item_id: String, price: int)
signal npc_exited(npc: NPC)

var npc_data: NPCData
var current_state: State = State.ENTER
var target_position: Vector2 = Vector2.ZERO
var item_to_buy: String = ""
var item_to_buy_original: String = ""
var queue_position: int = 0
var shopping_list: Array[String] = []
var checkout_total_override: int = -1
var checkout_outcome: String = "paid"

var _browse_item: String = ""
var _cart_items: Array[String] = []
var _enter_pause_timer: float = 0.0
var _dialog_timer: float = 0.0
var _checkout_timer: float = 0.0
var _search_timer: float = 0.0
var _search_announced: bool = false


func _ready() -> void:
	add_to_group("dialog_skip_target")
	_set_dialog_mouse_filter()


func setup(data: NPCData) -> void:
	npc_data = data
	_apply_scripted_metadata()
	_choose_item_to_buy()
	item_to_buy_original = item_to_buy
	_apply_visual()
	_apply_name_label()
	_set_state(State.ENTER)


func _physics_process(delta: float) -> void:
	match current_state:
		State.ENTER:
			_process_enter()
		State.WALK_TO_SHELF:
			_process_walk_to_shelf()
		State.SEARCH_ITEM:
			_process_search_item(delta)
		State.BROWSE_ITEM:
			_process_browse_item(delta)
		State.TAKE_ITEM:
			_process_take_item()
		State.WAIT_IN_QUEUE:
			_process_wait_in_queue(delta)
		State.CHECKOUT:
			_process_checkout(delta)
		State.EXIT:
			_process_exit()

	_update_dialog(delta)


func complete_checkout() -> void:
	if checkout_outcome == "reject_return":
		_return_cart_items_to_shelf()
		_show_dialog("Boo...")
		_dialog_timer = DIALOG_DURATION
		_leave_queue()
		target_position = entrance_position
		_set_state(State.EXIT)
		return

	var total := get_checkout_total()

	if total > 0:
		purchase_completed.emit(self, item_to_buy, total)
		_show_dialog(BlueprintManager.get_done_dialog(self))

	_dialog_timer = DIALOG_DURATION
	_leave_queue()
	target_position = entrance_position
	_set_state(State.EXIT)


func get_checkout_total() -> int:
	if checkout_total_override >= 0:
		return checkout_total_override

	var total := 0

	for cart_item_id in _cart_items:
		var item: ItemData = ItemDatabase.get_item(cart_item_id)

		if item != null:
			total += item.sell_price

	if total > 0:
		return total

	var fallback_item: ItemData = ItemDatabase.get_item(item_to_buy)
	return fallback_item.sell_price if fallback_item != null else 0


func get_checkout_item_label() -> String:
	if _cart_items.is_empty():
		var item: ItemData = ItemDatabase.get_item(item_to_buy)
		return item.display_name if item != null else item_to_buy

	var names: Array[String] = []

	for cart_item_id in _cart_items:
		var item: ItemData = ItemDatabase.get_item(cart_item_id)
		names.append(item.display_name if item != null else cart_item_id)

	return ", ".join(names)


func get_cart_item_ids() -> Array[String]:
	if not _cart_items.is_empty():
		return _cart_items.duplicate()

	return [item_to_buy] if item_to_buy != "" else []


func repeat_checkout_request() -> void:
	_show_dialog("I'm buying %s." % get_checkout_item_label())


func skip_dialog() -> bool:
	if _dialog_timer <= 0.0:
		return false

	_dialog_timer = 0.0
	_hide_dialog()
	return true


func cancel_checkout_and_leave() -> void:
	_return_cart_items_to_shelf()
	_show_dialog("Never mind. I'll come back later.")
	_dialog_timer = DIALOG_DURATION
	_leave_queue()
	target_position = entrance_position
	_set_state(State.EXIT)


func queue_done() -> void:
	queue_free()


func _apply_name_label() -> void:
	var label := get_node_or_null("NameLabel") as Label

	if label == null:
		return

	if npc_data != null:
		label.text = npc_data.display_name


func _apply_visual() -> void:
	var color_rect := get_node_or_null("ColorRect") as ColorRect
	var name_label := get_node_or_null("NameLabel") as Label

	if color_rect == null or npc_data == null:
		return

	if npc_data.npc_category == NPCData.NPCCategory.STORY:
		if npc_data.npc_id == "irene":
			color_rect.color = Color(0.2, 0.7, 0.3, 1.0)
			if name_label != null:
				name_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4, 1.0))
		elif npc_data.npc_id == "gooby":
			color_rect.color = Color(0.4, 0.2, 0.8, 1.0)
			if name_label != null:
				name_label.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0, 1.0))
		return

	if npc_data.visit_phase == NPCData.VisitPhase.DAY:
		color_rect.color = Color(1.0, 0.5, 0.0, 0.75)
		if name_label != null:
			name_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4, 1.0))
	else:
		color_rect.color = Color(0.3, 0.5, 0.9, 0.75)
		if name_label != null:
			name_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 1.0))


func _process_enter() -> void:
	_enter_pause_timer += get_process_delta_time()

	if _enter_pause_timer < ENTER_PAUSE:
		return

	_choose_available_item_to_buy()

	var target_shelf := _find_matching_shelf()

	if target_shelf == null:
		_show_dialog("Nothing I need is on the shelves right now.")
		_dialog_timer = DIALOG_DURATION
		target_position = entrance_position
		_set_state(State.EXIT)
		return

	target_position = _get_shelf_visit_position(target_shelf)
	_set_state(State.WALK_TO_SHELF)


func _process_walk_to_shelf() -> void:
	if global_position.distance_to(target_position) <= SHELF_ACTION_DISTANCE:
		velocity = Vector2.ZERO
		move_and_slide()
		_set_state(State.SEARCH_ITEM)
		return

	if _move_to(target_position):
		_set_state(State.SEARCH_ITEM)


func _process_search_item(delta: float) -> void:
	_search_timer += delta

	if _has_any_requested_item_available():
		if not _search_announced:
			_show_dialog(BlueprintManager.get_item_found_dialog(self))
			_search_announced = true

		_set_state(State.TAKE_ITEM)
		return

	var action := BlueprintManager.evaluate_no_item_action(self)

	match action:
		BlueprintManager.Action.LEAVE:
			if not _search_announced:
				_show_dialog(BlueprintManager.get_item_not_found_dialog(self))
				_search_announced = true

			if _search_timer >= SEARCH_PATIENCE:
				target_position = entrance_position
				_set_state(State.EXIT)

		BlueprintManager.Action.QUEUE:
			if not _search_announced:
				_show_dialog(BlueprintManager.get_item_not_found_dialog(self))
				_search_announced = true

			if _search_timer >= SEARCH_PATIENCE:
				_show_dialog("Is there any restock coming...? I'll wait here.")
				_search_timer = 0.0
				_search_announced = false
				_join_queue()
				target_position = _get_queue_target()
				_set_state(State.WAIT_IN_QUEUE)

		BlueprintManager.Action.BROWSE_BUY:
			if not _search_announced:
				_show_dialog(BlueprintManager.get_item_not_found_dialog(self))
				_search_announced = true

			if _search_timer >= 5.0:
				var alt_item := _find_alternative_item()

				if alt_item != "":
					_browse_item = alt_item
					item_to_buy = alt_item
					_search_timer = 0.0
					_search_announced = false
					_show_dialog("Oh? This looks good actually.")
					_set_state(State.TAKE_ITEM)
				else:
					target_position = entrance_position
					_set_state(State.EXIT)


func _process_browse_item(delta: float) -> void:
	_search_timer += delta

	if _search_timer < 8.0:
		return

	var alt_item := _find_alternative_item()

	if alt_item != "":
		_browse_item = alt_item
		item_to_buy = alt_item
		_show_dialog("This one will do!")
		_set_state(State.TAKE_ITEM)
	else:
		_show_dialog("Nothing here for me...")
		target_position = entrance_position
		_set_state(State.EXIT)


func _process_take_item() -> void:
	if global_position.distance_to(target_position) > SHELF_ACTION_DISTANCE and not _move_to(target_position):
		return

	if _take_requested_items_from_shelves():
		_join_queue()
		target_position = _get_queue_target()
		_show_dialog("I'll take this.")
		_set_state(State.WAIT_IN_QUEUE)
		return

	target_position = entrance_position
	_set_state(State.EXIT)


func _process_wait_in_queue(_delta: float) -> void:
	target_position = _get_queue_target()

	var arrived := global_position.distance_to(target_position) <= QUEUE_ACTION_DISTANCE

	if not arrived:
		arrived = _move_to(target_position)

	if arrived and current_queue.find(self) == 0:
		velocity = Vector2.ZERO
		move_and_slide()
		_set_state(State.CHECKOUT)


func _process_checkout(delta: float) -> void:
	if _checkout_timer == 0.0:
		_show_dialog("I'd like to buy %s." % get_checkout_item_label())

	_checkout_timer += delta

	if npc_data.patience_type == NPCData.PatienceType.IMPATIENT and _checkout_timer >= CHECKOUT_PATIENCE:
		_show_dialog(BlueprintManager.get_checkout_wait_dialog(self))
		_leave_queue()
		_return_item_to_shelf()
		target_position = entrance_position
		_set_state(State.EXIT)


func _process_exit() -> void:
	if _dialog_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _move_to(target_position):
		npc_exited.emit(self)
		queue_done()


func _move_to(target: Vector2) -> bool:
	var distance := global_position.distance_to(target)

	if distance <= ARRIVAL_THRESHOLD:
		velocity = Vector2.ZERO
		move_and_slide()
		return true

	velocity = global_position.direction_to(target) * SPEED
	move_and_slide()

	return false


func _choose_item_to_buy() -> void:
	if not shopping_list.is_empty():
		item_to_buy = shopping_list[0]
		return

	if npc_data == null or npc_data.favorite_items.is_empty():
		item_to_buy = ""
		return

	item_to_buy = npc_data.favorite_items[randi() % npc_data.favorite_items.size()]


func _choose_available_item_to_buy() -> void:
	if npc_data == null:
		return

	for shopping_item_id in shopping_list:
		if _find_shelf_with_item(shopping_item_id) != null:
			item_to_buy = shopping_item_id
			item_to_buy_original = item_to_buy
			return

	for favorite_item_id in npc_data.favorite_items:
		var item_id := str(favorite_item_id)

		if _find_shelf_with_item(item_id) != null:
			item_to_buy = item_id
			item_to_buy_original = item_to_buy
			return

	if item_to_buy == "":
		_choose_item_to_buy()


func _find_alternative_item() -> String:
	var target_type := ItemData.ShelfType.HUMAN
	var wanted_item: ItemData = ItemDatabase.get_item(item_to_buy)

	if wanted_item != null:
		target_type = wanted_item.shelf_type

	for shelf in get_tree().get_nodes_in_group("shelves"):
		if not shelf is Shelf:
			continue

		if shelf.shelf_type != target_type:
			continue

		for i in shelf.max_slots:
			var shelf_item_id: String = shelf.get_slot_content(i)

			if shelf_item_id != "" and shelf_item_id != item_to_buy_original:
				return shelf_item_id

	return ""


func _join_queue() -> void:
	if self not in current_queue:
		current_queue.append(self)


func _leave_queue() -> void:
	current_queue.erase(self)


func _get_queue_target() -> Vector2:
	var position_in_queue := current_queue.find(self)

	if position_in_queue < 0:
		return counter_position

	return counter_position + Vector2(0, position_in_queue * 20.0)


func _return_item_to_shelf() -> void:
	if not _cart_items.is_empty():
		_return_cart_items_to_shelf()
		return

	var item: ItemData = ItemDatabase.get_item(item_to_buy)

	if item == null:
		return

	for shelf in get_tree().get_nodes_in_group("shelves"):
		if shelf is Shelf and shelf.shelf_type == item.shelf_type:
			Inventory.add_item(item_to_buy)
			shelf.place_item(item_to_buy)
			return


func _find_matching_shelf() -> Shelf:
	var item: ItemData = ItemDatabase.get_item(item_to_buy)

	if item == null:
		return null

	var stocked_shelf := _find_shelf_with_item(item_to_buy)

	if stocked_shelf != null:
		return stocked_shelf

	var fallback_shelf: Shelf = null

	for shelf in get_tree().get_nodes_in_group("shelves"):
		if not shelf is Shelf:
			continue

		if shelf.shelf_type != item.shelf_type:
			continue

		if shelf.has_item(item_to_buy):
			return shelf

		if fallback_shelf == null:
			fallback_shelf = shelf

	return fallback_shelf


func _find_shelf_with_item(item_id: String) -> Shelf:
	for shelf in get_tree().get_nodes_in_group("shelves"):
		if shelf is Shelf and shelf.has_item(item_id):
			return shelf

	return null


func _get_shelf_visit_position(shelf: Shelf) -> Vector2:
	return shelf.global_position + SHELF_VISIT_OFFSET


func _apply_scripted_metadata() -> void:
	shopping_list.clear()
	_cart_items.clear()
	checkout_total_override = -1
	checkout_outcome = "paid"

	if npc_data == null:
		return

	if npc_data.has_meta("shopping_list"):
		for item_id in npc_data.get_meta("shopping_list"):
			shopping_list.append(str(item_id))

	if npc_data.has_meta("checkout_total"):
		checkout_total_override = int(npc_data.get_meta("checkout_total"))

	if npc_data.has_meta("checkout_outcome"):
		checkout_outcome = str(npc_data.get_meta("checkout_outcome"))


func _has_any_requested_item_available() -> bool:
	for requested_item_id in _get_requested_items():
		if _find_shelf_with_item(requested_item_id) != null:
			return true

	return false


func _take_requested_items_from_shelves() -> bool:
	_cart_items.clear()

	for requested_item_id in _get_requested_items():
		var shelf := _find_shelf_with_item(requested_item_id)

		if shelf != null and shelf.take_item_for_npc(requested_item_id):
			_cart_items.append(requested_item_id)

	if not _cart_items.is_empty():
		item_to_buy = _cart_items[0]
		return true

	return false


func _get_requested_items() -> Array[String]:
	if not shopping_list.is_empty():
		return shopping_list

	return [item_to_buy]


func _return_cart_items_to_shelf() -> void:
	for cart_item_id in _cart_items:
		var item: ItemData = ItemDatabase.get_item(cart_item_id)

		if item == null:
			continue

		for shelf in get_tree().get_nodes_in_group("shelves"):
			if shelf is Shelf and shelf.shelf_type == item.shelf_type:
				shelf.stock_item_direct(cart_item_id)
				break

	_cart_items.clear()


func _set_state(new_state: State) -> void:
	if new_state == State.ENTER:
		_enter_pause_timer = 0.0

	if new_state == State.SEARCH_ITEM:
		_search_timer = 0.0
		_search_announced = false

	if new_state == State.CHECKOUT:
		_checkout_timer = 0.0

	current_state = new_state


func _show_dialog(text: String) -> void:
	var bubble := get_node_or_null("DialogBubble") as ColorRect
	var label := get_node_or_null("DialogBubble/DialogLabel") as Label

	if label == null:
		label = get_node_or_null("DialogLabel") as Label

	if bubble == null or label == null:
		print("[%s]: %s" % [npc_data.display_name if npc_data else "NPC", text])
		return

	_set_dialog_mouse_filter()
	label.text = text
	bubble.visible = true
	_dialog_timer = DIALOG_DURATION


func _update_dialog(delta: float) -> void:
	if _dialog_timer <= 0.0:
		return

	_dialog_timer -= delta

	if _dialog_timer > 0.0:
		return

	_hide_dialog()


func _hide_dialog() -> void:
	var bubble := get_node_or_null("DialogBubble") as ColorRect

	if bubble != null:
		bubble.visible = false


func _set_dialog_mouse_filter() -> void:
	var bubble := get_node_or_null("DialogBubble") as Control
	var label := get_node_or_null("DialogBubble/DialogLabel") as Control

	if bubble != null:
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if label != null:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
