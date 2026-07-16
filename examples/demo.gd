extends Node3D
## Compares regular and dashed rectangles.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const RECT_WIDTH := 1.6
const RECT_HEIGHT := 1.0
const RECT_Y := 0.55
const RECT_SPACING := 2.0
const RECT_COLOR := Color(0.2, 0.85, 1.0, 1.0)
const SHORT_DASH_WIDTH := 0.2
const SHORT_DASH_SPACE := 0.1
const LONG_DASH_WIDTH := 0.4
const LONG_DASH_SPACE := 0.15
const DASH_SPEED := 0.3

var _short_dash_offset := 0.0
var _long_dash_offset := 0.0

@onready var _debug_draw = $DebugDraw3D


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(roundi(DESIGN_WIDTH * dpi_scale), roundi(DESIGN_HEIGHT * dpi_scale))
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

  _debug_draw.depth_bias = -0.001
  _debug_draw.line_width = 1.0


func _process(delta: float) -> void:
  _short_dash_offset = fposmod(_short_dash_offset + delta * DASH_SPEED, SHORT_DASH_WIDTH + SHORT_DASH_SPACE)
  _long_dash_offset = fposmod(_long_dash_offset + delta * DASH_SPEED, LONG_DASH_WIDTH + LONG_DASH_SPACE)
  _debug_draw.draw_rect(
    Vector3(-RECT_SPACING, RECT_Y, 0.0),
    Quaternion.IDENTITY,
    RECT_WIDTH,
    RECT_HEIGHT,
    RECT_COLOR,
  )
  _debug_draw.draw_rect_d(
    Vector3(0.0, RECT_Y, 0.0),
    Quaternion.IDENTITY,
    RECT_WIDTH,
    RECT_HEIGHT,
    RECT_COLOR,
    -1.0,
    SHORT_DASH_WIDTH,
    SHORT_DASH_SPACE,
    _short_dash_offset,
  )
  _debug_draw.draw_rect_d(
    Vector3(RECT_SPACING, RECT_Y, 0.0),
    Quaternion.IDENTITY,
    RECT_WIDTH,
    RECT_HEIGHT,
    RECT_COLOR,
    -1.0,
    LONG_DASH_WIDTH,
    LONG_DASH_SPACE,
    _long_dash_offset,
  )
