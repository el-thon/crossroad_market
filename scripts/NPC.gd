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

var npc_data: NPCData
var current_state: State = State.ENTER
var target_position: Vector2 = Vector2.ZERO
var item_to_buy: String = ""
var item_to_buy_original: String = ""
var _browse_item: String = ""
var queue_position: int = 0
var _enter_pause_timer: float = 0.0
var _dialog_timer: float = 0.0
var _checkout_timer: float = 0.0
var _search_timer: float = 0.0
var _search_announced: bool = false
var _current_waypoint_index: int = 0

# queue tracking
static var current_queue: Array[NPC] = []
static var counter_position: Vector2 = Vector2.ZERO
static var entrance_position: Vector2 = Vector2.ZERO
static var shelf_positions: Array[Vector2] = []
static var npc_waypoints: Array[Vector2] = []

signal purchase_completed(npc: NPC, item_id: String, price: int)
signal npc_exited(npc: NPC)

func setup(data: NPCData) -> void:
	npc_data = data
	_choose_item_to_buy()
	item_to_buy_original = item_to_buy
	_apply_visual()
	_apply_name_label()
	_set_state(State.ENTER)

func _apply_name_label() -> void:
	var label := $NameLabel as Label
	if label == null:
		return
	if npc_data != null:
		label.text = npc_data.display_name

func _apply_visual() -> void:
	var color_rect = $ColorRect
	var name_label = $NameLabel as Label
	if color_rect == null:
		return

	if npc_data.is_special:
		if npc_data.npc_id == "irene":
			color_rect.color = Color(0.2, 0.7, 0.3, 1.0)
			if name_label: name_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4, 1.0))
		elif npc_data.npc_id == "gooby":
			color_rect.color = Color(0.4, 0.2, 0.8, 1.0)
			if name_label: name_label.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0, 1.0))
	else:
		if npc_data.visit_phase == NPCData.VisitPhase.DAY:
			color_rect.color = Color(1.0, 0.5, 0.0, 0.75)
			if name_label: name_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4, 1.0))
		else:
			color_rect.color = Color(0.3, 0.5, 0.9, 0.75)
			if name_label: name_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 1.0))

func _physics_process(delta: float) -> void:
	match current_state:
		State.ENTER: _process_enter()
		State.WALK_TO_SHELF: _process_walk_to_shelf()
		State.SEARCH_ITEM: _process_search_item(delta)
		State.BROWSE_ITEM: _process_browse_item(delta)
		State.TAKE_ITEM: _process_take_item()
		State.WAIT_IN_QUEUE: _process_wait_in_queue(delta)
		State.CHECKOUT: _process_checkout(delta)
		State.EXIT: _process_exit()

	_update_dialog(delta)

# --- State processors ---

func _process_enter() -> void:
	_enter_pause_timer += get_process_delta_time()
	if _enter_pause_timer < ENTER_PAUSE:
		return

	var target_shelf := _find_matching_shelf()
	if target_shelf == null:
		target_position = entrance_position
		_set_state(State.EXIT)
		return
	target_position = target_shelf.global_position
	_set_state(State.WALK_TO_SHELF)

func _process_walk_to_shelf() -> void:
	if not npc_waypoints.is_empty():
		if _current_waypoint_index < npc_waypoints.size():
			var waypoint := npc_waypoints[_current_waypoint_index]
			if _move_to(waypoint):
				_current_waypoint_index += 1
			return
		_current_waypoint_index = 0
	if _move_to(target_position):
		_set_state(State.SEARCH_ITEM)

func _process_search_item(delta: float) -> void:
	_search_timer += delta

	# Check if our preferred item is on shelf
	var shelves := get_tree().get_nodes_in_group("shelves")
	for shelf: Shelf in shelves:
		if shelf.has_item(item_to_buy):
			if not _search_announced:
				_show_dialog(BlueprintManager.get_item_found_dialog(self))
				_search_announced = true
			_set_state(State.TAKE_ITEM)
			return

	# Item not found — use blueprint to decide what to do
	var action := BlueprintManager.evaluate_no_item_action(self)

	match action:
		BlueprintManager.Action.LEAVE:
			if not _search_announced:
				_show_dialog(BlueprintManager.get_item_not_found_dialog(self))
				_search_announced = true
			if _search_timer >= SEARCH_PATIENCE:
				_show_dialog(BlueprintManager.get_queue_too_long_dialog(self))
				_dialog_timer = DIALOG_DURATION
				_search_timer = 0.0
				_search_announced = false
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
				# Try to find an alternative item on any shelf
				var alt_item: String = _find_alternative_item()
				if alt_item != "":
					_browse_item = alt_item
					var item_data: ItemData = ItemDatabase.get_item(alt_item)
					var alt_name: String = item_data.display_name if item_data else alt_item
					_show_dialog("Oh? This %s looks good actually." % alt_name)
					item_to_buy = alt_item
					_search_timer = 0.0
					_search_announced = false
					_set_state(State.TAKE_ITEM)
				else:
					_show_dialog("Nothing else catches my eye... maybe next time.")
					_dialog_timer = DIALOG_DURATION
					_search_timer = 0.0
					_search_announced = false
					target_position = entrance_position
					_set_state(State.EXIT)

