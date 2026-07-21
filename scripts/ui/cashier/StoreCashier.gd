class_name StoreCashierUI
extends Node2D

## The replacement cashier UI.  It is intentionally independent of Cashier.gd
## so the old checkout can remain active until this scene is swapped in.

signal payment_requested(total: int, item_label: String, quantities: Dictionary)
signal free_requested(total: int, item_label: String, quantities: Dictionary)
signal checkout_cancelled()

const UI_LAYER: int = 12
const ITEM_CARD_SIZE := Vector2(48, 15)
const ITEM_GRID_GAP: int = 1
const CATALOG_VIEW_RECT := Rect2(2, 211, 97, 55)
const CATALOG_SCROLL_STEP: float = 16.0
const SMALL_FONT_SIZE: int = 7
const BODY_FONT_SIZE: int = 8
const ITEM_CARD_TEXTURE: Texture2D = preload("res://assets/cashier/item-card.png")

@onready var _scan_tab: Node2D = $StoreCashier
@onready var _exchange_tab: Node2D = $CashierExchangeTab

var _ui_layer: CanvasLayer
var _scan_list: Control
var _scan_rows: GridContainer
var _scan_scrollbar: VScrollBar
var _scan_cart: ScrollContainer
var _scan_cart_rows: VBoxContainer
var _scan_total: Label
var _customer_cash_label: Label
var _scan_continue: Button
var _exchange_cart_rows: VBoxContainer
var _exchange_total: Label
var _exchange_hint: Label
var _exchange_input: Label
var _scan_dialog: Label
var _exchange_dialog: Label
var _scan_portrait: PortraitAnimation
var _exchange_portrait: PortraitAnimation

var _customer: NPC
var _target_item_ids: Array[String] = []
var _cart_quantities: Dictionary[String, int] = {}
var _customer_cash: int = 0
var _total: int = 0
var _change_due: int = 0
var _entered_change: String = ""
var _portrait_texture: Texture2D
var _action_lock_active: bool = false
var _inventory_panel: CanvasItem
var _inventory_was_visible: bool = true
var _inventory_hidden_by_cashier: bool = false


func _ready() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "CashierUILayer"
	_ui_layer.layer = UI_LAYER
	add_child(_ui_layer)
	_scan_tab.reparent(_ui_layer, false)
	_exchange_tab.reparent(_ui_layer, false)

	_build_scan_tab()
	_build_exchange_tab()
	_ui_layer.visible = false
	_hide_inventory_panel()


## Starts a checkout for an NPC.  This is the hand-off point when replacing
## Cashier.gd's runtime flow.
func begin_checkout(npc: NPC) -> bool:
	if npc == null or not is_instance_valid(npc):
		return false

	_customer = npc
	_target_item_ids = npc.get_cart_item_ids() if npc.has_method("get_cart_item_ids") else [npc.item_to_buy]
	var valid_target_item_ids: Array[String] = []
	for item_id in _target_item_ids:
		if not item_id.is_empty():
			valid_target_item_ids.append(item_id)
	_target_item_ids = valid_target_item_ids
	if _target_item_ids.is_empty():
		_show_notification("This customer has no items to scan.")
		return false

	_cart_quantities.clear()
	_total = 0
	_change_due = 0
	_entered_change = ""
	_customer_cash = _get_customer_cash(npc, _get_target_total())
	_portrait_texture = _get_customer_portrait(npc)
	_apply_customer_presentation()
	_refresh_scan_tab()
	_show_scan_tab()
	_hide_inventory_panel()
	_set_action_lock(true)
	return true


func reset_runtime_ui() -> void:
	_ui_layer.visible = false
	_customer = null
	_target_item_ids.clear()
	_cart_quantities.clear()
	_entered_change = ""
	_restore_inventory_panel()
	_set_action_lock(false)


func _exit_tree() -> void:
	_restore_inventory_panel()


func has_active_checkout() -> bool:
	return _customer != null and is_instance_valid(_customer) and _ui_layer.visible


func _unhandled_input(event: InputEvent) -> void:
	if not has_active_checkout():
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		reset_runtime_ui()
		checkout_cancelled.emit()
		get_viewport().set_input_as_handled()


