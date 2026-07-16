class_name RestockPackage
extends Area2D

signal collected(delivery_id: int)

var delivery_id: int = -1
var item_id: String = ""
var quantity: int = 1
var deliveries: Array[Dictionary] = []

var _label: Label = null


func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	_ensure_visual()
	_refresh_label()


func setup(id: int, package_item_id: String, package_quantity: int) -> void:
	delivery_id = id
	item_id = package_item_id
	quantity = maxi(package_quantity, 1)
	deliveries = [{
		"item_id": item_id,
		"quantity": quantity
	}]
	_refresh_label()


func setup_deliveries(package_deliveries: Array) -> void:
	delivery_id = -1
	item_id = ""
	quantity = 0
	deliveries.clear()

	for delivery in package_deliveries:
		if not (delivery is Dictionary):
			continue

		var data := delivery as Dictionary
		var delivery_items := data.get("items", []) as Array

		if delivery_items.is_empty() and data.has("item_id"):
			delivery_items = [data]

		for item in delivery_items:
			if not (item is Dictionary):
				continue

			var item_data := item as Dictionary
			var delivery_item_id := str(item_data.get("item_id", ""))
			var delivery_quantity := int(item_data.get("quantity", 0))

			if delivery_item_id == "" or delivery_quantity <= 0:
				continue

			deliveries.append({
				"item_id": delivery_item_id,
				"quantity": delivery_quantity
			})
			quantity += delivery_quantity

	_refresh_label()


func get_hover_display_name() -> String:
	return "Restock Supply Box"


func request_interaction() -> bool:
	if deliveries.is_empty():
		return false

	for delivery in deliveries:
		Inventory.add_item(str(delivery.get("item_id", "")), int(delivery.get("quantity", 1)))

	_show_notification("Picked up restock delivery x%d." % quantity, 0.9)
	collected.emit(delivery_id)
	queue_free()
	return true


func _get_item_name() -> String:
	var item := ItemDatabase.get_item(item_id)
	return item.display_name if item != null and item.display_name != "" else item_id.capitalize()


func _ensure_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(64, 42)
		shape.shape = rect
		add_child(shape)

	if get_node_or_null("VisualRoot") == null:
		var visual_root := Node2D.new()
		visual_root.name = "VisualRoot"
		add_child(visual_root)

		var box := ColorRect.new()
		box.name = "SupplyBox"
		box.offset_left = -30.0
		box.offset_top = -28.0
		box.offset_right = 30.0
		box.offset_bottom = 14.0
		box.color = Color(0.46, 0.31, 0.16, 1.0)
		visual_root.add_child(box)

		var strap := ColorRect.new()
		strap.name = "SupplyBoxStrap"
		strap.offset_left = -30.0
		strap.offset_top = -10.0
		strap.offset_right = 30.0
		strap.offset_bottom = -3.0
		strap.color = Color(0.86, 0.67, 0.36, 1.0)
		visual_root.add_child(strap)

		_label = Label.new()
		_label.name = "SupplyBoxLabel"
		_label.position = Vector2(-36, 15)
		_label.size = Vector2(72, 16)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 7)
		visual_root.add_child(_label)
	else:
		_label = get_node_or_null("VisualRoot/SupplyBoxLabel") as Label


func _refresh_label() -> void:
	if _label == null:
		return

	_label.text = "x%d" % quantity


func _show_notification(text: String, duration: float) -> void:
	var hud := get_tree().get_first_node_in_group("hud")

	if hud != null and hud.has_method("show_notification"):
		hud.call("show_notification", text, duration, false)
