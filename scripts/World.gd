extends Node2D

var npc_scene: PackedScene = preload("res://scenes/NPC.tscn")

@onready var counter_pos: Marker2D = $CounterPos
@onready var entrance_pos: Marker2D = $EntrancePos
@onready var mystery_supply: MysterySupplyBox = $Mistery
@onready var human_shelf: Shelf = $ShelfHuman
@onready var warehouse_zone: Area2D = $WarehouseZone

var _shelf_positions: Array[Vector2] = []


func _ready() -> void:
	add_to_group("world")

	NPCScheduler.npc_spawn_requested.connect(_on_npc_spawn_requested)
	TimeManager.phase_changed.connect(_on_phase_changed)
	TimeManager.day_ended.connect(_on_day_ended)
	EconomyManager.daily_target_reached.connect(_on_target_reached)
	EconomyManager.daily_report_ready.connect(_on_daily_report)

	_collect_shelf_positions()
	_setup_npc_static_data()
	_connect_signals()

	TimeManager.start_game()


func _connect_signals() -> void:
	if human_shelf != null:
		if not human_shelf.item_placed.is_connected(_on_human_item_placed):
			human_shelf.item_placed.connect(_on_human_item_placed)

	if mystery_supply != null:
		if not mystery_supply.discovered.is_connected(_on_mystery_discovered):
			mystery_supply.discovered.connect(_on_mystery_discovered)


func _collect_npc_waypoints() -> void:
	var waypoints: Array[Vector2] = []
	var names := ["NPCWaypoint1", "NPCWaypoint2", "NPCWaypoint3"]

	for marker_name in names:
		var marker: Node = get_node_or_null(marker_name)

		if marker != null:
			waypoints.append(marker.global_position)

	NPC.npc_waypoints = waypoints


func _collect_shelf_positions() -> void:
	_shelf_positions.clear()

	for shelf in get_tree().get_nodes_in_group("shelves"):
		if shelf is Shelf:
			_shelf_positions.append(shelf.global_position)


func _setup_npc_static_data() -> void:
	if counter_pos != null:
		NPC.counter_position = counter_pos.global_position

	if entrance_pos != null:
		NPC.entrance_position = entrance_pos.global_position

	NPC.shelf_positions = _shelf_positions

	_collect_npc_waypoints()


func _on_npc_spawn_requested(npc_data) -> void:
	if npc_scene == null:
		push_error("World: NPC scene not assigned")
		return

	var npc: NPC = npc_scene.instantiate()
	add_child(npc)

	if entrance_pos != null:
		npc.global_position = entrance_pos.global_position

	npc.purchase_completed.connect(_on_npc_purchase)
	npc.npc_exited.connect(_on_npc_exited)
	npc.setup(npc_data)


func _on_npc_purchase(npc: NPC, item_id: String, price: int) -> void:
	EconomyManager.add_gold(price)


func _on_npc_exited(_npc: NPC) -> void:
	pass


func _on_phase_changed(_phase) -> void:
	pass


func _on_target_reached() -> void:
	pass


func _on_daily_report(report: Dictionary) -> void:
	print("=== DAY %d REPORT ===" % report.day)
	print("Revenue: %dG" % report.revenue)
	print("Tax: %dG" % report.tax)
	print("Net Profit: %dG" % report.net_profit)
	print("Total Gold: %dG" % report.total_gold)
	print("Target: %s" % ("REACHED" if report.target_reached else "MISSED"))

	EconomyManager.pay_tax()
	TimeManager.end_day_sequence()


func _on_day_ended(_day: int) -> void:
	pass


func on_normal_item_taken() -> void:
	if mystery_supply != null:
		mystery_supply.on_normal_item_taken()


func _on_human_item_placed(_slot_index: int, _item_id: String) -> void:
	if mystery_supply != null:
		mystery_supply.on_human_item_placed()


func _on_mystery_discovered() -> void:
	var ghost_shelf: Shelf = get_node_or_null("ShelfGhost") as Shelf

	if ghost_shelf != null:
		ghost_shelf.apply_ghost_glow(true)
