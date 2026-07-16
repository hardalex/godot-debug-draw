extends Node3D
## Flat all-API DebugDraw3D sample scene.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const ORIGIN_X := 1.0
const ORIGIN_Z := -1.0
const COLUMN_SPACING := 2.0
const ROW_SPACING := 1.25
const SAMPLE_Y := 0.55
const LABEL_Y := 0.08
const TITLE_Z := 0.25
const SAMPLE_LABEL_GAP := 0.12
const LABEL_FONT_SIZE := 18
const TITLE_LABEL_FONT_SIZE := 24
const LABEL_PIXEL_SIZE := 0.004
const DASH_OFFSET := 0.0
const DASH_WIDTH := 0.16
const DASH_SPACE := 0.09
const COLUMN_LABELS := [
  "line",
  "ray",
  "arrow",
  "axes",
  "line_list",
  "strip",
  "loop",
  "curve",
  "grid",
  "rect",
  "box",
  "circle",
  "arc",
  "sphere",
  "cone",
  "cylinder",
  "capsule",
]
const ROW_LABELS := [
  ["draw_line", "draw_line_n", "draw_line_d", "draw_line_n_d"],
  ["draw_ray", "draw_ray_n", "draw_ray_d", "draw_ray_n_d"],
  ["draw_arrow", "draw_arrow_n", "draw_arrow_line", "draw_arrow_line_n", "draw_arrow_line_d", "draw_arrow_line_n_d"],
  ["draw_axes", "draw_axes_n"],
  ["draw_line_list", "draw_line_list_n"],
  ["draw_line_strip", "draw_line_strip_n", "draw_line_strip_d", "draw_line_strip_n_d"],
  ["draw_line_loop", "draw_line_loop_n", "draw_line_loop_d", "draw_line_loop_n_d"],
  ["draw_curve", "draw_curve_d"],
  ["draw_grid", "draw_grid_n"],
  ["draw_rect", "draw_rect_s", "draw_rect_n", "draw_rect_d", "draw_rect_n_d"],
  ["draw_box", "draw_box_s", "draw_box_n", "draw_box_d", "draw_box_n_d"],
  ["draw_circle", "draw_circle_n", "draw_circle_d", "draw_circle_n_d"],
  ["draw_arc", "draw_arc_n", "draw_arc_d", "draw_arc_n_d"],
  ["draw_sphere", "draw_sphere_s", "draw_sphere_n", "draw_sphere_d", "draw_sphere_n_d"],
  ["draw_cone", "draw_cone_s", "draw_cone_n"],
  ["draw_cylinder", "draw_cylinder_s", "draw_cylinder_n"],
  ["draw_capsule", "draw_capsule_n"],
]

var _curve: Curve3D

@onready var _debug_draw: DebugDraw3D = $DebugDraw3D


func _ready() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(roundi(DESIGN_WIDTH * dpi_scale), roundi(DESIGN_HEIGHT * dpi_scale))
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

  _debug_draw.depth_bias = -0.001
  _debug_draw.line_width = 2.0
  _debug_draw.round_joint_resolution = 8
  _debug_draw.miter_limit = 4.0

  _curve = Curve3D.new()
  _curve.add_point(Vector3(-0.45, -0.15, 0.0), Vector3.ZERO, Vector3(0.25, 0.4, 0.0))
  _curve.add_point(Vector3(0.15, 0.25, 0.25), Vector3(-0.25, 0.35, 0.0), Vector3(0.25, -0.35, 0.0))
  _curve.add_point(Vector3(0.65, -0.15, 0.45), Vector3(-0.25, -0.35, 0.0), Vector3.ZERO)

  _create_labels()


