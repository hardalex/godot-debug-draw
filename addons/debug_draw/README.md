# Debug Draw

`DebugDraw3D` is a reusable in-scene 3D debug drawing node for Godot 4.7. It renders transient draw commands through `MultiMeshInstance3D` nodes and shaders.

## Requirements

- Godot 4.7

## Installation

Copy this folder to your project:

```text
res://addons/debug_draw/
```

No plugin activation is required.

## Quick Start

Instance the reusable scene in a 3D scene:

```text
res://addons/debug_draw/debug_draw_3d.tscn
```

Submit draw calls every frame while the geometry should remain visible:

```gdscript
@onready var debug_draw: DebugDraw3D = $DebugDraw3D

func _process(_delta: float) -> void:
  debug_draw.draw_axes(Vector3.ZERO, Quaternion.IDENTITY, 1.0, 2.0)
  debug_draw.draw_line(
    Vector3.ZERO,
    Vector3(1.0, 0.5, 0.0),
    Color(1.0, 0.85, 0.1),
    3.0,
  )
```

Keep the `DebugDraw3D` node unrotated and unscaled. Its draw buffers are reset after each frame.

## License

MIT License. See [LICENSE](LICENSE).
