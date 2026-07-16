class_name SleepBed
extends Area2D


func _ready() -> void:
	input_pickable = true


func get_hover_display_name() -> String:
	return "Bed"


func request_interaction() -> bool:
	if TimeManager.sleep_until_next_day():
		_show_notification("You rest until morning.", 1.0)
		return true

	_show_notification("It's too early to sleep.", 1.0)
	return false


func _show_notification(text: String, duration: float) -> void:
	var hud := get_tree().get_first_node_in_group("hud")

	if hud != null and hud.has_method("show_notification"):
		hud.call("show_notification", text, duration, false)
