# Digi-world player character

Open `preview/character_preview.tscn` in Godot and press **F6** to inspect the animated character.

- **Idle, Walk, Jog, Wave** buttons or **1–4** select the animation.
- **Drag** or use **Left/Right arrows** to rotate; **Turn around** shows the backpack.
- **Space** or **Pause/Resume** freezes the current pose.
- **Backpack** toggles both the bag and shoulder straps.
- Buttons also support keyboard focus with **Tab**, then **Enter**.

The friendly teen wears a teal hoodie, slate trousers, coral canvas sneakers, a canvas backpack and a small shield patch. The model has breathing, blinking, head movement, articulated arms and legs, level soles, and secondary backpack motion. Colors inherit the bedroom and neighborhood palette.

## Use the model

Instance `digi_character.tscn` as a visual child in another scene. It is approximately 1.8 units tall, with +Y up, +Z forward and its origin at floor level. Meshes use the default render layer, and all parts remain editable. There are 23,823 triangles across the model. Materials are embedded; no downloaded textures or external dependencies are needed.

Standalone instances play their exported `preview_animation` automatically. Set it to Idle, Walk, Jog or Wave in the inspector. The `backpack_visible` export controls the outfit accessory.

For a moving player, set `external_control = true` and drive the model once per frame using the actual horizontal speed:

```gdscript
$Model.animate(delta, Vector2(velocity.x, velocity.z).length())
```

Use `$Model.wave()` for a brief greeting that returns to idle. A moving character suppresses the greeting. Orient the parent toward travel. Animations run in place: the movement controller owns translation, collision and navigation. Idle, walking and jogging blend continuously; the preview's Wave state repeats until another state is selected.

The model uses an articulated Node3D hierarchy and procedural joint animation. It is not a skinned Skeleton3D or a retargetable imported animation library. `source/build_character.gd` regenerates only `digi_character.tscn`; it never rewrites the gameplay controller. Save custom scene edits separately before rebuilding.

## Existing first-person bedroom

`bedroom_player.tscn` and `bedroom_player.gd` remain the invisible first-person player. The bedroom gameplay scene now instances the model as `SeatedCharacter`: it types at the keyboard, breathes and blinks while awaiting a second Play click. The camera moves into its eyes, then rises behind the chair before enabling movement. The seated visual is hidden and its animation stops during first-person play. Running the project still uses the current opening sequence and bedroom controls: WASD/arrows to move, mouse to look, Shift to jog, Escape to release the cursor, and click to capture it again.

## Validation

Run from this project's root using your Godot executable:

```text
Godot --headless --path . --script res://character_assets/source/check_character.gd
Godot --headless --fixed-fps 60 --path . --script res://bedroom_assets/source/check_first_person.gd
```

The character check covers foot clearance, level soles, motion, blinking, greeting transitions, optional backpack, external control and preview buttons. The existing first-person check verifies the current bedroom behavior. Front, rear, wave, jogging and compact-window renders are recorded in `../.impeccable/review/`. These are scoped behavior and visual checks, not a target-device performance benchmark.

The prior character source, scene, animation and README are retained in `source/before_player_refresh/`.

An eight-second animated preview is saved in `preview/character-animations.gif`. It was rendered from the actual Godot model, with two seconds each of Idle, Walk, Jog and Wave. To regenerate it, run `source/capture_character.gd` with the user argument `--animation` using a graphical Godot process, then run `source/package_animation_preview.py` with Python and Pillow. These tools are only for packaging the preview; the character itself requires only Godot.

## First-person camera smoothing

The bedroom player keeps the previous and current physics positions. The camera interpolates between them each rendered frame while applying mouse rotation immediately. Spawn and fall recovery reset the position history; direct external teleports also reset it when sampled. This is local to the bedroom controller and does not enable project-wide interpolation or alter the opening flight.

Regression check (240 frames per second against the default 60 physics ticks):

```text
Godot --headless --fixed-fps 240 --path . --script res://bedroom_assets/source/check_camera_smoothing.gd
```

The deterministic walking sample improved from 90/120 stationary camera frames to 1/120, with maximum position steps reduced from 0.03667 m to 0.00917 m. Existing first-person controls and 2,112 collision/movement frames, including the intro handoff, also pass. This verifies camera pacing, not GPU rendering performance.

