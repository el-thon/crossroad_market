class_name ItemData
extends Resource

enum ShelfType {
	HUMAN, GHOST
}

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var buy_cost: int = 0
@export var sell_price: int = 0
@export var shelf_type: ShelfType = ShelfType.HUMAN
@export var icon: Texture2D = null
