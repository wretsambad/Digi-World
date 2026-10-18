# Protect Your Base

Lesson 1. It plays inside the bedroom computer and is set in `treehouse_animated.tscn`.

## Play

Run the main scene, get to first-person in the bedroom and click the outlined computer. The boy sits down and types (the existing animation in `scripts/typing_animation.gd`). The camera then moves over his shoulder while he double-clicks the game icon, dives into the monitor and cross-fades to full screen. At the end it pulls back out while he celebrates. **Continue** returns you to the bedroom to pick another object.

To work on the lesson alone, run `scenes/monitor_game/monitor_game.tscn` (F6).

Keys: Enter or Space for Next, 1–4 to pick a password.

## Flow

`LessonStateMachine`: Intro → Customize → Step1 → Step2 → Step3 → Finale. It emits `step_completed`, `mistake_made` and `repaired`.

1. **Intro**: Pip waves and says hello.
2. **Customize**: pick the treehouse colour (8), a flag design (10), the flag colour (8) and Pip's colour (8), with a live preview. The choices are stored in the `PlayerProfile` autoload (memory only).
3. **The Glitch arrives** and climbs the ladder. Pip gets worried. The frosted alert reads "Let's build a strong password to keep it out!"
4. **Three steps, four options each.** The pretend password builds up: `treetopcastle` → `TreeTopCastle` → `TreeTopCastle#47`.
   - Step 1 adds a wooden gate and fence around the ladder. The Glitch hops over the fence.
   - Step 2 makes the fence taller and the gate bigger. The Glitch climbs the branch route instead.
   - Step 3 slides metal guards over the branches and metal-plates the fence and gate.
5. **Mistakes**: each wrong option has a prank:
   - `flag_swap`: the Glitch puts up a sock flag.
   - `paint`: lime paint and pink splats on the cabin.
   - `fold_wall`: a plastic wall folds like paper.
   - `steal_hat`: the Glitch takes Pip's beanie.

   Pip looks sad. A frosted, typewritten explanation and tip follow. The player then picks again with the wrong option crossed out. The correct pick repairs everything and restores the `PlayerProfile` colours, flag and hat. There is no game over.
6. **Finale**: the Glitch slips off the metal, bounces off the gate and runs away. Pip cheers, the flag waves and the camera orbits. A Great Job card lists the 3 rules.

## Editing

- `data/protect_your_base.json`: all lines, steps, options, explanations, tips and the prank for each wrong option. Every step needs exactly 4 options. `correct` must agree with `scripts/PasswordRules.gd`, and the test checks this.
- `scripts/PasswordRules.gd`: rules checked in order (`common`, `personal`, `length`, `mixed_case`, `number`, `symbol`), plus a 0–4 strength score for the meter.
- `scripts/ProtectYourBase.gd`: the lesson script and the named camera `SHOTS` (eye, target, fov).
- `scripts/TreehouseBase.gd`: positions of the ladder, fence, branch route, flag and Pip; the defense builds; the pranks and repairs.
- `scripts/CameraDirector.gd`: glides, follow shots, orbit, shake and handheld drift.
- `scripts/Pip.gd`, `scripts/pip_outfit.gdshader`: Pip's jacket colour comes from a vertex-alpha mask baked by `protect_base_assets/source/sculpt_pip.gd`. Moods (Happy, Worried, Cheer, Sad) are in `pip_animation.gd`.
- `scripts/Glitch.gd`: the voxel Glitch and its moves.
- `ui/LessonUI.gd`, `ui/frost.gdshader`, `ui/DesktopScreen.gd`: all 2D screens, on a 1280×720 canvas.
- `scripts/ComputerSession.gd`: the bedroom side (monitor SubViewport, camera choreography, cross-fades, celebration, Continue).

## Safety

All passwords are made-up examples, and the player never types one. Nothing is saved to disk, collected or sent over a network. Sounds are synthesized on the device.

## Tests

```
godot --headless --path . res://tests/lesson_flow.tscn
godot --headless --path . res://tests/bedroom_flow.tscn
```

`lesson_flow` checks that the data agrees with the validator, then plays every step with wrong picks first (all 4 pranks). It checks that each repair restores the custom colours, flag, Pip's colour and hat, and that the lesson reaches the finale. `bedroom_flow` clicks the computer from first person, plays the whole lesson, returns, and presses Continue. Append `-- --capture` (and drop `--headless`) to save screenshots to `work/review/`.