func _process(_delta: float) -> void:
  _debug_draw.draw_axes(Vector3.ZERO, Quaternion.IDENTITY, 0.75, 2.0)

  _debug_draw.draw_line(_p(0, 0), _p(0, 0, 1.0, 0.0, 0.9), Color.WHITE, 2.0)
  _debug_draw.draw_line_n(_p(0, 1), _p(0, 1, 1.0, 0.0, 0.9), Vector3.UP, Color(0.35, 1.0, 1.0), 2.0)
  _debug_draw.draw_line_d(_p(0, 2), _p(0, 2, 1.0, 0.0, 0.9), Color(1.0, 0.75, 0.25), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET)
  _debug_draw.draw_line_n_d(_p(0, 3), _p(0, 3, 1.0, 0.0, 0.9), Vector3.UP, Color(0.5, 1.0, 0.65), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET)

  _debug_draw.draw_ray(_p(1, 0), Vector3(1.0, 0.35, 0.0), Color.WHITE, 2.0)
  _debug_draw.draw_ray_n(_p(1, 1), Vector3(1.0, 0.35, 0.0), Vector3.UP, Color(0.35, 1.0, 1.0), 2.0)
  _debug_draw.draw_ray_d(_p(1, 2), Vector3(1.0, 0.35, 0.0), Color(1.0, 0.75, 0.25), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET)
  _debug_draw.draw_ray_n_d(_p(1, 3), Vector3(1.0, 0.35, 0.0), Vector3.UP, Color(0.5, 1.0, 0.65), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET)

  _debug_draw.draw_arrow(_p(2, 0, 1.0, 0.0, 0.9), Vector3(0.55, 0.2, 0.0), Color.WHITE, 2.0, PI / 6.0, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_arrow_n(_p(2, 1, 1.0, 0.0, 0.9), Vector3(0.55, 0.2, 0.0), Vector3.UP, Color(0.35, 1.0, 1.0), 2.0, PI / 6.0, DebugDraw3D.LineJoint.BEVEL)
  _debug_draw.draw_arrow_line(_p(2, 2), _p(2, 2, 1.0, 0.0, 0.9), Color(1.0, 0.75, 0.25), 2.0, 0.25, PI / 6.0, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_arrow_line_n(_p(2, 3), _p(2, 3, 1.0, 0.0, 0.9), Vector3.UP, Color(0.5, 1.0, 0.65), 2.0, 0.25, PI / 6.0, DebugDraw3D.LineJoint.BEVEL)
  _debug_draw.draw_arrow_line_d(_p(2, 4), _p(2, 4, 1.0, 0.0, 0.9), Color(1.0, 0.45, 1.0), 2.0, 0.25, PI / 6.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, DebugDraw3D.LineJoint.MITER)
  _debug_draw.draw_arrow_line_n_d(_p(2, 5), _p(2, 5, 1.0, 0.0, 0.9), Vector3.UP, Color(0.7, 0.7, 1.0), 2.0, 0.25, PI / 6.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, DebugDraw3D.LineJoint.ROUND)

  _debug_draw.draw_axes(_p(3, 0, 0.5), Quaternion.IDENTITY, 0.55, 2.0)
  _debug_draw.draw_axes_n(_p(3, 1, 0.5), Quaternion(Vector3.UP, PI * 0.25), 0.55, 2.0)

  _debug_draw.draw_line_list(PackedVector3Array([_p(4, 0), _p(4, 0, 0.8, 0.0, 0.85), _p(4, 0, 0.1, 0.35), _p(4, 0, 0.9, 0.35, 0.85)]), Color.WHITE, 2.0)
  _debug_draw.draw_line_list_n(PackedVector3Array([_p(4, 1), _p(4, 1, 0.8, 0.0, 0.85), _p(4, 1, 0.1, 0.35), _p(4, 1, 0.9, 0.35, 0.85)]), PackedVector3Array([Vector3.UP, Vector3.UP]), Color(0.35, 1.0, 1.0), 2.0)

  _debug_draw.draw_line_strip(PackedVector3Array([_p(5, 0), _p(5, 0, 0.45, 0.18, 0.95), _p(5, 0, 1.0, 0.0, 0.7)]), Color.WHITE, 4.0, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_line_strip_n(PackedVector3Array([_p(5, 1), _p(5, 1, 0.45, 0.18, 0.95), _p(5, 1, 1.0, 0.0, 0.7)]), PackedVector3Array([Vector3.UP, Vector3.UP]), Color(0.35, 1.0, 1.0), 4.0, DebugDraw3D.LineJoint.BEVEL)
  _debug_draw.draw_line_strip_d(PackedVector3Array([_p(5, 2), _p(5, 2, 0.45, 0.18, 0.95), _p(5, 2, 1.0, 0.0, 0.7)]), Color(1.0, 0.75, 0.25), 4.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, DebugDraw3D.LineJoint.MITER)
  _debug_draw.draw_line_strip_n_d(PackedVector3Array([_p(5, 3), _p(5, 3, 0.45, 0.18, 0.95), _p(5, 3, 1.0, 0.0, 0.7)]), PackedVector3Array([Vector3.UP, Vector3.UP]), Color(0.5, 1.0, 0.65), 4.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, DebugDraw3D.LineJoint.ROUND)

  _debug_draw.draw_line_loop(PackedVector3Array([_p(6, 0), _p(6, 0, 0.55, 0.25, 0.95), _p(6, 0, 1.0, 0.0, 0.65)]), Color.WHITE, 4.0, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_line_loop_n(PackedVector3Array([_p(6, 1), _p(6, 1, 0.55, 0.25, 0.95), _p(6, 1, 1.0, 0.0, 0.65)]), PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP]), Color(0.35, 1.0, 1.0), 4.0, DebugDraw3D.LineJoint.BEVEL)
  _debug_draw.draw_line_loop_d(PackedVector3Array([_p(6, 2), _p(6, 2, 0.55, 0.25, 0.95), _p(6, 2, 1.0, 0.0, 0.65)]), Color(1.0, 0.75, 0.25), 4.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, DebugDraw3D.LineJoint.MITER)
  _debug_draw.draw_line_loop_n_d(PackedVector3Array([_p(6, 3), _p(6, 3, 0.55, 0.25, 0.95), _p(6, 3, 1.0, 0.0, 0.65)]), PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP]), Color(0.5, 1.0, 0.65), 4.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, DebugDraw3D.LineJoint.ROUND)

  _debug_draw.draw_curve(_curve, Transform3D(Basis.IDENTITY, _p(7, 0, 0.5, 0.0, 0.65)), Color.WHITE, 2.5, 5, 0.04, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_curve_d(_curve, Transform3D(Basis.IDENTITY, _p(7, 1, 0.5, 0.0, 0.65)), Color(1.0, 0.75, 0.25), 2.5, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, 5, 0.04, DebugDraw3D.LineJoint.BEVEL)

  _debug_draw.draw_grid(_p(8, 0, 0.5, 0.0, 0.05), Quaternion.IDENTITY, Vector2i(4, 3), Vector2(0.25, 0.25), Color.WHITE, 1.5, DebugDraw3D.DEFAULT_LAYER, DebugDraw3D.GridOuterEdges.XZ, Vector2.ZERO)
  _debug_draw.draw_grid_n(_p(8, 1, 0.5), Quaternion(Vector3.RIGHT, PI * 0.5), Vector2i(4, 3), Vector2(0.25, 0.25), Color(0.35, 1.0, 1.0), 1.5, DebugDraw3D.DEFAULT_LAYER, DebugDraw3D.GridOuterEdges.XZ, Vector2.ZERO)

  _debug_draw.draw_rect(_p(9, 0, 0.5), Quaternion.IDENTITY, 0.8, 0.5, Color.WHITE, 2.0, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_rect_s(_p(9, 1, 0.5), Quaternion.IDENTITY, 0.8, 0.5, Color(1.0, 0.25, 0.25, 0.45))
  _debug_draw.draw_rect_n(_p(9, 2, 0.5), Quaternion.IDENTITY, 0.8, 0.5, Color(0.35, 1.0, 1.0), 2.0, DebugDraw3D.LineJoint.BEVEL)
  _debug_draw.draw_rect_d(_p(9, 3, 0.5), Quaternion.IDENTITY, 0.8, 0.5, Color(1.0, 0.75, 0.25), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, DebugDraw3D.LineJoint.MITER)
  _debug_draw.draw_rect_n_d(_p(9, 4, 0.5), Quaternion.IDENTITY, 0.8, 0.5, Color(0.5, 1.0, 0.65), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, DebugDraw3D.LineJoint.ROUND)

  _debug_draw.draw_box(_p(10, 0, 0.5), Quaternion.IDENTITY, Vector3(0.7, 0.7, 0.7), Color.WHITE, 2.0)
  _debug_draw.draw_box_s(_p(10, 1, 0.5), Quaternion.IDENTITY, Vector3(0.7, 0.7, 0.7), Color(1.0, 0.45, 0.2, 0.35))
  _debug_draw.draw_box_n(_p(10, 2, 0.5), Quaternion.IDENTITY, Vector3(0.7, 0.7, 0.7), Color(0.35, 1.0, 1.0), 2.0)
  _debug_draw.draw_box_d(_p(10, 3, 0.5), Quaternion.IDENTITY, Vector3(0.7, 0.7, 0.7), Color(1.0, 0.75, 0.25), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET)
  _debug_draw.draw_box_n_d(_p(10, 4, 0.5), Quaternion.IDENTITY, Vector3(0.7, 0.7, 0.7), Color(0.5, 1.0, 0.65), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET)

  _debug_draw.draw_circle(_p(11, 0, 0.5), Quaternion.IDENTITY, 0.4, Color.WHITE, 2.0, 32, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_circle_n(_p(11, 1, 0.5), Quaternion.IDENTITY, 0.4, Color(0.35, 1.0, 1.0), 2.0, 32, DebugDraw3D.LineJoint.BEVEL)
  _debug_draw.draw_circle_d(_p(11, 2, 0.5), Quaternion.IDENTITY, 0.4, Color(1.0, 0.75, 0.25), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, 32, DebugDraw3D.LineJoint.MITER)
  _debug_draw.draw_circle_n_d(_p(11, 3, 0.5), Quaternion.IDENTITY, 0.4, Color(0.5, 1.0, 0.65), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, 32, DebugDraw3D.LineJoint.ROUND)

  _debug_draw.draw_arc(_p(12, 0, 0.5), Quaternion.IDENTITY, 0.45, PI * 1.25, Color.WHITE, 2.0, 32, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_arc_n(_p(12, 1, 0.5), Quaternion.IDENTITY, 0.45, PI * 1.25, Color(0.35, 1.0, 1.0), 2.0, 32, DebugDraw3D.LineJoint.BEVEL)
  _debug_draw.draw_arc_d(_p(12, 2, 0.5), Quaternion.IDENTITY, 0.45, PI * 1.25, Color(1.0, 0.75, 0.25), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, 32, DebugDraw3D.LineJoint.MITER)
  _debug_draw.draw_arc_n_d(_p(12, 3, 0.5), Quaternion.IDENTITY, 0.45, PI * 1.25, Color(0.5, 1.0, 0.65), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, 32, DebugDraw3D.LineJoint.ROUND)

  _debug_draw.draw_sphere(_p(13, 0, 0.5), Quaternion.IDENTITY, 0.4, Color.WHITE, 2.0, 32, 2, 2, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_sphere_s(_p(13, 1, 0.5), Quaternion.IDENTITY, 0.4, Color(0.35, 0.75, 1.0, 0.35))
  _debug_draw.draw_sphere_n(_p(13, 2, 0.5), Quaternion.IDENTITY, 0.4, Color(0.35, 1.0, 1.0), 2.0, 32, 2, 2, DebugDraw3D.LineJoint.BEVEL)
  _debug_draw.draw_sphere_d(_p(13, 3, 0.5), Quaternion.IDENTITY, 0.4, Color(1.0, 0.75, 0.25), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, 32, 2, 2, DebugDraw3D.LineJoint.MITER)
  _debug_draw.draw_sphere_n_d(_p(13, 4, 0.5), Quaternion.IDENTITY, 0.4, Color(0.5, 1.0, 0.65), 2.0, DASH_WIDTH, DASH_SPACE, DASH_OFFSET, 32, 2, 2, DebugDraw3D.LineJoint.ROUND)

  _debug_draw.draw_cone(_p(14, 0, 0.5), Quaternion.IDENTITY, 0.35, 0.8, Color.WHITE, 2.0, 32, 8, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_cone_s(_p(14, 1, 0.5), Quaternion.IDENTITY, 0.35, 0.8, Color(1.0, 0.45, 0.25, 0.35))
  _debug_draw.draw_cone_n(_p(14, 2, 0.5), Quaternion.IDENTITY, 0.35, 0.8, Color(0.35, 1.0, 1.0), 2.0, 32, 8, DebugDraw3D.LineJoint.BEVEL)

  _debug_draw.draw_cylinder(_p(15, 0, 0.5), Quaternion.IDENTITY, 0.35, 0.4, Color.WHITE, 2.0, 32, 8, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_cylinder_s(_p(15, 1, 0.5), Quaternion.IDENTITY, 0.35, 0.4, Color(0.6, 0.45, 1.0, 0.35))
  _debug_draw.draw_cylinder_n(_p(15, 2, 0.5), Quaternion.IDENTITY, 0.35, 0.4, Color(0.35, 1.0, 1.0), 2.0, 32, 8, DebugDraw3D.LineJoint.BEVEL)

  _debug_draw.draw_capsule(_p(16, 0, 0.5), Quaternion.IDENTITY, 0.32, 0.45, Color.WHITE, 2.0, 32, 2, DebugDraw3D.LineJoint.ROUND)
  _debug_draw.draw_capsule_n(_p(16, 1, 0.5), Quaternion.IDENTITY, 0.32, 0.45, Color(0.35, 1.0, 1.0), 2.0, 32, 2, DebugDraw3D.LineJoint.BEVEL)


func _create_labels() -> void:
  for column in COLUMN_LABELS.size():
    _create_label(
      "ColumnLabel%d" % column,
      COLUMN_LABELS[column],
      Vector3(_column_x(column) + 0.5, LABEL_Y, TITLE_Z),
      TITLE_LABEL_FONT_SIZE,
      HORIZONTAL_ALIGNMENT_CENTER,
    )

  for column in ROW_LABELS.size():
    for row in ROW_LABELS[column].size():
      _create_label(
        "SampleLabel%d_%d" % [column, row],
        ROW_LABELS[column][row],
        Vector3(_column_x(column) - SAMPLE_LABEL_GAP, LABEL_Y, _row_z(row)),
        LABEL_FONT_SIZE,
        HORIZONTAL_ALIGNMENT_RIGHT,
      )


func _create_label(
    label_name: String,
    text: String,
    label_position: Vector3,
    font_size: int,
    horizontal_alignment: HorizontalAlignment,
) -> void:
  var label := Label3D.new()
  label.name = label_name
  label.text = text
  label.position = label_position
  label.rotation.x = -PI * 0.5
  label.font_size = font_size
  label.pixel_size = LABEL_PIXEL_SIZE
  label.fixed_size = false
  label.no_depth_test = false
  label.modulate = Color(0.86, 0.94, 1.0, 1.0)
  label.horizontal_alignment = horizontal_alignment
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  add_child(label)


func _p(
    column: int,
    row: int,
    x_offset: float = 0.0,
    z_offset: float = 0.0,
    y: float = SAMPLE_Y,
) -> Vector3:
  return Vector3(_column_x(column) + x_offset, y, _row_z(row) + z_offset)


func _column_x(column: int) -> float:
  return ORIGIN_X + float(column) * COLUMN_SPACING


func _row_z(row: int) -> float:
  return ORIGIN_Z - float(row) * ROW_SPACING
