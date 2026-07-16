class_name FreeCamera
extends Camera3D
## FreeCamera: Godot editor-style 3D debug camera.
##
## Default controls follow the Godot 3D editor: middle mouse to orbit,
## Shift + middle mouse to pan, Ctrl + middle mouse to zoom, wheel/pinch to zoom,
## and right mouse to enter Freelook with WASD/QE movement.

const ORBIT_SENSITIVITY_DEGREES := 0.25
const FREELOOK_SENSITIVITY_DEGREES := 0.25
const TRANSLATION_SENSITIVITY := 1.0
const DISTANCE_DEFAULT := 4.0
const ZOOM_FREELOOK_MIN := 0.01
const ZOOM_FREELOOK_MAX := 10000.0
const ZOOM_FACTOR := 1.08
const ZOOM_DRAG_SPEED := 1.0 / 80.0
const DEFAULT_DISTANCE := 4.0
const FREELOOK_BASE_SPEED := 5.0

@export var initial_distance := DEFAULT_DISTANCE

var _yaw := 0.0
var _pitch := 0.0
var _distance := DEFAULT_DISTANCE
var _freelook_speed := FREELOOK_BASE_SPEED
var _target := Vector3.ZERO
var _freelook_active := false


func _ready() -> void:
  # Derive the orbit state from the editor-authored camera transform instead of hardcoded defaults.
  var forward := -global_transform.basis.z.normalized()
  _pitch = asin(clampf(-forward.y, -1.0, 1.0))
  _yaw = atan2(-forward.z, -forward.x)
  _distance = initial_distance
  _target = global_position + forward * _distance
  _update_camera()


func _process(delta: float) -> void:
  _update_freelook(delta)


func _exit_tree() -> void:
  if _freelook_active:
    set_freelook_active(false)


func _input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
    _handle_mouse_button(event)
  elif event is InputEventMouseMotion:
    _handle_mouse_motion(event)
  elif event is InputEventMagnifyGesture:
    if _freelook_active:
      _scale_freelook_speed(event.factor)
    else:
      _scale_distance(1.0 / event.factor)
  elif event is InputEventPanGesture:
    _handle_pan_gesture(event)


func is_freelook_active() -> bool:
  return _freelook_active


func set_freelook_active(active: bool) -> void:
  if _freelook_active == active:
    return

  _freelook_active = active
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE


func get_info_text() -> String:
  var mode := "Freelook" if _freelook_active else "Orbit"
  return "%s  Dist: %.1f  Speed: %.1f  Yaw: %.0f°  Pitch: %.0f°  Target: (%.1f, %.1f, %.1f)" % [
    mode,
    _distance,
    _freelook_speed,
    rad_to_deg(_yaw),
    rad_to_deg(_pitch),
    _target.x,
    _target.y,
    _target.z,
  ]


func _handle_mouse_button(event: InputEventMouseButton) -> void:
  # Godot editor default: the wheel zooms, or adjusts movement speed in Freelook.
  var wheel_factor := 1.0 + (ZOOM_FACTOR - 1.0) * event.factor
  match event.button_index:
    MOUSE_BUTTON_WHEEL_UP:
      if _freelook_active:
        _scale_freelook_speed(wheel_factor)
      else:
        _scale_distance(1.0 / wheel_factor)
    MOUSE_BUTTON_WHEEL_DOWN:
      if _freelook_active:
        _scale_freelook_speed(1.0 / wheel_factor)
      else:
        _scale_distance(wheel_factor)
    MOUSE_BUTTON_RIGHT:
      set_freelook_active(event.pressed)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
  if _freelook_active:
    _nav_look(event.relative)
    return

  if not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
    return

  # Godot editor default navigation: middle mouse orbits, Shift pans, and Ctrl zooms.
  if event.shift_pressed:
    _nav_pan(event.relative)
  elif event.ctrl_pressed:
    _nav_zoom(event.relative)
  else:
    _nav_orbit(event.relative)


