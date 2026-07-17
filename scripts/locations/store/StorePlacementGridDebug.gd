@tool
class_name StorePlacementGridDebug
extends Node2D

@export var grid_origin: Vector2 = Vector2(25, 112):
	set(value):
		grid_origin = value
		queue_redraw()
@export var grid_cell_size: Vector2 = Vector2(40, 24):
	set(value):
		grid_cell_size = Vector2(maxf(1.0, value.x), maxf(1.0, value.y))
		queue_redraw()
@export_range(1, 64, 1) var grid_columns: int = 11:
	set(value):
		grid_columns = maxi(1, value)
		queue_redraw()
@export_range(1, 32, 1) var grid_rows: int = 7:
	set(value):
		grid_rows = maxi(1, value)
		queue_redraw()
@export var visible_in_game: bool = false
@export var point_radius: float = 2.0:
	set(value):
		point_radius = maxf(0.5, value)
		queue_redraw()
@export var grid_color: Color = Color(0.2, 0.85, 1.0, 0.26):
	set(value):
		grid_color = value
		queue_redraw()
@export var point_color: Color = Color(0.3, 1.0, 0.7, 0.88):
	set(value):
		point_color = value
		queue_redraw()
@export var border_color: Color = Color(0.8, 1.0, 0.2, 0.35):
	set(value):
		border_color = value
		queue_redraw()


func _ready() -> void:
	if not Engine.is_editor_hint() and not visible_in_game:
		visible = false
	set_process(Engine.is_editor_hint())
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cell_size := Vector2(maxf(1.0, grid_cell_size.x), maxf(1.0, grid_cell_size.y))
	var columns := maxi(1, grid_columns)
	var rows := maxi(1, grid_rows)
	var end_x := grid_origin.x + cell_size.x * float(columns - 1)
	var end_y := grid_origin.y + cell_size.y * float(rows - 1)
	var half_cell := cell_size * 0.5
	var border_rect := Rect2(grid_origin - half_cell, Vector2(end_x - grid_origin.x, end_y - grid_origin.y) + cell_size)

	draw_rect(border_rect, border_color, false, 1.0)

	for row in range(rows):
		var y := grid_origin.y + cell_size.y * float(row)
		draw_line(Vector2(grid_origin.x, y), Vector2(end_x, y), grid_color, 1.0)

	for column in range(columns):
		var x := grid_origin.x + cell_size.x * float(column)
		draw_line(Vector2(x, grid_origin.y), Vector2(x, end_y), grid_color, 1.0)

	for row in range(rows):
		for column in range(columns):
			var position := grid_origin + Vector2(cell_size.x * float(column), cell_size.y * float(row))
			draw_circle(position, point_radius, point_color)
