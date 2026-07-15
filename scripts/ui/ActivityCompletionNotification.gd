extends Control

@onready var message: Label = $Panel/Message


func _ready() -> void:
	_connect_activity_completion_manager()


func _connect_activity_completion_manager() -> void:
	var manager := get_node_or_null("/root/ActivityCompletionManager")

	if manager == null:
		call_deferred("_connect_activity_completion_manager")
		return

	if manager.has_signal("activity_completion"):
		var show_callable := Callable(self, "_show_message")

		if not manager.activity_completion.is_connected(show_callable):
			manager.activity_completion.connect(show_callable)


func _show_message(msg: String) -> void:
	message.text = msg
	visible = true
	scale = Vector2.ZERO

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	await get_tree().create_timer(2.0).timeout
	_hide()


func _hide() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	tween.finished.connect(func():
		visible = false
	)
