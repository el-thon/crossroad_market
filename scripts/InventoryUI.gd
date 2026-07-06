extends Control

@onready var item_container: VBoxContainer = $Panel/VBoxContainer

func _ready() -> void:
	Inventory.inventory_changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(_item_id: String, _quantity: int) -> void:
	_refresh()

func _refresh() -> void:
	# clear existing labels
	for child in item_container.get_children():
		child.queue_free()

	var items: Dictionary = Inventory.get_all()
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "(empty)"
		empty_label.add_theme_font_size_override("font_size", 8)
		item_container.add_child(empty_label)
		return

	for item_id in items:
		var quantity: int = items[item_id]
		var item_data: ItemData = ItemDatabase.get_item(item_id)
		var display_name: String = item_data.display_name if item_data else item_id

		var label := Label.new()
		label.text = "%s x%d" % [display_name, quantity]
		label.add_theme_font_size_override("font_size", 8)
		item_container.add_child(label)
