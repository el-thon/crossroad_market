class_name Dialog
extends Control

## Reusable story dialog overlay.
##
## Assign `character_name`, `content`, and `portrait` in the inspector, or use
## `show_dialog()` when creating the scene from code. Portraits can be a
## single image or a horizontal animation strip; `portrait_frame_width` is
## used to select a frame from a strip.

signal next_requested
signal dialog_finished

@export_category("Dialog")
@export var character_name: String = "Gooby"
@export_multiline var content: String = "I want Phantom Ice Cream Boo..."
@export var next_text: String = "Next..."

@export_category("Portrait")
@export var portrait: Texture2D
@export_range(0, 32, 1) var portrait_frame: int = 0
@export_range(0, 1024, 1) var portrait_frame_width: int = 0
@export var portrait_frame_height: int = 0

@export_category("Behavior")
@export var close_on_next: bool = false
@export var close_on_escape: bool = false

@onready var portrait_view: TextureRect = $Portrait
@onready var name_label: Label = $DialogPanel/NameLabel
@onready var content_label: Label = $DialogPanel/ContentLabel
@onready var next_button: Button = $DialogPanel/NextButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_button.pressed.connect(_on_next_pressed)
	_apply_dialog()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed():
		return

	if event is InputEventKey:
		if event.is_echo():
			return
		if event.keycode == KEY_ESCAPE and close_on_escape:
			hide_dialog()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_on_next_pressed()
			get_viewport().set_input_as_handled()


func show_dialog(
		dialogue_name: String,
		dialogue_content: String,
		dialogue_portrait: Texture2D = null,
		frame: int = 0
	) -> void:
	character_name = dialogue_name
	content = dialogue_content
	portrait = dialogue_portrait
	portrait_frame = frame
	_apply_dialog()
	show()


func hide_dialog() -> void:
	hide()
	dialog_finished.emit()


func set_portrait_frame(frame: int) -> void:
	portrait_frame = max(frame, 0)
	_update_portrait()


func _apply_dialog() -> void:
	if not is_node_ready():
		return

	name_label.text = character_name
	content_label.text = content
	content_label.add_theme_font_size_override("font_size", 12)
	next_button.text = next_text
	_update_portrait()


func _update_portrait() -> void:
	if portrait == null:
		portrait_view.texture = null
		portrait_view.visible = false
		return

	portrait_view.visible = true
	portrait_view.texture = _get_portrait_texture()


func _get_portrait_texture() -> Texture2D:
	if portrait_frame_width <= 0 or portrait_frame_height <= 0:
		return portrait

	var atlas := AtlasTexture.new()
	atlas.atlas = portrait
	atlas.region = Rect2(
		portrait_frame * portrait_frame_width,
		0,
		portrait_frame_width,
		portrait_frame_height
	)
	return atlas


func _on_next_pressed() -> void:
	next_requested.emit()
	if close_on_next:
		hide_dialog()
