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

Startup uses a tiny boot scene rather than parsing the neighborhood before
the engine can paint. `SceneLoading` loads resource dependencies before their
parents, keeping strong references until the destination owns them. The
single-threaded browser returns to its event loop between 3 ms resource
slices; native builds poll a background resource request before retrieving it.
Opening/bedroom navigation, lesson exits, replay and round changes all use this
loader. Duplicate transitions are rejected, and failed loads restore the
previous pause and rendering state.

The computer click handler only starts the lightweight 2D monitor animation
and the operator/camera sequence. The monitor render target is warmed during
room setup. The full 3D lesson is instantiated after the animation completes,
under the loading surface. Replay uses the same sequence. Sharing-board and
phone loading surfaces appear after their existing entrance animations.
The scene remains covered while scenery and quality changes finish. Material
uploads and WebGL shader compilation then warm in groups of at most 16 geometry
instances per frame. Collecting those instances also yields, without reading
back MultiMesh bounds from the renderer. This avoids compiling
all visible materials in a single first frame. The browser loading bar animates
through CSS rather than game code. Individual resources, scene instantiation,
driver compilation and engine startup remain indivisible operations.

## Rendering

`GraphicsQuality` defaults to Auto. Browsers with at most two logical CPU
cores or 2 GB of reported memory start at Low; at most four cores or less than
4 GB select Balanced. Other browsers and unavailable hints start High.
Software renderers start Low. Auto steps down after three four-second
gameplay windows below 24 FPS, with a warmup after scene changes. Loading,
pausing and unfocused windows are excluded. It never oscillates back up.
Settings → Graphics cycles Auto, Low, Balanced and High and saves the choice.
For a direct test or a lighter shared link, append `?quality=low` to the URL;
this overrides the saved preference for that visit without saving it.

| Budget | Low | Balanced | High |
| --- | --- | --- | --- |
| 3D scale | Native | Native | Native |
| Full-screen monitor target / outline mask | Native | Native | Native |
| Ambient leaves, snow, motes and fire particles | 20% | 50% | Authored density |
| Other feedback particles | 35% | 60% | Authored density |
| Particle prewarming | Off | ≤0.1 s | ≤0.25 s |
| Multisample AA | At most 2× | At most 2× | At most 4× |
| Sun and local shadows | Off | Off | Authored enabled state |
| Sun shadow splits / reach | Off | Off | At most 2 / 160 m |
| Local shadow atlas | Disabled | Disabled | At most 4096² |
| Local light fade start / length | 20 / 10 m | 35 / 10 m | 60 / 10 m |
| Local shadow fade | Off | Off | 30 m (or shorter authored fade) |
| Mesh LOD pixel threshold | At least 4 | At least 2 | At least 1.5 |
| Round primitive radial segments | At most 12 | At most 20 | Authored topology |
| Sphere rings | At most 6 | At most 10 | Authored topology |
| Ambient particle shadows | Off | Off | Off |
| Ambient particle turbulence | Off | Off | Authored setting |
| Canopy sway | Off | 15 updates/s | Every frame |
| Campfire light animation | 6 updates/s | 15 updates/s | Every frame |

Every preset keeps the world, UI, photo clues and full-screen computer lesson
at their full target resolution. Low and Balanced remove shadow passes and
reduce geometry, ambient particles and small-prop draw distance. Shared copies
of round primitive meshes reduce tessellation without changing authored assets
or collision shapes; High restores their original topology, including batched
primitives. Imported meshes use their existing LODs. High also budgets distant
detail, local lights, sun splits, AA and particle startup work. Disabling
shadows changes the lighting, including how light reaches lamp shades.
Gameplay, collisions, lesson timing and camera framing remain unchanged.

Scenery preparation yields on every platform (a 2 ms target, checked between
meshes, batches and individual instance transforms). Geometry quality changes
use a separate 2 ms queue rather than scanning an entire scene in one frame.
Adding a light no longer revisits every mesh and every existing light. Startup
and lesson loading wait for preparation before revealing the scene.
Covered viewports suspend 3D drawing during preparation, avoiding repeated
unbatched renders; their previous rendering state is restored before reveal.
Individual resource parsing, mesh conversion, scene instantiation and driver
shader compilation can still take longer than the cooperative budgets;
these changes reduce stalls but cannot guarantee every browser stays responsive
on every machine. Native measurements on a dedicated GPU do not establish
low-end browser frame rates.

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

The enabled `scenery_export` editor plugin runs the palette conversion for the
reviewed static branches during export. Runtime preparation still handles
development scenes and any dynamically changed materials. Bedroom scenery now
also batches static floorboards, furnishings and decorations. The seated actor,
animated mouse and lesson objects remain independent, preserving their motion,
interaction and outline masks. The authored scene resources are not rewritten
by export preparation.

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

In one fixed 1280×720 Compatibility bedroom view on the same GPU, adding room
batching reduced High draw calls from 3,049 to 1,815, with the other High budgets
held constant. The final Balanced and Low presets each used 626 calls in that
view. These are not measurements on low-end hardware.

The original release payload was 65.11 MiB uncompressed, or 25.88 MiB with
equivalent gzip. The release with custom loading assets is about 59.27 MiB
uncompressed and 21.55 MiB with gzip. Those historical payloads predate the
current music and prepared meshes; `build/web/sizes.json` records current sizes.

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
godot --headless --path . --script res://tests/graphics_quality.gd
godot --headless --path . --script res://tests/scene_loading.gd
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

The browser performance test starts a temporary loopback server, uses a fresh
browser context for each preset, applies 4× CPU throttling, and traverses the
opening flight into the bedroom. It checks JavaScript/game errors and rejects
scene/gameplay tasks of five seconds or more after engine boot. Engine startup
tasks are recorded separately. Screenshots, phase marks and
task durations go to `work/performance-browser/`. CPU throttling is a synthetic
stress test, not a substitute for testing physical low-end devices:

```powershell
node tests/web_performance.cjs
```

Add `&profile_loading=1` to a quality test URL to record loading phase marks in
the browser Performance timeline. No profiling marks are emitted by default.
