extends Node2D

signal return_to_store(door_type: String)
signal enter_home()

@onready var return_door: Area2D = get_node_or_null("ReturnDoor") as Area2D
@onready var home_door: Area2D = get_node_or_null("PlayerHomeArea/HomeDoor") as Area2D


func _ready() -> void:
	add_to_group("location")
	add_to_group("yard")

	if return_door == null:
		push_error("Yard: ReturnDoor is missing.")
		return

	return_door.set_meta("door_type", "yard_return")

	if home_door == null:
		push_error("Yard: HomeDoor is missing.")
	else:
		home_door.set_meta("door_type", "home")


func request_return_to_store() -> bool:
	if _is_action_locked():
		return false

	return_to_store.emit("yard")
	return true


func request_enter_home() -> bool:
	if _is_action_locked():
		return false

	enter_home.emit()
	return true


func _is_action_locked() -> bool:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null or not hud.has_method("is_action_locked"):
		return false

	return bool(hud.call("is_action_locked"))
