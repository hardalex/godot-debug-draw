# API Reference

This page groups the public `DebugDraw3D` API by use case. See `addons/debug_draw/debug_draw_3d.gd` for exact signatures.

Related: [Concepts](concepts.md), [Getting Started](getting-started.md), [Rendering Architecture](rendering-architecture.md).

## Node Controls

| API | Purpose |
| --- | --- |
| `flush()` | Commit current buffers immediately and reset submissions. Usually automatic. |
| `set_layer_enabled(layer, enabled)` | Toggle a positive layer bit in `visible_layers`. |

Useful exported properties: `debug_visible`, `line_width`, `back_fade_start`, `back_fade_transition`, `round_joint_resolution`, `miter_limit`, `depth_bias`, `visible_layers`.

## Enums

| Enum | Values |
| --- | --- |
| `LineJoint` | `NONE`, `ROUND`, `BEVEL`, `MITER` |
| `GridOuterEdges` | `NONE`, `X`, `Y`, `Z`, `XZ`, `ALL` |

## Lines and Rays

| API | Notes |
| --- | --- |
| `draw_line(from, to, color, width, layer)` | One line segment. |
| `draw_line_n(from, to, normal, color, width, layer)` | Normal-aware segment. |
| `draw_line_d(from, to, color, width, dash_width, dash_space, dash_offset, layer)` | Dashed segment. |
| `draw_line_n_d(from, to, normal, color, width, dash_width, dash_space, dash_offset, layer)` | Normal-aware dashed segment. |
| `draw_ray(from, vector, color, width, layer)` | Segment from `from` to `from + vector`. |
| `draw_ray_n(...)`, `draw_ray_d(...)`, `draw_ray_n_d(...)` | Normal-aware and dashed ray variants. |

## Arrow and Axes Helpers

| API | Notes |
| --- | --- |
| `draw_arrow(pos, dir, color, width, head_angle, joint, layer)` | Draw an arrow head at `pos + dir`. |
| `draw_arrow_n(...)` | Normal-aware arrow. |
| `draw_arrow_line(from, to, color, width, head_length, head_angle, joint, layer)` | Segment plus arrow head at `to`. |
| `draw_arrow_line_n(...)` | Normal-aware arrow line. |
| `draw_arrow_line_d(...)` | Dashed arrow line. |
| `draw_arrow_line_n_d(...)` | Normal-aware dashed arrow line. |
| `draw_axes(pos, rotation, length, width, layer)` | RGB local axes. |
| `draw_axes_n(pos, rotation, length, width, layer)` | Normal-aware RGB local axes. |

## Point Collections and Curves

| API | Input shape |
| --- | --- |
| `draw_line_list(points, color, width, layer)` | Independent segment pairs. |
| `draw_line_list_n(points, normals, color, width, layer)` | Independent normal-aware pairs. |
| `draw_line_strip(points, color, width, joint, layer)` | Connected open polyline. |
| `draw_line_strip_n(...)`, `draw_line_strip_d(...)`, `draw_line_strip_n_d(...)` | Normal-aware and dashed strip variants. |
| `draw_line_loop(points, color, width, joint, layer)` | Connected closed loop. |
| `draw_line_loop_n(...)`, `draw_line_loop_d(...)`, `draw_line_loop_n_d(...)` | Normal-aware and dashed loop variants. |
| `draw_curve(curve, curve_transform, color, width, max_stages, tolerance_length, joint, layer)` | Tessellated `Curve3D`; closed curves become loops. |
| `draw_curve_d(...)` | Dashed curve variant. |

## Grids and Rects

| API | Notes |
| --- | --- |
| `draw_grid(center, rotation, cell_count, spacing, color, line_width, layer, outer_edges, skew)` | Wire grid in a rotated plane. |
| `draw_grid_n(...)` | Normal-aware grid. |
| `draw_rect(center, rotation, rect_width, rect_height, color, line_width, joint, layer)` | Wire rect. |
| `draw_rect_s(center, rotation, rect_width, rect_height, color, layer)` | Filled rect. |
| `draw_rect_n(...)`, `draw_rect_d(...)`, `draw_rect_n_d(...)` | Normal-aware and dashed rect variants. |

## Boxes

| API | Notes |
| --- | --- |
| `draw_box(pos, rotation, size, color, line_width, layer)` | Wire box. |
| `draw_box_s(pos, rotation, size, color, layer)` | Solid box. |
| `draw_box_n(...)`, `draw_box_d(...)`, `draw_box_n_d(...)` | Normal-aware and dashed box variants. |

## Circles and Arcs

| API | Notes |
| --- | --- |
| `draw_circle(center, rotation, radius, color, line_width, segment_count, joint, layer)` | Closed circular loop. |
| `draw_circle_n(...)`, `draw_circle_d(...)`, `draw_circle_n_d(...)` | Normal-aware and dashed circle variants. |
| `draw_arc(center, rotation, radius, angle, color, line_width, segment_count, joint, layer)` | Open arc strip. |
| `draw_arc_n(...)`, `draw_arc_d(...)`, `draw_arc_n_d(...)` | Normal-aware and dashed arc variants. |

## Volumes

| API | Notes |
| --- | --- |
| `draw_sphere(pos, rotation, radius, color, line_width, segment_count, y_axis_segment_count, z_axis_segment_count, joint, layer)` | Wire sphere rings. |
| `draw_sphere_s(pos, rotation, radius, color, layer)` | Solid sphere. |
| `draw_sphere_n(...)`, `draw_sphere_d(...)`, `draw_sphere_n_d(...)` | Normal-aware and dashed sphere variants. |
| `draw_cone(pos, rotation, radius, height, color, line_width, segment_count, side_segment_count, joint, layer)` | Wire cone. |
| `draw_cone_s(pos, rotation, radius, height, color, layer)` | Solid cone. |
| `draw_cone_n(...)` | Normal-aware cone. |
| `draw_cylinder(pos, rotation, radius, half_height, color, line_width, segment_count, side_segment_count, joint, layer)` | Wire cylinder. |
| `draw_cylinder_s(pos, rotation, radius, half_height, color, layer)` | Solid cylinder. |
| `draw_cylinder_n(...)` | Normal-aware cylinder. |
| `draw_capsule(pos, rotation, radius, half_height, color, line_width, segment_count, side_segment_count, joint, layer)` | Wire capsule. |
| `draw_capsule_n(...)` | Normal-aware capsule. |

## Naming Pattern

Prefer choosing an API by answering these questions:

1. What shape family do you need?
2. Do you need a solid helper? Use `_s` when available.
3. Do you need hidden-side fading? Use `_n` when available.
4. Do you need dashes? Use `_d` or `_n_d` when available.
5. Do connected corners matter? Pass a `LineJoint` when the function exposes `joint`.
