extends CanvasLayer
class_name VirtualJoystick

@onready var knob: TextureRect = $Knob
@onready var button: BaseButton = $Button
@onready var ring: TextureRect = $Ring

var radius: float = 80.0
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	button.gui_input.connect(_on_button_gui_input)
	visible = OS.has_feature("mobile")

func _on_button_pressed() -> void:
	knob.position = Vector2.ZERO
	drag_offset = Vector2.ZERO

func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed:
		knob.position = Vector2.ZERO
		drag_offset = Vector2.ZERO
	elif event is InputEventScreenTouch:
		var touch_pos: Vector2 = (event as InputEventScreenTouch).position
		var local_touch_pos: Vector2 = ring.to_local(touch_pos)
		drag_offset = local_touch_pos.limit_length(radius)
		knob.position = drag_offset
	elif event is InputEventScreenDrag:
		var drag_pos: Vector2 = (event as InputEventScreenDrag).position
		var local_drag_pos: Vector2 = ring.to_local(drag_pos)
		drag_offset = local_drag_pos.limit_length(radius)
		knob.position = drag_offset

func get_normalized_vector() -> Vector2:
	return drag_offset.normalized()


func _on_btn_dash_pressed() -> void:
	Input.action_press("Dash")
