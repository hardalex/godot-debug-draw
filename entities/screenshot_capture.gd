extends Node
## Captures the current scene at 1080p when P is pressed.

const SCREENSHOT_SIZE := Vector2i(1920, 1080)
const SCREENSHOT_DIRECTORY := "res://media"

var _is_capturing := false


func _unhandled_key_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
    get_viewport().set_input_as_handled()
    _capture()


func _capture() -> void:
  if _is_capturing:
    return

  _is_capturing = true
  var directory_path := ProjectSettings.globalize_path(SCREENSHOT_DIRECTORY)
  var directory_error := DirAccess.make_dir_recursive_absolute(directory_path)
  if directory_error != OK:
    push_error("Could not create screenshot directory: %s" % directory_path)
    _is_capturing = false
    return

  var scene_copy := get_tree().current_scene.duplicate()

  var screenshot_viewport := SubViewport.new()
  screenshot_viewport.size = SCREENSHOT_SIZE
  screenshot_viewport.own_world_3d = true
  screenshot_viewport.msaa_2d = get_viewport().msaa_2d
  screenshot_viewport.msaa_3d = get_viewport().msaa_3d
  screenshot_viewport.screen_space_aa = get_viewport().screen_space_aa
  screenshot_viewport.use_taa = get_viewport().use_taa
  screenshot_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
  add_child(screenshot_viewport)
  screenshot_viewport.add_child(scene_copy)
  screenshot_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

  await RenderingServer.frame_post_draw
  var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
  var path := "%s/screenshot-%s-%d.png" % [SCREENSHOT_DIRECTORY, timestamp, Time.get_ticks_msec()]
  var save_error := screenshot_viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
  screenshot_viewport.queue_free()
  _is_capturing = false

  if save_error != OK:
    push_error("Could not save screenshot: %s" % path)
    return

  print("Screenshot saved: %s" % ProjectSettings.globalize_path(path))
