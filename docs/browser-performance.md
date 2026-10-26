# Browser build and performance

The Web preset contains the opening, bedroom, all three lessons, the ending,
their resource dependencies and lesson JSON. `python tools/web.py build`
refreshes the explicit resource list, exports a release build and generates
gzip copies. This avoids relying on Godot's incomplete dependency discovery
for scripts loaded from other scripts or by string paths. Use the build script
to also copy the custom HTML shell's logo and font beside the exported page.

## Loading and transitions

`web/loading.html` replaces the default browser/Godot startup screen. It uses
the existing logo, Fredoka font and SunsetUI palette. Download progress is
shown when available; preparation uses an indeterminate bar. `SceneLoading`
keeps the surface visible until the first real game frame is ready. It also
provides a native fallback and loading surfaces for lesson transitions.

The computer click handler only starts the lightweight 2D monitor animation
and the operator/camera sequence. The monitor render target is warmed during
room setup. The full 3D lesson is instantiated after the animation completes,
under the loading surface. Replay uses the same sequence. Sharing-board and
phone loading surfaces appear after their existing entrance animations.
Loading can still take time on the browser's main thread; this change keeps
that work from freezing the first click-animation frame and makes the wait
explicit. The browser loading bar animates through CSS rather than game code.

## Rendering

Static scenery uses spatial MultiMeshes in 12-meter cells. Nearby repeated
meshes share draw calls; animated, scripted, interactive and transparent
branches stay separate. The winter neighborhood now uses the same batching
with its reviewed opaque snow shader. Collision nodes and authored node paths
are preserved.

Opaque, untextured surfaces that differ only in their albedo color are combined
using vertex colors. Their geometry, normals, UVs, lighting properties and
transparent surfaces are retained. The conversion is cached per mesh and
material combination and does not alter authored resources. Combined meshes
keep up to four conservative LOD transitions; batching can slightly change
distant LOD selection. `batch_lod_meshes` and `optimize_palettes` on the batching
node provide independent opt-outs.

The finale ships WAV files generated from the existing deterministic synthesis
functions. This preserves the sounds while removing synthesis and worker-thread
work from the browser. Regenerate them after changing the synthesis functions:

```powershell
godot --headless --path . --script res://tools/bake_web_audio.gd
```

## Measurements

One fixed opening-camera view, 1280×720, native Compatibility renderer,
RTX 4070 SUPER, VSync disabled, 120 frames after warmup:

| Measurement | Before | After |
| --- | ---: | ---: |
| Draw calls | 2,794 | 561 |
| Average frame time | 4.65 ms | 1.59 ms |
| Rendered primitives | 496,063 | 347,555 |

These are native renderer measurements, not a browser FPS guarantee. The
fixed-view RGB image comparison averaged 0.27/255 absolute difference per
channel, mostly at distant LOD edges. The original game assets, lighting,
lesson rules, controls, timings and UI are retained.

The original release payload was 65.11 MiB uncompressed, or 25.88 MiB with
equivalent gzip. The release with custom loading assets is about 59.27 MiB
uncompressed and 21.55 MiB with gzip. `build/web/sizes.json` records current sizes.

## Verification

Automated native checks cover bedroom/computer completion, the phone lesson,
both winter sharing rounds and photo capture, finale/replay/reset, global
pause, and palette/LOD/collision preservation:

```powershell
godot --headless --path . res://tests/bedroom_flow.tscn
godot --headless --path . res://tests/phone_flow.tscn
godot --path . --rendering-method gl_compatibility res://tests/sharing_winter_flow.tscn
godot --headless --path . res://tests/finale_flow.tscn
godot --headless --path . --script res://tests/pause_flow.gd
godot --headless --path . --script res://tests/static_scenery.gd
```

The browser release was also opened in Chrome and checked through the opening
flight into the bedroom. Single-threaded Web audio uses Godot's default Sample
playback. The shell attempts autoplay immediately; browsers that block it show
"Turn sound on" on the home screen. Any click, tap or key can unlock the same
engine audio context without pressing Play. Focus and visibility changes retry
an interrupted context across all scenes. Browser autoplay restrictions still
require a user gesture where the browser enforces one. See the official
[Web export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

Settings has independent Sound (master) and Music switches. Background tracks,
phone party speakers and finale music use the Music bus; effects and typing
remain audible when only Music is off. Volume and pause still apply globally.

Audio startup checks load the opening, bedroom, treehouse, both Sharing Board
rounds and phone scene without sending input. Chrome tests cover allowed and
blocked autoplay, touch, keyboard and interruption recovery using fresh browser
contexts and the built assets. They require Playwright and a Chrome executable
(`CHROME_BIN` overrides the Windows default):

```powershell
godot --headless --path . --script res://tests/music_startup.gd
godot --headless --path . --script res://tests/music_flow.gd
node tests/web_audio.cjs
```