func _build_scan_tab() -> void:
	var cards_root := _scan_tab.get_node("Cards") as Node2D
	_scan_list = Control.new()
	_scan_list.name = "CardViewport"
	_scan_list.position = CATALOG_VIEW_RECT.position
	_scan_list.size = CATALOG_VIEW_RECT.size
	_scan_list.clip_contents = true
	_scan_list.mouse_filter = Control.MOUSE_FILTER_STOP
	_scan_list.gui_input.connect(_on_catalog_gui_input)
	cards_root.add_child(_scan_list)

	_scan_rows = GridContainer.new()
	_scan_rows.name = "ItemGrid"
	_scan_rows.columns = 2
	_scan_rows.size = Vector2(CATALOG_VIEW_RECT.size.x, 0)
	_scan_rows.add_theme_constant_override("h_separation", ITEM_GRID_GAP)
	_scan_rows.add_theme_constant_override("v_separation", ITEM_GRID_GAP)
	_scan_list.add_child(_scan_rows)

	_scan_scrollbar = VScrollBar.new()
	_scan_scrollbar.name = "ScrollThumb"
	_scan_scrollbar.position = Vector2(100.5, 211.5)
	_scan_scrollbar.size = Vector2(5, 55)
	_scan_scrollbar.step = 1.0
	_scan_scrollbar.mouse_filter = Control.MOUSE_FILTER_STOP
	_scan_scrollbar.z_index = 5
	var empty_track := StyleBoxEmpty.new()
	var thumb_style := _panel_style(Color("ad673c"), Color("ad673c"), 0)
	_scan_scrollbar.add_theme_stylebox_override("scroll", empty_track)
	_scan_scrollbar.add_theme_stylebox_override("scroll_focus", empty_track)
	_scan_scrollbar.add_theme_stylebox_override("grabber", thumb_style)
	_scan_scrollbar.add_theme_stylebox_override("grabber_highlight", thumb_style)
	_scan_scrollbar.add_theme_stylebox_override("grabber_pressed", thumb_style)
	_scan_scrollbar.value_changed.connect(_on_catalog_scroll_changed)
	_scan_tab.add_child(_scan_scrollbar)

	_scan_cart = ScrollContainer.new()
	_scan_cart.name = "SelectedItems"
	_scan_cart.position = Vector2(113, 214)
	_scan_cart.size = Vector2(72, 34)
	_scan_cart.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scan_cart.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scan_cart.mouse_filter = Control.MOUSE_FILTER_STOP
	_scan_tab.add_child(_scan_cart)

	_scan_cart_rows = VBoxContainer.new()
	_scan_cart_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scan_cart_rows.add_theme_constant_override("separation", 0)
	_scan_cart.add_child(_scan_cart_rows)

	_scan_total = _make_label("TOTAL 0G", BODY_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER)
	_scan_total.position = Vector2(109, 193)
	_scan_total.size = Vector2(80, 13)
	_scan_total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scan_total.add_theme_color_override("font_color", Color.WHITE)
	_scan_tab.add_child(_scan_total)

	_scan_continue = _make_button("", Rect2(169, 250, 16, 11), BODY_FONT_SIZE)
	_scan_continue.tooltip_text = "Check the scanned items and enter the customer's change."
	_scan_continue.pressed.connect(_on_scan_continue_pressed)
	_add_exchange_arrow_icon(_scan_continue)
	_scan_tab.add_child(_scan_continue)

	var customer_money := _scan_tab.get_node("CustomerMoney") as Sprite2D
	_customer_cash_label = _make_label("0G", BODY_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER)
	_customer_cash_label.position = Vector2(-24, -7)
	_customer_cash_label.size = Vector2(48, 14)
	_customer_cash_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	customer_money.add_child(_customer_cash_label)

	_scan_dialog = _make_dialog_label()
	_scan_tab.add_child(_scan_dialog)
	_scan_portrait = _scan_tab.get_node("PortraitAnimation") as PortraitAnimation


