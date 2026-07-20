extends Node


@warning_ignore("unused_signal")
signal activity_completion(message: String)

@warning_ignore("unused_private_class_variable")
var _notifier: ActivityCompletionNotifier = ActivityCompletionNotifier.new()


func _ready() -> void:
	_notifier.setup(self)


func notify(message: String) -> void:
	_notifier.notify(message)
