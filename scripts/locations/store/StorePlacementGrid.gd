class_name StorePlacementGrid
extends RefCounted

var origin: Vector2 = Vector2.ZERO
var cell_size: Vector2 = Vector2(40, 24)
var columns: int = 1
var rows: int = 1


func _init(
	grid_origin: Vector2 = Vector2.ZERO,
	grid_cell_size: Vector2 = Vector2(40, 24),
	grid_columns: int = 1,
	grid_rows: int = 1
) -> void:
	setup(grid_origin, grid_cell_size, grid_columns, grid_rows)


func setup(
	grid_origin: Vector2,
	grid_cell_size: Vector2,
	grid_columns: int,
	grid_rows: int
) -> void:
	origin = grid_origin
	cell_size = Vector2(maxf(1.0, grid_cell_size.x), maxf(1.0, grid_cell_size.y))
	columns = maxi(1, grid_columns)
	rows = maxi(1, grid_rows)


func get_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []

	for row in range(rows):
		for column in range(columns):
			positions.append(origin + Vector2(cell_size.x * column, cell_size.y * row))

	return positions
