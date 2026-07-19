class_name NPCScheduleBlueprint
extends Resource

@export var day: int = 1
@export var session_name: StringName = &"human"
@export_range(0, 32, 1) var customer_count: int = 0
@export_range(0, 1440, 10) var window_start: int = 360
@export_range(0, 1440, 10) var window_end: int = 1080
@export_range(0, 180, 1) var min_interval: int = 20
@export_range(0, 180, 1) var max_interval: int = 180
@export var customer_pool: String = ""
@export var behavior_blueprints: Array[Resource] = []
