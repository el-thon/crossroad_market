extends Node

signal npc_spawn_requested(npc_data)

const SPAWN_INTERVAL: float = 60.0

var _npc_database: Dictionary = {}
var _day_schedule: Array = []
var _spawn_queue: Array = []
var _spawn_timer: float = 0.0
var _is_spawning: bool = false

func _ready() -> void:
	_load_npc_data()
	TimeManager.day_started.connect(_on_day_started)
	TimeManager.phase_changed.connect(_on_phase_changed)

func _process(delta: float) -> void:
	if not _is_spawning or _spawn_queue.is_empty():
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_next_npc()
		_spawn_timer = SPAWN_INTERVAL

func _load_npc_data() -> void:
	var dir := DirAccess.open("res://data/npcs/")
	if dir == null:
		push_error("NPCScheduler: folder data/npcs/ not found")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var npc = load("res://data/npcs/" + file_name)
			if npc and npc.npc_id != "":
				_npc_database[npc.npc_id] = npc
		file_name = dir.get_next()

func _on_day_started(day: int) -> void:
	_generate_schedule(day)

func _on_phase_changed(phase) -> void:
	if phase == TimeManager.Phase.MORNING:
		if TimeManager.current_day > 1:
			_start_spawning(NPCData.VisitPhase.MORNING)
		else:
			_stop_spawning()
	elif phase == TimeManager.Phase.DAY:
		_start_spawning(NPCData.VisitPhase.DAY)
	elif phase == TimeManager.Phase.NIGHT:
		_start_spawning(NPCData.VisitPhase.NIGHT)

func _generate_schedule(day: int) -> void:
	_day_schedule.clear()

	for npc in _npc_database.values():
		if npc.visit_days.is_empty() or day in npc.visit_days:
			_day_schedule.append(npc)

	_day_schedule.sort_custom(func(a, b): return a.spawn_order < b.spawn_order)

func _start_spawning(phase) -> void:
	_spawn_queue.clear()
	for npc in _day_schedule:
		if npc.visit_phase == phase:
			_spawn_queue.append(npc)
	_is_spawning = true
	_spawn_timer = 5.0

func _stop_spawning() -> void:
	_is_spawning = false
	_spawn_queue.clear()

func _spawn_next_npc() -> void:
	if _spawn_queue.is_empty():
		_is_spawning = false
		return
	var npc_data = _spawn_queue.pop_front()
	npc_spawn_requested.emit(npc_data)
