class_name PurpleSparkleBlink
extends Node2D

const BLINK_COUNT: int = 3
const FADE_DURATION: float = 0.11
const HOLD_DURATION: float = 0.08
const BETWEEN_BLINKS_DURATION: float = 0.1
const SPARKLE_OFFSETS: Array[Vector2] = [
	Vector2(-16, -9),
	Vector2(0, -17),
	Vector2(17, -7),
	Vector2(-21, 8),
	Vector2(4, 4),
	Vector2(20, 13),
]


func _ready() -> void:
	z_index = 120
	modulate.a = 0.0
	_build_sparkles()


func play() -> void:
	for blink_index in BLINK_COUNT:
		scale = Vector2(0.72, 0.72)
		var appear := create_tween()
		appear.set_parallel(true)
		appear.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
		appear.tween_property(self, "scale", Vector2.ONE, FADE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await appear.finished
		await get_tree().create_timer(HOLD_DURATION).timeout

		var disappear := create_tween()
		disappear.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
		await disappear.finished
		if blink_index < BLINK_COUNT - 1:
			await get_tree().create_timer(BETWEEN_BLINKS_DURATION).timeout

	queue_free()


func _build_sparkles() -> void:
	for index in SPARKLE_OFFSETS.size():
		var sparkle := Polygon2D.new()
		sparkle.position = SPARKLE_OFFSETS[index]
		var radius := 4.5 if index % 2 == 0 else 3.0
		sparkle.polygon = _make_sparkle_polygon(radius)
		sparkle.color = (
			Color(0.83, 0.54, 1.0, 1.0)
			if index % 2 == 0
			else Color(0.56, 0.25, 0.95, 1.0)
		)
		add_child(sparkle)


func _make_sparkle_polygon(radius: float) -> PackedVector2Array:
	var inner := radius * 0.22
	return PackedVector2Array([
		Vector2(0, -radius),
		Vector2(inner, -inner),
		Vector2(radius, 0),
		Vector2(inner, inner),
		Vector2(0, radius),
		Vector2(-inner, inner),
		Vector2(-radius, 0),
		Vector2(-inner, -inner),
	])