func _build_exchange_tab() -> void:
	_exchange_total = _make_label("TOTAL 0G", BODY_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER)
	_exchange_total.position = Vector2(109, 193)
	_exchange_total.size = Vector2(80, 13)
	_exchange_total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_exchange_total.add_theme_color_override("font_color", Color.WHITE)
	_exchange_tab.add_child(_exchange_total)

	_exchange_cart_rows = VBoxContainer.new()
	_exchange_cart_rows.position = Vector2(113, 214)
	_exchange_cart_rows.size = Vector2(72, 28)
	_exchange_cart_rows.add_theme_constant_override("separation", 0)
	_exchange_tab.add_child(_exchange_cart_rows)

	_exchange_input = _make_label("", BODY_FONT_SIZE, HORIZONTAL_ALIGNMENT_RIGHT)
	_exchange_input.position = Vector2(113, 244)
	_exchange_input.size = Vector2(72, 13)
	_exchange_input.add_theme_color_override("font_color", Color("fff2a6"))
	_exchange_input.add_theme_stylebox_override("normal", _panel_style(Color("6e514d"), Color("d9c2a8"), 1))
	_exchange_tab.add_child(_exchange_input)

	_exchange_hint = _make_label("CHANGE 0G", BODY_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER)
	_exchange_hint.position = Vector2(126, 179)
	_exchange_hint.size = Vector2(50, 12)
	_exchange_tab.add_child(_exchange_hint)

	_build_calculator()
	_exchange_dialog = _make_dialog_label()
	_exchange_tab.add_child(_exchange_dialog)
	_exchange_portrait = _exchange_tab.get_node("PortraitAnimation") as PortraitAnimation


func _build_calculator() -> void:
	var digits := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
	for index in digits.size():
		var column := index % 3
		var row := index / 3
		var position := Vector2(2 + column * 16, 212 + row * 13)
		var digit_button := _make_button(digits[index], Rect2(position, Vector2(14, 11)), SMALL_FONT_SIZE)
		digit_button.tooltip_text = "Add %s to the change amount." % digits[index]
		digit_button.pressed.connect(_on_digit_pressed.bind(digits[index]))
		_exchange_tab.add_child(digit_button)

	var free_button := _make_button("FREE", Rect2(63, 216, 30, 25), BODY_FONT_SIZE)
	free_button.tooltip_text = "Give the selected items to the customer for free."
	free_button.add_theme_color_override("font_color", Color("fff0e8"))
	free_button.add_theme_stylebox_override("normal", _panel_style(Color("ba1f26"), Color("ff5c5c"), 1))
	free_button.pressed.connect(_on_free_pressed)
	_exchange_tab.add_child(free_button)

	var delete_button := _make_button("DEL", Rect2(63, 246, 14, 11), SMALL_FONT_SIZE)
	delete_button.tooltip_text = "Delete the last digit, or return to Scan when the field is empty."
	delete_button.pressed.connect(_on_delete_or_back_pressed)
	_exchange_tab.add_child(delete_button)

	var confirm_button := _make_button("OK", Rect2(79, 246, 14, 11), SMALL_FONT_SIZE)
	confirm_button.tooltip_text = "Return the exact change to complete the checkout."
	confirm_button.pressed.connect(_on_confirm_exchange_pressed)
	_exchange_tab.add_child(confirm_button)


func _refresh_scan_tab() -> void:
	_clear_children(_scan_rows)
	var store_items := _get_store_items()
	for item in store_items:
		_scan_rows.add_child(_make_catalog_item(item))
	_update_catalog_scroll_metrics(store_items.size())

	_refresh_cart_displays()
	_customer_cash_label.text = "%dG" % _customer_cash
	_scan_dialog.text = _get_customer_dialogue()
	_scan_continue.disabled = _cart_quantities.is_empty()


func _refresh_cart_displays() -> void:
	_total = _calculate_cart_total()
	_scan_total.text = "TOTAL %dG" % _total
	_exchange_total.text = "TOTAL %dG" % _total

	_clear_children(_scan_cart_rows)
	_clear_children(_exchange_cart_rows)
	if _cart_quantities.is_empty():
		_scan_cart_rows.add_child(_make_label("Select items", SMALL_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER))
		_exchange_cart_rows.add_child(_make_label("No items", SMALL_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER))
		return

	for item_id in _cart_quantities:
		var quantity := _cart_quantities[item_id]
		_scan_cart_rows.add_child(_make_cart_row(item_id, quantity, true))
		_exchange_cart_rows.add_child(_make_cart_row(item_id, quantity, false))


