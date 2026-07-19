class_name NPCSchedulerSessionRuntime
extends RefCounted

var scheduler: Node = null


func setup(scheduler_node: Node) -> void:
	scheduler = scheduler_node


func are_customer_sessions_complete_for_day() -> bool:
	if scheduler._customer_sessions.is_empty():
		return true

	for session in scheduler._customer_sessions.values():
		if not (session is Dictionary):
			continue

		var data := session as Dictionary
		var pool := data.get("pool", []) as Array[NPCData]
		var index := int(data.get("index", 0))

		if index < pool.size() and not bool(data.get("closed", false)):
			return false

	return true


func close_customer_sessions_for_day() -> void:
	for session_name in scheduler._customer_sessions.keys():
		var session := scheduler._customer_sessions[session_name] as Dictionary
		var pool := session.get("pool", []) as Array[NPCData]
		var index := int(session.get("index", 0))
		session["missed"] = int(session.get("missed", 0)) + maxi(0, pool.size() - index)
		session["index"] = pool.size()
		session["closed"] = true
		scheduler._customer_sessions[session_name] = session

	scheduler._active_customer_session = scheduler.SESSION_NONE
	scheduler._is_spawning = false
	scheduler._spawn_queue.clear()


func start_night_customer_session() -> void:
	if scheduler._active_customer_session == scheduler.SESSION_NIGHT:
		return

	finish_active_customer_session()
	start_customer_session(scheduler.SESSION_NIGHT)


func reset_customer_sessions() -> void:
	scheduler._customer_sessions.clear()
	scheduler._active_customer_session = scheduler.SESSION_NONE


func process_active_customer_session() -> void:
	if scheduler._active_customer_session == scheduler.SESSION_NONE or not scheduler._customer_sessions.has(scheduler._active_customer_session):
		return

	var session := scheduler._customer_sessions[scheduler._active_customer_session] as Dictionary

	if bool(session.get("closed", false)):
		return

	var pool := session.get("pool", []) as Array[NPCData]
	var slots := session.get("slots", []) as Array[int]
	var index := int(session.get("index", 0))

	if index >= pool.size():
		return

	var current_minutes := TimeManager.get_current_clock_minutes()

	if current_minutes >= TimeManager.END_START_MINUTES:
		finish_active_customer_session()
		return

	while index < slots.size():
		var slot_minutes := slots[index]

		if current_minutes < slot_minutes:
			return

		var session_can_spawn: bool = scheduler._active_customer_session != scheduler.SESSION_NIGHT or scheduler._spawning_unlocked

		if scheduler._store_open and session_can_spawn:
			scheduler.npc_spawn_requested.emit(pool[index])
		else:
			session["missed"] = int(session.get("missed", 0)) + 1

		index += 1
		session["index"] = index
		scheduler._customer_sessions[scheduler._active_customer_session] = session


func start_customer_session(session_name: StringName) -> void:
	if not scheduler._customer_sessions.has(session_name):
		scheduler._active_customer_session = scheduler.SESSION_NONE
		return

	scheduler._active_customer_session = session_name


func finish_active_customer_session() -> void:
	if scheduler._active_customer_session == scheduler.SESSION_NONE or not scheduler._customer_sessions.has(scheduler._active_customer_session):
		return

	var session := scheduler._customer_sessions[scheduler._active_customer_session] as Dictionary
	var pool := session.get("pool", []) as Array[NPCData]
	var index := int(session.get("index", 0))
	session["missed"] = int(session.get("missed", 0)) + maxi(0, pool.size() - index)
	session["index"] = pool.size()
	session["closed"] = true
	scheduler._customer_sessions[scheduler._active_customer_session] = session


func get_active_interaction_blueprints() -> Array:
	var blueprints: Array = []

	if scheduler._active_customer_session == scheduler.SESSION_NONE or not scheduler._customer_sessions.has(scheduler._active_customer_session):
		return blueprints

	var session := scheduler._customer_sessions[scheduler._active_customer_session] as Dictionary
	var raw_blueprints: Array = session.get("behavior_blueprints", [])

	for blueprint in raw_blueprints:
		if blueprint is Resource and blueprint.get("id") != null:
			blueprints.append(blueprint)

	return blueprints


func notify_npc_shelf_route_ready(travel_seconds: float) -> void:
	if scheduler._active_customer_session == scheduler.SESSION_NONE or not scheduler._customer_sessions.has(scheduler._active_customer_session):
		return

	var session := scheduler._customer_sessions[scheduler._active_customer_session] as Dictionary

	if bool(session.get("interaction_timing_adjusted", false)):
		return

	var blueprints := get_active_interaction_blueprints()

	if blueprints.is_empty():
		return

	var pool := session.get("pool", []) as Array[NPCData]
	var slots := session.get("slots", []) as Array[int]
	var index := int(session.get("index", 0))

	if index >= pool.size() or index >= slots.size():
		return

	var blueprint: Resource = blueprints[0] as Resource
	var phase_world_minutes: int = TimeManager.get_phase_world_duration_minutes(TimeManager.current_phase)
	var travel_minutes: float = travel_seconds * float(phase_world_minutes) / TimeManager.PHASE_DURATION
	var delay: float = clamp(
		travel_minutes * float(blueprint.get("meet_progress")),
		float(blueprint.get("min_delay")),
		float(blueprint.get("max_delay"))
	)
	var current_minutes: float = TimeManager.get_precise_clock_minutes()
	var adjusted_slot := int(round(current_minutes + delay))
	var original_slot := int(slots[index])
	var window_end := int(session.get("window_end", scheduler.HUMAN_CUSTOMER_END_MINUTES))

	adjusted_slot = mini(adjusted_slot, window_end)

	if adjusted_slot < original_slot:
		slots[index] = adjusted_slot
		session["slots"] = slots
		session["interaction_timing_adjusted"] = true
		scheduler._customer_sessions[scheduler._active_customer_session] = session
