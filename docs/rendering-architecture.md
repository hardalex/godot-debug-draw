# Rendering Architecture

`DebugDraw3D` renders transient debug geometry through reusable MultiMesh renderers. Its public API is defined in `addons/debug_draw/debug_draw_3d.gd`.

Related: [Concepts](concepts.md), [API Reference](api-reference.md), [Getting Started](getting-started.md).

## Node Layout

`addons/debug_draw/debug_draw_3d.tscn` has a `Node3D` root with these `MultiMeshInstance3D` children:

- `RectMesh`
- `BoxMesh`
- `SphereMesh`
- `CylinderMesh`
- `ConeMesh`
- `LineMesh`
- `NormalLineMesh`
- `JointMesh`
- `NormalJointMesh`

Additional mesh instances for bevel and miter joints are created on demand at runtime.

## Frame Pipeline

1. Scene scripts call `draw_*` methods.
2. `DebugDraw3D` validates inputs and converts higher-level shapes into line, joint, rect, or mesh submissions.
3. Renderer objects append packed data to CPU buffers.
4. `flush()` commits visible submissions to MultiMeshes.
5. Buffers are reset for the next frame.

When `debug_visible` is false, renderers clear their MultiMesh visible counts and reset their submissions.

## Renderer Types

| Renderer | Role |
| --- | --- |
| `debug_line_renderer_3d.gd` | Regular line and dashed line segments. |
| `debug_normal_line_renderer_3d.gd` | Normal-aware line and dashed line segments. |
| `debug_joint_renderer_3d.gd` | Round, bevel, and miter joint fans. |
| `debug_normal_joint_renderer_3d.gd` | Normal-aware joint fans. |
| `debug_rect_renderer_3d.gd` | Filled rect instances. |
| `debug_mesh_renderer_3d.gd` | Solid box, sphere, cylinder, and cone instances. |

Each renderer owns a MultiMesh, grows its capacity in powers of two, updates `visible_instance_count`, and writes a custom AABB for culling.

## Shaders

Line shaders expand compact instance data into screen-space strokes. Joint shaders render triangle fans for connected corners. Mesh shaders render solid helper instances with per-instance color and `depth_bias`.

Shader groups live in `addons/debug_draw/shaders/`:

- `debug_line_3d*`: regular line strokes.
- `debug_normal_line_3d*`: normal-aware strokes.
- `debug_line_joint_*`: regular joints.
- `debug_normal_line_joint_*`: normal-aware joints.
- `debug_rect_3d.gdshader`: filled rects.
- `debug_mesh_3d.gdshader`: solid shape helpers.

## Layers and Visibility

Renderers store a layer for each submission. During commit, they filter submissions against `visible_layers`. This keeps layer visibility inexpensive and consistent across all draw families.

## Sorting

Solid mesh and filled-rect submissions are sorted back-to-front relative to the active camera before upload. This improves translucent debug-volume rendering. Wire lines and joints are not sorted.

## Depth Bias

`depth_bias` is forwarded to every renderer material. A small negative value, such as `-0.001`, helps reduce z-fighting with scene geometry.

## Process Priority

`DebugDraw3D` sets a high `process_priority` in `_ready()`. This lets normal scene scripts submit debug calls during `_process()` before `DebugDraw3D` flushes its buffers.

## Constraints

- Keep `DebugDraw3D` unrotated and unscaled.
- Draw calls are transient and must be resubmitted every frame.
- Invalid or degenerate geometry is skipped.
- The extension is written in GDScript and has no external dependencies.