func _make_catalog_item(item: ItemData) -> Button:
	var button := _make_button("", Rect2(Vector2.ZERO, ITEM_CARD_SIZE), SMALL_FONT_SIZE)
	button.custom_minimum_size = ITEM_CARD_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	button.tooltip_text = "Scan %s for %dG." % [item.display_name, item.sell_price]
	button.pressed.connect(_on_item_scanned.bind(item.item_id))

	var card := TextureRect.new()
	card.texture = ITEM_CARD_TEXTURE
	card.position = Vector2.ZERO
	card.size = ITEM_CARD_SIZE
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(card)

	var icon := TextureRect.new()
	icon.texture = item.get_icon()
	icon.position = Vector2(1, 1)
	icon.size = Vector2(13, 13)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	var item_name := _make_label(item.display_name, SMALL_FONT_SIZE)
	item_name.position = Vector2(15, 0)
	item_name.size = Vector2(31, 8)
	item_name.clip_text = true
	item_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	item_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(item_name)

	var price := _make_label("%dG" % item.sell_price, SMALL_FONT_SIZE)
	price.position = Vector2(15, 7)
	price.size = Vector2(31, 8)
	price.add_theme_color_override("font_color", Color("ead2a2"))
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(price)
	return button


func _make_cart_row(item_id: String, quantity: int, allow_decrement: bool) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(72, 10)
	row.add_theme_constant_override("separation", 1)
	var item: ItemData = ItemDatabase.get_item(item_id)
	var name := item.display_name if item != null else item_id
	var price := item.sell_price if item != null else 0
	var text := _make_label("%s x%d" % [name, quantity], SMALL_FONT_SIZE)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.clip_text = true
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(text)

	var subtotal := _make_label("%d" % (price * quantity), SMALL_FONT_SIZE, HORIZONTAL_ALIGNMENT_RIGHT)
	subtotal.custom_minimum_size = Vector2(15, 0)
	row.add_child(subtotal)

	if allow_decrement:
		var minus := _make_button("", Rect2(Vector2.ZERO, Vector2(9, 9)), SMALL_FONT_SIZE)
		minus.custom_minimum_size = Vector2(9, 9)
		minus.tooltip_text = "Remove one %s." % name
		minus.pressed.connect(_on_item_decremented.bind(item_id))
		var minus_icon := ColorRect.new()
		minus_icon.position = Vector2(2, 4)
		minus_icon.size = Vector2(5, 1)
		minus_icon.color = Color.BLACK
		minus_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		minus.add_child(minus_icon)
		row.add_child(minus)
	return row


func _show_scan_tab() -> void:
	if _exchange_portrait != null and _scan_portrait != null and _portrait_texture != null:
		_scan_portrait.set_portrait(_portrait_texture, _exchange_portrait.get_current_frame())
	_scan_tab.visible = true
	_exchange_tab.visible = false
	_ui_layer.visible = true
	_set_tab_contrast(_scan_tab, true)
	_set_tab_contrast(_exchange_tab, false)
	_hide_inventory_panel()


func show_scan_tab() -> void:
	if has_active_checkout():
		_show_scan_tab()


func _show_exchange_tab() -> void:
	if _scan_portrait != null and _exchange_portrait != null and _portrait_texture != null:
		_exchange_portrait.set_portrait(_portrait_texture, _scan_portrait.get_current_frame())
	_scan_tab.visible = false
	_exchange_tab.visible = true
	_ui_layer.visible = true
	_set_tab_contrast(_scan_tab, false)
	_set_tab_contrast(_exchange_tab, true)
	_hide_inventory_panel()
	_refresh_exchange_tab()


func show_exchange_tab() -> void:
	if has_active_checkout():
		_show_exchange_tab()


func _refresh_exchange_tab() -> void:
	_change_due = max(_customer_cash - _total, 0)
	_exchange_hint.text = "CHANGE %dG" % _change_due
	_exchange_input.text = ("[%sG]" % _entered_change) if not _entered_change.is_empty() else "[--G]"
	_exchange_dialog.text = _get_customer_dialogue()
	_refresh_cart_displays()


func _update_catalog_scroll_metrics(item_count: int) -> void:
	var row_count := ceili(float(item_count) / 2.0)
	var content_height := maxf(
		CATALOG_VIEW_RECT.size.y,
		row_count * ITEM_CARD_SIZE.y + maxi(row_count - 1, 0) * ITEM_GRID_GAP
	)
	_scan_rows.custom_minimum_size = Vector2(CATALOG_VIEW_RECT.size.x, content_height)
	_scan_rows.size = Vector2(CATALOG_VIEW_RECT.size.x, content_height)
	_scan_scrollbar.min_value = 0.0
	_scan_scrollbar.max_value = content_height
	_scan_scrollbar.page = CATALOG_VIEW_RECT.size.y
	_scan_scrollbar.visible = content_height > CATALOG_VIEW_RECT.size.y
	_scan_scrollbar.value = clampf(
		_scan_scrollbar.value,
		0.0,
		maxf(content_height - CATALOG_VIEW_RECT.size.y, 0.0)
	)
	_on_catalog_scroll_changed(_scan_scrollbar.value)


