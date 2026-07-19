class_name NPCInteractionBlueprint
extends Resource

@export var id: String = ""
@export var category: StringName = &"general_small_talk"
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0
@export_range(8.0, 96.0, 1.0) var proximity_radius: float = 28.0
@export_range(0.25, 8.0, 0.25) var pause_duration: float = 2.0
@export_range(0.0, 60.0, 0.5) var cooldown: float = 12.0
@export_range(1, 20, 1) var max_per_session: int = 1
@export_range(0.0, 1.0, 0.05) var meet_progress: float = 0.55
@export_range(0, 180, 1) var min_delay: int = 10
@export_range(0, 180, 1) var max_delay: int = 60
@export_range(8.0, 64.0, 1.0) var face_distance: float = 18.0
@export var dialog_lines: Array[String] = []
