extends Node

enum Phase {MORNING, DAY, NIGHT}

const PHASE_DURATION = 60.0 # seconds
const TOTAL_DAYS: int = 6

signal phase_changed(new_phase: Phase)
signal day_started(day: int)
signal day_ended(day: int)
signal time_updated(seconds_remaining: float)

var current_day: int = 1
var current_phase: Phase = Phase.MORNING
var time_remaining: float = PHASE_DURATION
var is_running: bool = true

func _process(delta: float) -> void:
	if not is_running:
		return

	time_remaining -= delta
	time_updated.emit(time_remaining)

	if time_remaining <= 0.0:
		_advance_phase()

func start_game() -> void:
	current_day = 1
	is_running = true
	_set_phase(Phase.MORNING)
	day_started.emit(current_day)

func start_next_day() -> void:
	if current_day >= TOTAL_DAYS:
		return
	current_day += 1
	_set_phase(Phase.MORNING)
	day_started.emit(current_day)

func end_day_sequence() -> void:
	start_next_day()

func pause() -> void:
	is_running = false

func resume() -> void:
	is_running = true

func get_phase_name() -> String:
	match current_phase:
		Phase.MORNING: return "Morning"
		Phase.DAY: return "Day"
		Phase.NIGHT: return "Night"
	return "Unknown"

func get_time_display() -> String:
	var total: int = int(time_remaining)
	var m: int = total / 60
	var s: int = total % 60
	return "%02d:%02d" % [m, s]

func _advance_phase() -> void:
	match current_phase:
		Phase.MORNING:
			_set_phase(Phase.DAY)
		Phase.DAY:
			_set_phase(Phase.NIGHT)
		Phase.NIGHT:
			is_running = false
			day_ended.emit(current_day)

func _set_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	time_remaining = PHASE_DURATION
	phase_changed.emit(current_phase)