func _on_catalog_scroll_changed(value: float) -> void:
	_scan_rows.position.y = -roundf(value)


func _on_catalog_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_scan_scrollbar.value -= CATALOG_SCROLL_STEP
		_scan_list.accept_event()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_scan_scrollbar.value += CATALOG_SCROLL_STEP
		_scan_list.accept_event()


func _on_item_scanned(item_id: String) -> void:
	_cart_quantities[item_id] = _cart_quantities.get(item_id, 0) + 1
	_refresh_scan_tab()


func _on_item_decremented(item_id: String) -> void:
	if not _cart_quantities.has(item_id):
		return
	_cart_quantities[item_id] -= 1
	if _cart_quantities[item_id] <= 0:
		_cart_quantities.erase(item_id)
	_refresh_scan_tab()


func _on_scan_continue_pressed() -> void:
	if _cart_quantities.is_empty():
		_show_notification("Scan at least one item first.")
		return
	if not _cart_matches_customer():
		_show_notification("Scan exactly the items this customer requested.")
		return
	_entered_change = ""
	_show_exchange_tab()


func _on_digit_pressed(digit: String) -> void:
	if _entered_change.length() >= 6:
		return
	_entered_change += digit
	_refresh_exchange_tab()


func _on_delete_or_back_pressed() -> void:
	if _entered_change.is_empty():
		_show_scan_tab()
		return
	_entered_change = _entered_change.left(-1)
	_refresh_exchange_tab()


func _on_confirm_exchange_pressed() -> void:
	if _entered_change.is_empty() or int(_entered_change) != _change_due:
		_show_notification("Return exactly %dG in change." % _change_due)
		_flash_exchange_input()
		return
	_complete_checkout(false)


func _on_free_pressed() -> void:
	if not _cart_matches_customer():
		_show_notification("Scan the customer's requested items before giving them away.")
		return
	_complete_checkout(true)


func _complete_checkout(is_free: bool) -> void:
	if _customer == null or not is_instance_valid(_customer):
		reset_runtime_ui()
		return

	var item_label := _get_selected_item_label()
	var quantities := _cart_quantities.duplicate(true)
	if is_free:
		free_requested.emit(_total, item_label, quantities)
	else:
		payment_requested.emit(_total, item_label, quantities)


func _cart_matches_customer() -> bool:
	var selected: Array[String] = []
	for item_id in _cart_quantities:
		for count in _cart_quantities[item_id]:
			selected.append(item_id)
	return CashierCheckoutService.selection_matches_customer(selected, _target_item_ids)


func _calculate_cart_total() -> int:
	var total := 0
	for item_id in _cart_quantities:
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item != null:
			total += item.sell_price * _cart_quantities[item_id]
	return total


func _get_selected_item_label() -> String:
	var labels: Array[String] = []
	for item_id in _cart_quantities:
		var item: ItemData = ItemDatabase.get_item(item_id)
		var item_name := item.display_name if item != null else item_id
		var quantity := _cart_quantities[item_id]
		labels.append("%s x%d" % [item_name, quantity] if quantity > 1 else item_name)
	return ", ".join(labels)


func _get_target_total() -> int:
	if _customer != null and _customer.has_method("get_checkout_total"):
		return _customer.get_checkout_total()
	return CashierCheckoutService.calculate_total(_target_item_ids)


func _get_customer_cash(npc: NPC, target_total: int) -> int:
	if npc.npc_data != null and npc.npc_data.checkout_cash > 0:
		return max(npc.npc_data.checkout_cash, target_total)

	for denomination in [10, 20, 25, 50, 100, 200, 500, 1000]:
		if denomination >= target_total:
			return denomination
	return ceili(float(target_total) / 100.0) * 100


func _get_customer_portrait(npc: NPC) -> Texture2D:
	if npc.npc_data == null:
		return null
	if npc.npc_data.portrait != null:
		return npc.npc_data.portrait
	if npc.npc_data.assets_path.is_empty():
		return null
	return NPCAssetRuntime.load_portrait_texture(npc.npc_data.assets_path)


