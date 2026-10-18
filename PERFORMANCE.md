# Performance pass — October 15, 2026

This pass preserves the current lighting, shadow settings, render resolution,
models, materials, animated effects, and interactive lesson objects.

## Changes

- `scripts/StaticSceneryBatch.gd` instances repeated opaque static meshes in
  32 m cells in the opening neighborhood, nearby bedroom exterior, and autumn
  neighborhood slice. Each object remains separately editable in the editor.
  Batches are built once at runtime and preserve effective material overrides,
  transforms, render layers, shadow casting, and geometry settings.
- Models with automatic LODs remain individual render instances. Testing a more
  aggressive batch exposed differences in distant detail, so that approach was
  discarded. Transparent, scripted, skinned, animated, hidden, and billboard
  objects are also excluded. The learning house is explicitly excluded from
  neighborhood batching. No treehouse gameplay geometry is batched.
- Glitch's opaque body uses seven instanced color groups plus two moving pupils:
  74 body drawables become 9. Translucent ghost copies keep their original
  individual sorting, and all movement/hat attachment paths remain intact.
- The autumn sky skips hill-noise calculations above the highest possible hill
  line. The original calculations and parameters are retained everywhere they
  can contribute to the image. Cloud animation and sky lighting are unchanged.
- The computer's hidden render target starts at 2×2 until first use, then uses
  the original 1600×900 resolution for its desktop, lesson, transitions, and
  final monitor image. The logical UI remains 1280×720.
- After Continue returns the player to the bedroom, the completed lesson stops
  processing behind its still monitor image. Replaying creates an active fresh
  lesson. The existing full-screen lesson already disables bedroom 3D rendering.
- `work/runtime/.gdignore` keeps temporary diagnostic output out of editor asset
  discovery and ordinary exports.

Only explicitly static branches should be batched. If future gameplay moves,
individually hides, or changes the materials of scenery in these branches, add
that object/branch to `excluded_paths` or attach its behavior script before the
batcher runs. Source node paths and collisions are retained; source mesh render
layers are disabled only in the running game, with originals recorded as metadata.

## Measurements

Godot 4.7.2, Compatibility/OpenGL, RTX 4070 SUPER, 1280×720, VSync off.
Each fixed-view sample warms up for 75 frames and measures 180 frames.
The editor/user game may remain open, so timings are indicative rather than a
guarantee for an exported game or a different computer.

| View | Original median frame time | Final median frame time | Approximate change |
|---|---:|---:|---:|
| Autumn treehouse | 5.689 ms | 4.909 ms | 14% lower |
| Bedroom | 7.452 ms | 6.415 ms | 14% lower |
| Standalone lesson, unobscured | 5.265 ms | 5.221 ms | Essentially unchanged |
| Lesson welcome screen | 5.958 ms | 5.252 ms | 12% lower |

These are runtime measurements, not editor FPS. The Glitch is hidden in the
sampled lesson welcome/title view; its body batching helps the story beats in
which it appears. The CPU benefit of stopping the completed lesson is also not
included in the initial-bedroom sample.

## Validation

- `tests/lesson_flow.tscn`: PASS, including all three password steps, all four
  pranks, repairs, customization, actor floor clearance, and finale.
- `tests/bedroom_flow.tscn`: PASS. Additional assertions cover the original monitor
  resolution, inactive completed lesson, unchanged hidden animation clock, and
  active fresh instance on replay.
- `neighborhood_assets/source/check_preview_loop.gd`: PASS for both cloud-fade
  loops and Play taking over without teleporting the camera.
- Same-scene frozen renders compare the original and batched scenery, avoiding
  differences from particle randomness or camera movement. The bedroom matches
  pixel for pixel. The treehouse has only sparse subpixel edge differences
  (0.0024% of pixels differ by more than 4/255); the opening has one such pixel.
- Original vs optimized sky renders match pixel for pixel. Glitch front and
  turned/leaning poses also match pixel for pixel.
- No new shader/script errors. The diagnostic harness reports the same single
  ObjectDB cleanup warning before and after this pass; the complete flow tests
  finish successfully.

Diagnostic scripts, JSON, screenshots, diffs, scene backups, and test logs are
retained locally in `work/runtime/performance_oct15/` (ignored by Git). Restart
the running game to use the updated scripts and scene configuration.