func _handle_pan_gesture(event: InputEventPanGesture) -> void:
  # Match the Godot editor by routing trackpad pan gestures through the same navigation shortcuts.
  if event.shift_pressed:
    _nav_pan(-event.delta)
  elif event.ctrl_pressed:
    _nav_zoom(event.delta)
  else:
    _nav_orbit(-event.delta)


func _nav_orbit(relative: Vector2) -> void:
  var radians_per_pixel := deg_to_rad(ORBIT_SENSITIVITY_DEGREES)
  _pitch = clampf(_pitch + relative.y * radians_per_pixel, -1.57, 1.57)
  _yaw += relative.x * radians_per_pixel
  _update_camera()


func _nav_look(relative: Vector2) -> void:
  var eye_pos := global_position
  var radians_per_pixel := deg_to_rad(FREELOOK_SENSITIVITY_DEGREES)
  _pitch = clampf(_pitch + relative.y * radians_per_pixel, -1.57, 1.57)
  _yaw += relative.x * radians_per_pixel
  _target = eye_pos + _get_forward() * _distance
  _update_camera()


func _nav_pan(relative: Vector2) -> void:
  var pan_speed := TRANSLATION_SENSITIVITY / 150.0
  var scaled_speed := pan_speed * _distance / DISTANCE_DEFAULT
  var right := global_transform.basis.x
  var up := global_transform.basis.y
  _target += (-right * relative.x + up * relative.y) * scaled_speed
  _update_camera()


func _nav_zoom(relative: Vector2) -> void:
  # Godot editor default uses vertical dragging for zoom.
  if relative.y > 0.0:
    _scale_distance(1.0 + relative.y * ZOOM_DRAG_SPEED)
  elif relative.y < 0.0:
    _scale_distance(1.0 / (1.0 - relative.y * ZOOM_DRAG_SPEED))


func _update_freelook(delta: float) -> void:
  if not _freelook_active:
    return

  var direction := Vector3.ZERO
  var forward := global_transform.basis * Vector3.FORWARD
  var right := global_transform.basis * Vector3.RIGHT
  var up := global_transform.basis * Vector3.UP

  if Input.is_key_pressed(KEY_A):
    direction -= right
  if Input.is_key_pressed(KEY_D):
    direction += right
  if Input.is_key_pressed(KEY_W):
    direction += forward
  if Input.is_key_pressed(KEY_S):
    direction -= forward
  if Input.is_key_pressed(KEY_E):
    direction += up
  if Input.is_key_pressed(KEY_Q):
    direction -= up

  if direction.is_zero_approx():
    return

  var speed := _freelook_speed
  if Input.is_key_pressed(KEY_SHIFT):
    speed *= 3.0
  if Input.is_key_pressed(KEY_ALT):
    speed *= 0.333333

  var motion := direction * speed * delta
  _target += motion
  global_position += motion


func _scale_distance(factor: float) -> void:
  _distance = _clamp_editor_zoom_value(_distance * factor)
  _update_camera()


func _scale_freelook_speed(factor: float) -> void:
  _freelook_speed = _clamp_editor_zoom_value(_freelook_speed * factor)


func _clamp_editor_zoom_value(value: float) -> float:
  # Match the Godot editor by clamping against Camera3D near/far instead of fixed project constants.
  var min_value := maxf(near * 4.0, ZOOM_FREELOOK_MIN)
  var max_value := minf(far / 4.0, ZOOM_FREELOOK_MAX)
  if min_value > max_value:
    return (min_value + max_value) * 0.5
  return clampf(value, min_value, max_value)


func _get_forward() -> Vector3:
  return Vector3(-cos(_pitch) * cos(_yaw), -sin(_pitch), -cos(_pitch) * sin(_yaw)).normalized()


func _update_camera() -> void:
  position = _target - _get_forward() * _distance
  look_at(_target)