func _apply_customer_presentation() -> void:
	var dialogue := _get_customer_dialogue()
	_scan_dialog.text = dialogue
	_exchange_dialog.text = dialogue
	if _portrait_texture != null:
		_scan_portrait.visible = true
		_exchange_portrait.visible = true
		_scan_portrait.set_portrait(_portrait_texture)
		_exchange_portrait.set_portrait(_portrait_texture)
	else:
		_scan_portrait.visible = false
		_exchange_portrait.visible = false


func _get_customer_dialogue() -> String:
	if _customer == null or not is_instance_valid(_customer):
		return "Customer\nWaiting..."
	var customer_name := "Customer"
	if _customer.npc_data != null and not _customer.npc_data.display_name.is_empty():
		customer_name = _customer.npc_data.display_name
	var request := _customer.get_checkout_item_label() if _customer.has_method("get_checkout_item_label") else "these items"
	return "%s\nJust %s, please." % [customer_name, request]


func _get_store_items() -> Array[ItemData]:
	var items: Array[ItemData] = ItemDatabase.get_all_items()
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		return a.display_name.naturalnocasecmp_to(b.display_name) < 0
	)
	return items


func _make_dialog_label() -> Label:
	var label := _make_label("Customer", BODY_FONT_SIZE)
	label.position = Vector2(211, 183)
	label.size = Vector2(176, 74)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_constant_override("line_spacing", 0)
	return label


func _add_exchange_arrow_icon(button: Button) -> void:
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([
		Vector2(2, 3),
		Vector2(9, 3),
		Vector2(9, 1),
		Vector2(14, 5.5),
		Vector2(9, 10),
		Vector2(9, 8),
		Vector2(2, 8),
	])
	arrow.color = Color.WHITE
	button.add_child(arrow)


func _make_label(text: String, font_size: int, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("3c251b"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_button(text: String, rect: Rect2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("f5dfc6"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color("fff0a0"))
	button.add_theme_stylebox_override("normal", _panel_style(Color.TRANSPARENT, Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("hover", _panel_style(Color("4e3025"), Color("d98c58"), 1))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("2b1714"), Color("fff0a0"), 1))
	button.add_theme_stylebox_override("disabled", _panel_style(Color.TRANSPARENT, Color.TRANSPARENT, 0))
	return button


func _panel_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.content_margin_left = 1
	style.content_margin_right = 1
	return style


func _set_tab_contrast(tab: Node2D, scan_selected: bool) -> void:
	var first_tab := tab.get_node("FirstTab") as CanvasItem
	var second_tab := tab.get_node("SecondTab") as CanvasItem
	if first_tab != null:
		first_tab.modulate = Color(1.18, 1.18, 1.18, 1.0) if scan_selected else Color(0.52, 0.52, 0.52, 1.0)
	if second_tab != null:
		second_tab.modulate = Color(0.52, 0.52, 0.52, 1.0) if scan_selected else Color(1.18, 1.18, 1.18, 1.0)


func _flash_exchange_input() -> void:
	_exchange_input.modulate = Color("ff6b6b")
	var tween := create_tween()
	tween.tween_property(_exchange_input, "modulate", Color.WHITE, 0.25)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _hide_inventory_panel() -> void:
	if _inventory_hidden_by_cashier:
		return
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	_inventory_panel = hud.get_node_or_null("InventoryUI") as CanvasItem
	if _inventory_panel == null:
		return
	_inventory_was_visible = _inventory_panel.visible
	_inventory_panel.visible = false
	_inventory_hidden_by_cashier = true


func _restore_inventory_panel() -> void:
	if not _inventory_hidden_by_cashier:
		return
	if _inventory_panel != null and is_instance_valid(_inventory_panel):
		_inventory_panel.visible = _inventory_was_visible
	_inventory_panel = null
	_inventory_hidden_by_cashier = false


func _set_action_lock(locked: bool) -> void:
	if locked == _action_lock_active:
		return
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	if locked and hud.has_method("begin_action_lock"):
		hud.call("begin_action_lock")
		_action_lock_active = true
	elif not locked and hud.has_method("end_action_lock"):
		hud.call("end_action_lock")
		_action_lock_active = false


func _show_notification(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("show_notification"):
		hud.call("show_notification", text, 1.2)
