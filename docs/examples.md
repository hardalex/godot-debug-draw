# Examples

The `examples/` scenes are visual references for the public API. They are curated examples, not exhaustive test matrices.

Related: [Getting Started](getting-started.md), [API Reference](api-reference.md).

## Example Scene Families

| Scene | Focus |
| --- | --- |
| `examples/index.tscn` | Overview scene covering every current `DebugDraw3D.draw_*` API. |
| `examples/line.tscn` | Lines, rays, strips, loops, dashes, normal-aware paths, and joints. |
| `examples/arrow.tscn` | Arrow and arrow-line helpers. |
| `examples/axes.tscn` | Local-axis helpers. |
| `examples/grid.tscn` | Grid cells, spacing, edges, skew, and normal-aware grids. |
| `examples/rect.tscn` | Wire and filled rects, dashes, rotation, joints, and normal-aware variants. |
| `examples/box.tscn` | Wire, solid, dashed, and normal-aware boxes. |
| `examples/circle.tscn` | Circle segments, dashes, joints, and normal-aware variants. |
| `examples/arc.tscn` | Arc angles, segments, dashes, joints, and normal-aware variants. |
| `examples/curve.tscn` | `Curve3D` tessellation and dashed curves. |
| `examples/sphere.tscn` | Sphere rings, solid spheres, axis segment counts, dashes, and normals. |
| `examples/cone.tscn` | Cone bases, side lines, solid cones, and normal-aware cones. |
| `examples/cylinder.tscn` | Cylinder rings, sides, solid cylinders, and normal-aware cylinders. |
| `examples/capsule.tscn` | Capsule rings and normal-aware capsules. |

## Shared Example Pattern

Most example scenes include:

- `FreeCamera` from `entities/free_camera.gd`.
- `EndlessGrid3D` from `entities/endless_grid_3d.gd`.
- A `DebugDraw3D` scene instance.
- Draw submission from `_process()`.
- A 1280×720 design viewport scaled with `DisplayServer.screen_get_max_scale()`.
- Short world-space labels for columns and rows.

## Camera Controls

`FreeCamera` uses Godot editor-style controls:

- Middle mouse: orbit.
- Shift + middle mouse: pan.
- Ctrl + middle mouse: zoom.
- Mouse wheel or pinch: zoom.
- Right mouse: freelook.
- WASD/QE: movement in freelook.

## Updating Examples

Key rules for editing or adding an example:

- Treat the `.gd` script as the source of truth for layout and draw calls.
- Prefer representative samples to exhaustive API combinations.
- Use the X axis for API groups and the Z axis for parameter variations.
- Keep labels local to each column.
- Use `examples/rect.gd` as the implementation reference for curated shape examples.

## API Coverage

The current examples cover every public shape family listed in [API Reference](api-reference.md). When adding an API, add or update the closest shape-family example and keep it focused on the new behavior.
