extends CanvasLayer

@onready var gold_label: Label = $GoldLabel
@onready var target_label: Label = $TargetLabel
@onready var time_label: Label = $TimeLabel
@onready var phase_label: Label = $PhaseLabel
@onready var day_label: Label = $DayLabel
@onready var notification_label: Label = $NotificationLabel

const NOTIFY_DURATION: float = 2.0

var _notify_timer: float = 0.0
var _notify_duration: float = NOTIFY_DURATION
var _notify_full_chars: int = 0


func _ready() -> void:
	add_to_group("hud")

	EconomyManager.gold_changed.connect(_on_gold_changed)
	EconomyManager.daily_target_reached.connect(_on_target_reached)
	TimeManager.time_updated.connect(_on_time_updated)
	TimeManager.phase_changed.connect(_on_phase_changed)
	TimeManager.day_started.connect(_on_day_started)

	_update_all()

	notification_label.visible = false
	notification_label.modulate.a = 0.0
	notification_label.visible_characters = 0


func _process(delta: float) -> void:
	if _notify_timer <= 0.0:
		return

	_notify_timer -= delta

	var elapsed: float = _notify_duration - _notify_timer
	var progress: float = clamp(elapsed / _notify_duration, 0.0, 1.0)

	var reveal_progress: float = clamp(progress / 0.35, 0.0, 1.0)
	notification_label.visible_characters = int(reveal_progress * _notify_full_chars)

	if progress < 0.75:
		notification_label.modulate.a = 1.0
	else:
		var fade_progress: float = clamp((progress - 0.75) / 0.25, 0.0, 1.0)
		notification_label.modulate.a = 1.0 - fade_progress

	if _notify_timer <= 0.0:
		notification_label.modulate.a = 0.0
		notification_label.visible_characters = 0
		notification_label.visible = false


func show_notification(text: String, duration: float = NOTIFY_DURATION) -> void:
	notification_label.visible = true
	notification_label.text = text
	_notify_full_chars = text.length()
	_notify_duration = max(duration, 0.1)
	_notify_timer = _notify_duration
	notification_label.visible_characters = 0
	notification_label.modulate.a = 1.0


func _update_all() -> void:
	_on_gold_changed(EconomyManager.gold)
	_on_day_started(TimeManager.current_day)
	_on_phase_changed(TimeManager.current_phase)
	_on_time_updated(TimeManager.time_remaining)

	target_label.text = "Target: %dG" % EconomyManager.daily_target


func _on_gold_changed(amount: int) -> void:
	gold_label.text = "Gold: %dG" % amount
	target_label.text = "%dG / %dG" % [
		EconomyManager.daily_revenue,
		EconomyManager.daily_target
	]


func _on_target_reached() -> void:
	target_label.text = "%dG / %dG  TARGET ACHIEVED" % [
		EconomyManager.daily_revenue,
		EconomyManager.daily_target
	]


func _on_time_updated(seconds: float) -> void:
	var total_seconds: int = int(seconds)
	var m: int = int(total_seconds / 60)
	var s: int = total_seconds % 60

	time_label.text = "%02d:%02d" % [m, s]


func _on_phase_changed(_phase) -> void:
	phase_label.text = TimeManager.get_phase_name()


func _on_day_started(day: int) -> void:
	day_label.text = "Day %d" % day