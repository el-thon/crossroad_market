extends Node

signal gold_changed(new_amount: int)
signal daily_target_reached()
signal daily_report_ready(report: Dictionary)

var gold: int = 0
var daily_revenue: int = 0
var daily_expenses: int = 0
var daily_target: int = 50
var _daily_target_reached: bool = false

# tax increases per day (index = day - 1)
var _tax_per_day: Array[int] = [10, 10, 15, 15, 20, 25]

func _ready() -> void:
	TimeManager.day_started.connect(_on_day_started)
	TimeManager.day_ended.connect(_on_day_ended)

func add_gold(amount: int) -> void:
	gold += amount
	daily_revenue += amount
	gold_changed.emit(gold)

	if not _daily_target_reached and daily_revenue >= daily_target:
		_daily_target_reached = true
		daily_target_reached.emit()

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	daily_expenses += amount
	gold_changed.emit(gold)
	return true

func get_daily_tax() -> int:
	var day_index: int = TimeManager.current_day - 1
	if day_index >= 0 and day_index < _tax_per_day.size():
		return _tax_per_day[day_index]
	return _tax_per_day[-1]

func pay_tax() -> bool:
	var tax := get_daily_tax()
	return spend_gold(tax)

func get_daily_report() -> Dictionary:
	return {
		"day": TimeManager.current_day,
		"revenue": daily_revenue,
		"expenses": daily_expenses,
		"tax": get_daily_tax(),
		"net_profit": daily_revenue - daily_expenses - get_daily_tax(),
		"total_gold": gold,
		"target": daily_target,
		"target_reached": daily_revenue >= daily_target
	}

func _on_day_started(_day: int) -> void:
	daily_revenue = 0
	daily_expenses = 0
	_daily_target_reached = false

func _on_day_ended(_day: int) -> void:
	var report := get_daily_report()
	daily_report_ready.emit(report)
