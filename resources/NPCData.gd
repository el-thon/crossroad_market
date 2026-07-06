class_name NPCData
extends Resource

enum VisitPhase { MORNING, DAY, NIGHT }
enum PatienceType {IMPATIENT, PATIENT, QUITTER}
enum BlueprintType { IMMEDIATE_LEAVE, QUEUE_ASK, BROWSE_BUY }

@export var npc_id: String = ""
@export var display_name: String = ""
@export var is_special: bool = false
@export var visit_phase: VisitPhase = VisitPhase.DAY
@export var patience_type: PatienceType = PatienceType.PATIENT
@export var blueprint_type: BlueprintType = BlueprintType.QUEUE_ASK  # defaults to patience_type mapping
@export var favorite_items: Array[String] = []
@export var visit_days: Array[int] = []
@export var spawn_order: int = 0
@export var portrait: Texture2D = null

func _get_blueprint() -> BlueprintType:
	# Falls back to patience_type mapping if blueprint_type not explicitly set
	match patience_type:
		PatienceType.IMPATIENT: return BlueprintType.IMMEDIATE_LEAVE
		PatienceType.PATIENT: return BlueprintType.QUEUE_ASK
		PatienceType.QUITTER: return BlueprintType.BROWSE_BUY
	return BlueprintType.QUEUE_ASK
