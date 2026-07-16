extends Node2D

signal return_to_yard(door_type: String)

@onready var return_door: Area2D = get_node_or_null("ReturnDoor") as Area2D


func _ready() -> void:
	add_to_group("location")
	add_to_group("home")

	if return_door == null:
		push_error("Home: ReturnDoor is missing.")
		return

	return_door.set_meta("door_type", "home_return")


func request_return_to_yard() -> bool:
	if _is_action_locked():
		return false

	return_to_yard.emit("home")
	return true


func _is_action_locked() -> bool:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null or not hud.has_method("is_action_locked"):
		return false

	return bool(hud.call("is_action_locked"))
