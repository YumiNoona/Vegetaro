extends CanvasLayer
class_name VirtualJoystick

signal movement_changed(direction: Vector2)

@export var force_visible: bool = false  # Set to true in editor to test on PC (disabled for production)
@export var enable_mouse_input: bool = false  # Disabled - mobile touch input only

@onready var knob: TextureRect = $Knob
@onready var move_button: BaseButton = $BTN_Move
@onready var ring: TextureRect = $Ring
@onready var dash_button: BaseButton = $BTN_Dash

var radius: float = 150.0  # Increased radius for better mobile control
var drag_offset: Vector2 = Vector2.ZERO
var is_active: bool = false
var knob_center: Vector2

func _ready() -> void:
	# Show only on mobile devices (or if force_visible is enabled for testing in editor)
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("Android") or OS.has_feature("iOS")
	visible = force_visible or is_mobile
	
	# Disable mouse input if not on mobile (unless force_visible is set for testing)
	if not is_mobile and not force_visible:
		enable_mouse_input = false
	
	# Wait one frame to ensure all nodes are properly positioned
	await get_tree().process_frame
	
	_setup_joystick()

func _setup_joystick() -> void:
	# Wait another frame to ensure viewport is ready
	await get_tree().process_frame
	
	# Get the actual rects after anchors are applied
	var ring_rect = ring.get_rect()
	var knob_rect = knob.get_rect()
	
	# Calculate ring center in local coordinates
	var ring_center_local = ring_rect.position + ring_rect.size / 2.0
	
	# Calculate knob center position (knob should be centered on ring)
	# knob.position is the top-left corner, so center it on the ring
	knob_center = ring_center_local - knob_rect.size / 2.0
	
	# Set initial knob position
	knob.position = knob_center
	
	# Store the ring center in global coordinates for later use
	# This will be recalculated in _update_joystick_position, but we can cache it here if needed
	
	# Connect button signals
	move_button.button_down.connect(_on_button_pressed)
	move_button.button_up.connect(_on_button_released)
	move_button.gui_input.connect(_on_button_gui_input)
	
	# Connect dash button (check if not already connected from scene)
	if dash_button:
		if not dash_button.pressed.is_connected(_on_btn_dash_pressed):
			dash_button.pressed.connect(_on_btn_dash_pressed)
		dash_button.gui_input.connect(_on_dash_button_gui_input)
	
	# Also handle touch events on the ring area
	ring.gui_input.connect(_on_ring_gui_input)
	
	# Enable mouse input for testing on PC
	if enable_mouse_input:
		move_button.mouse_filter = Control.MOUSE_FILTER_STOP
		ring.mouse_filter = Control.MOUSE_FILTER_STOP
		if dash_button:
			dash_button.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_button_pressed() -> void:
	is_active = true

func _on_button_released() -> void:
	_reset_joystick()

func _on_button_gui_input(event: InputEvent) -> void:
	_handle_input_event(event, move_button)

func _on_ring_gui_input(event: InputEvent) -> void:
	_handle_input_event(event, ring)

