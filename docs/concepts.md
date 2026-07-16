# Concepts

Related: [[getting-started|Getting Started]], [[api-reference|API Reference]], [[rendering-architecture|Rendering Architecture]].

## Draw Call Lifetime

Draw commands are frame-local. Submit them again each frame while they should remain visible.

`DebugDraw3D` converts submissions into renderer buffers, commits them to MultiMeshes during `_process()`, and then clears the buffers. Call `flush()` only when a commit is needed before the node's process step.

## Coordinates and Transforms

Draw functions accept world-space positions and rotations. Shape rotations are `Quaternion` values, normalized internally before points are generated.

Keep `DebugDraw3D`'s global basis at identity. It reports an error when rotated or scaled.

## Width

Most line APIs accept a `width` or `line_width` parameter.

- `-1.0` uses the node's `line_width` property.
- A positive value overrides the default for that call.
- Line width is rendered in screen space by the line shaders.

## API Suffixes

Suffixes describe draw variants:

- No suffix: regular wireframe or helper path.
- `_d`: dashed-line path with `dash_width`, `dash_space`, and `dash_offset`.
- `_n`: normal-aware path; the normal controls fading as a line faces away.
- `_n_d`: normal-aware dashed path.
- `_s`: solid-mesh or filled-rect path.

## Dashes

Dashed APIs measure distance along the emitted line path.

- `dash_width`: visible-segment length.
- `dash_space`: gap length.
- `dash_offset`: phase offset, useful for animation.

Wrap animated offsets with `fposmod(offset, dash_width + dash_space)` to keep them bounded.

## Normal-Aware Drawing

Normal-aware APIs use line normals to fade back-facing debug geometry. `back_fade_start` sets where fading begins, and `back_fade_transition` sets the angular range of the transition. The Inspector displays both values in degrees; scripts and saved scenes use radians. Angles are measured between the normal and view direction: `0` is front-facing, `PI * 0.5` is side-facing, and `PI` is back-facing.

Shape helpers generate normals internally when possible. Primitive `_n` line APIs require callers to provide them.

## Joints

Polyline and loop APIs can render connected corners with `DebugDraw3D.LineJoint`:

- `NONE`: no explicit joint mesh.
- `ROUND`: rounded corner fan.
- `BEVEL`: clipped corner.
- `MITER`: extended corner with `miter_limit`.

When an API exposes a `joint` parameter, joints apply to line strips, loops, curves, rects, arcs, circles, spheres, cones, cylinders, capsules, arrows, and their dashed or normal-aware variants.

## Layers

Each draw call has a `layer` bit. The node renders only calls whose layer intersects `visible_layers`.

```gdscript
_debug_draw.set_layer_enabled(1, true)
_debug_draw.set_layer_enabled(2, false)
_debug_draw.draw_line(Vector3.ZERO, Vector3.RIGHT, Color.WHITE, 2.0, 1)
```

Layer values must be positive bit flags. `DEFAULT_LAYER` is `1`.

## Solid Helpers

Solid helpers use the `_s` suffix:

- `draw_rect_s`
- `draw_box_s`
- `draw_sphere_s`
- `draw_cone_s`
- `draw_cylinder_s`

Solid helpers use mesh renderers and are depth-sorted back-to-front before upload. They are suited to translucent debug volumes.

## Validation

Most geometry helpers ignore invalid input rather than raising errors. For example:

- Zero-length lines are skipped.
- Non-positive radii, sizes, widths, heights, spacing values, or segment counts are skipped.
- Normal arrays must contain enough entries for the submitted points.
