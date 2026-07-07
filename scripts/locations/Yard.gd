extends Node2D

signal return_to_store(door_type: String)

@onready var return_door: Area2D = get_node_or_null("ReturnDoor") as Area2D


func _ready() -> void:
	add_to_group("location")
	add_to_group("yard")

	if return_door == null:
		push_error("Yard: ReturnDoor is missing.")
		return

	if not return_door.body_entered.is_connected(_on_return_door_entered):
		return_door.body_entered.connect(_on_return_door_entered)


func _on_return_door_entered(body: Node) -> void:
	if _is_action_locked():
		return

	if body.is_in_group("player"):
		return_to_store.emit("yard")


func _is_action_locked() -> bool:
	var hud: Node = get_tree().get_first_node_in_group("hud")

	if hud == null or not hud.has_method("is_action_locked"):
		return false

	return bool(hud.call("is_action_locked"))