func _handle_input_event(event: InputEvent, source_control: Control = null) -> void:
	# Handle touch input (mobile)
	if event is InputEventScreenTouch:
		if event.pressed:
			# For touch events received via gui_input, position might be in local coordinates
			# Convert to global/viewport coordinates
			var touch_pos: Vector2
			if source_control:
				# Convert local position to global/viewport coordinates
				touch_pos = source_control.to_global(event.position)
			else:
				# Fallback: use position directly (should be viewport coords for screen touch)
				touch_pos = event.position
			
			# Get ring center in global/viewport coordinates
			var ring_rect = ring.get_global_rect()
			var ring_center_global = ring_rect.position + ring_rect.size / 2.0
			var distance_to_center = touch_pos.distance_to(ring_center_global)
			# Only activate if touch is within reasonable distance (2.5x radius for easier activation)
			var ring_radius = (ring_rect.size.x / 2.0) * 2.5
			if distance_to_center <= ring_radius:
				is_active = true
				_update_joystick_position(touch_pos)
		else:
			_reset_joystick()
	elif event is InputEventScreenDrag:
		if is_active:
			# Drag events: convert to global coordinates if we have a source control
			var drag_pos: Vector2
			if source_control:
				drag_pos = source_control.to_global(event.position)
			else:
				drag_pos = event.position
			_update_joystick_position(drag_pos)
	# Handle mouse input (for testing on PC)
	elif enable_mouse_input and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Use global_position for mouse events (it's in viewport coordinates)
				var mouse_pos: Vector2 = event.global_position
				var ring_rect = ring.get_global_rect()
				var ring_center_global = ring_rect.position + ring_rect.size / 2.0
				var distance_to_center = mouse_pos.distance_to(ring_center_global)
				var ring_radius = (ring_rect.size.x / 2.0) * 2.5  # 2.5x radius for easier activation
				if distance_to_center <= ring_radius:
					is_active = true
					_update_joystick_position(mouse_pos)
			else:
				_reset_joystick()
	elif enable_mouse_input and event is InputEventMouseMotion:
		if is_active and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			# Use global_position for mouse events (it's in viewport coordinates)
			var mouse_pos: Vector2 = event.global_position
			_update_joystick_position(mouse_pos)

func _update_joystick_position(event_pos: Vector2) -> void:
	# event_pos should be in viewport/global coordinates
	# Get ring center in global coordinates
	var ring_rect_global = ring.get_global_rect()
	var ring_center_global = ring_rect_global.position + ring_rect_global.size / 2.0
	
	# Calculate offset from ring center
	var offset_from_center = event_pos - ring_center_global
	
	# Debug: Uncomment to debug on mobile
	# print("Touch pos: ", event_pos, " Ring center: ", ring_center_global, " Offset: ", offset_from_center, " X: ", offset_from_center.x, " Y: ", offset_from_center.y)
	
	# Limit the offset to the joystick radius
	var ring_radius = (ring_rect_global.size.x / 2.0) * 0.8
	var scaled_radius = min(radius, ring_radius)
	var limited_offset = offset_from_center.limit_length(scaled_radius)
	
	# Store offset for movement direction (this is the direction vector)
	# This offset represents the direction: positive X = right, positive Y = down
	drag_offset = limited_offset
	
	# Update knob position using the stored knob_center (calculated in local coords)
	# The offset needs to be in the same coordinate space as knob_center
	# Since both are in CanvasLayer, and CanvasLayer uses viewport coordinates,
	# we can use the offset directly, but we calculated knob_center in local space
	# So we need to convert: get the ring center in local space and use that
	var ring_rect_local = ring.get_rect()
	var ring_center_local = ring_rect_local.position + ring_rect_local.size / 2.0
	var knob_rect_local = knob.get_rect()
	var knob_center_local = ring_center_local - knob_rect_local.size / 2.0
	
	# The limited_offset is in global/viewport coordinates
	# For CanvasLayer, we can use it directly since CanvasLayer uses viewport coords
	knob.position = knob_center_local + limited_offset
	
	emit_movement_changed()

func _reset_joystick() -> void:
	is_active = false
	knob.position = knob_center
	drag_offset = Vector2.ZERO
	# Debug print (uncomment if needed)
	# print("Joystick reset - knob.position: ", knob.position)
	emit_movement_changed()

func emit_movement_changed() -> void:
	movement_changed.emit(get_normalized_vector())

func get_normalized_vector() -> Vector2:
	if drag_offset.length() < 0.1:
		return Vector2.ZERO
	var normalized = drag_offset.normalized()
	# Debug: Uncomment to see joystick direction on mobile
	# print("Joystick drag_offset: ", drag_offset, " normalized: ", normalized)
	return normalized

func get_movement_direction() -> Vector2:
	return get_normalized_vector()

func _on_btn_dash_pressed() -> void:
	Input.action_press("Dash")
	# Also trigger the dash action directly
	await get_tree().process_frame
	Input.action_release("Dash")

func _on_dash_button_gui_input(event: InputEvent) -> void:
	# Handle touch input for dash button
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_btn_dash_pressed()
	elif enable_mouse_input and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_btn_dash_pressed()