func _process_browse_item(delta: float) -> void:
	# BROWSE_ITEM state: walk around shelf then buy alternative or leave
	_search_timer += delta
	if _search_timer >= 8.0:
		var alt_item: String = _find_alternative_item()
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
	if _move_to(target_position):
		var shelves := get_tree().get_nodes_in_group("shelves")
		for shelf: Shelf in shelves:
			if shelf.has_item(item_to_buy):
				shelf.take_item_for_npc(item_to_buy)
				_join_queue()
				target_position = _get_queue_target()
				_set_state(State.WAIT_IN_QUEUE)
				return
		# Item gone while walking — go back to search
		target_position = entrance_position
		_set_state(State.EXIT)

func _process_wait_in_queue(delta: float) -> void:
	target_position = _get_queue_target()
	_move_to(target_position)

	var position_in_queue := current_queue.find(self)
	var people_ahead := position_in_queue

	# First in queue — go to checkout
	if people_ahead == 0:
		_set_state(State.CHECKOUT)

func _process_checkout(delta: float) -> void:
	if _checkout_timer == 0.0:
		_show_dialog(BlueprintManager.get_checkout_dialog(self))

	_checkout_timer += delta
	var patience := npc_data.patience_type

	if patience == NPCData.PatienceType.IMPATIENT and _checkout_timer >= CHECKOUT_PATIENCE:
		_show_dialog(BlueprintManager.get_checkout_wait_dialog(self))
		_leave_queue()
		_return_item_to_shelf()
		target_position = entrance_position
		_set_state(State.EXIT)

func complete_checkout() -> void:
	var item: ItemData = ItemDatabase.get_item(item_to_buy)
	if item != null:
		purchase_completed.emit(self, item_to_buy, item.sell_price)
		_show_dialog(BlueprintManager.get_done_dialog(self))
	_dialog_timer = DIALOG_DURATION
	_leave_queue()
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

# --- Helper functions ---

func _move_to(target: Vector2) -> bool:
	var direction := global_position.direction_to(target)
	var distance := global_position.distance_to(target)

	if distance <= ARRIVAL_THRESHOLD:
		velocity = Vector2.ZERO
		move_and_slide()
		return true

	velocity = direction * SPEED
	move_and_slide()
	return false

func _choose_item_to_buy() -> void:
	if npc_data.favorite_items.is_empty():
		item_to_buy = ""
		return
	item_to_buy = npc_data.favorite_items[randi() % npc_data.favorite_items.size()]

func _find_alternative_item() -> String:
	var shelves := get_tree().get_nodes_in_group("shelves")
	var target_type := ItemData.ShelfType.HUMAN
	var item: ItemData = ItemDatabase.get_item(item_to_buy)
	if item != null:
		target_type = item.shelf_type

	for shelf: Shelf in shelves:
		if shelf.shelf_type == target_type:
			# Return first available item (excluding the original wanted item)
			for i in shelf.max_slots:
				var sid := shelf.get_slot_content(i)
				if sid != "" and sid != item_to_buy_original:
					return sid
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
	var shelves := get_tree().get_nodes_in_group("shelves")
	for shelf: Shelf in shelves:
		var item: ItemData = ItemDatabase.get_item(item_to_buy)
		if item != null and shelf.shelf_type == item.shelf_type:
			Inventory.add_item(item_to_buy)
			shelf.place_item(item_to_buy)
			return

func _find_matching_shelf() -> Shelf:
	var item: ItemData = ItemDatabase.get_item(item_to_buy)
	if item == null:
		return null
	var shelves := get_tree().get_nodes_in_group("shelves")
	for shelf: Shelf in shelves:
		if shelf.shelf_type == item.shelf_type:
			return shelf
	return null

func _set_state(new_state: State) -> void:
	if new_state == State.ENTER:
		_enter_pause_timer = 0.0
	if new_state == State.WALK_TO_SHELF:
		_current_waypoint_index = 0
	if new_state == State.SEARCH_ITEM:
		_search_timer = 0.0
		_search_announced = false
	if new_state == State.CHECKOUT:
		_checkout_timer = 0.0
	current_state = new_state

func _show_dialog(text: String) -> void:
	var bubble := $DialogBubble as ColorRect
	var label := $DialogLabel as Label
	if bubble == null or label == null:
		print("[%s]: %s" % [npc_data.display_name if npc_data else "NPC", text])
		return
	label.text = text
	bubble.visible = true
	_dialog_timer = DIALOG_DURATION

func _update_dialog(delta: float) -> void:
	if _dialog_timer <= 0.0:
		return
	_dialog_timer -= delta
	if _dialog_timer <= 0.0:
		var bubble := $DialogBubble as ColorRect
		if bubble != null:
			bubble.visible = false

func queue_done() -> void:
	queue_free()
