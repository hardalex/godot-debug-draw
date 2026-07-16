# Getting Started

Use `DebugDraw3D` as a scene node rather than a global singleton. Draw calls are transient, so submit them from `_process()` every frame they should remain visible.

Related: [Concepts](concepts.md), [API Reference](api-reference.md), [Examples](examples.md).

## Add the Node

Instance `res://addons/debug_draw/debug_draw_3d.tscn` in any scene that needs debug rendering.
Keep the node's global basis at identity; do not rotate or scale `DebugDraw3D` itself.

```gdscript
@onready var _debug_draw: DebugDraw3D = $DebugDraw3D
```

## Submit Draw Calls

```gdscript
func _process(_delta: float) -> void:
  _debug_draw.draw_axes(Vector3.ZERO, Quaternion.IDENTITY, 1.0, 2.0)
  _debug_draw.draw_line(
    Vector3.ZERO,
    Vector3(1.0, 0.5, 0.0),
    Color(1.0, 0.85, 0.1, 1.0),
    3.0,
  )
```

During its own `_process()`, `DebugDraw3D` flushes and resets its internal buffers. Its high process priority lets normal scene scripts submit draw calls first.

## Common Setup

```gdscript
func _ready() -> void:
  _debug_draw.line_width = 2.0
  _debug_draw.depth_bias = -0.001
```

Useful properties:

- `debug_visible`: shows or hides all submitted debug geometry.
- `line_width`: default width when a draw call passes `-1.0`.
- `depth_bias`: small clip-space offset that reduces z-fighting.
- `visible_layers`: bitmask that filters submitted debug layers.
- `round_joint_resolution`: triangle-fan resolution for round line joints.
- `miter_limit`: maximum miter length for miter joints.
- `back_fade_start`: angle where normal-aware lines begin fading from front-facing brightness; shown in degrees in the Inspector.
- `back_fade_transition`: angular range for the fade to back-facing brightness; shown in degrees in the Inspector.

## Minimal Scene Pattern

The example scenes follow this pattern:

1. Instance `DebugDraw3D`.
2. Configure `depth_bias` in `_ready()`.
3. Submit debug shapes in `_process()`.
4. Use HiDPI-aware window sizing with a 1280×720 design viewport.

See `examples/index.gd` and [Example Scene Families](examples.md#example-scene-families).
