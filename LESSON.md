# Protect Your Base

The prior lesson implementation, world builder, rules, data, scene wrappers, and autoload implementations were deleted before this replacement was authored. The opening's typing/hand animation methods were retained in `scripts/typing_animation.gd`. Existing neighborhood assets, bedroom opening, character, Fredoka font, text writer, and sculpted Pip are reused as required by the brief.

## Play

Run the project's normal main scene for the neighborhood opening. Enter first-person mode and click the outlined computer. The preserved typing sequence leads into the new lesson. Complete customization, choose one of four pretend examples in each step, and return to the bedroom after the finale.

For direct lesson development, run `scenes/monitor_game/monitor_game.tscn`. For the bedroom entry, run `scenes/bedroom/bedroom.tscn`.

Mouse: click options. Keyboard: Tab/Shift+Tab to focus, Enter/Space to activate, or 1–4 for password choices. Sound and gentle motion controls are visible throughout. Pip's lines appear as typewritten subtitles.

## Structure

- `autoload/`: local cosmetic profile, completion state, generated placeholder audio.
- `scripts/ComputerSession.gd`: shared SubViewport screen, original opening choreography, crossfade, return and celebration.
- `scripts/MonitorGame.gd`: lesson orchestration and neighborhood stage.
- `scripts/LessonStateMachine.gd`: Intro, Customize, Step1, Step2, Step3, Finale; step_completed, mistake_made, repaired signals.
- `scripts/PasswordRules.gd`: fake-example validation and explanations.
- `data/protect_your_base.json`: three editable steps, four options per step, correctness and teaching explanations.
- `scenes/treehouse`, `scenes/pip`, `scenes/glitch`: reusable lesson actors.
- `ui/LessonUI.gd`: scalable 1280×720 workshop UI.

Each step is cumulative: mossycomet → MossyComet → MossyComet7!. The meter counts these three teaching rules; it does not predict real password security. JSON correctness must agree with PasswordRules; the test checks all 12 entries.

Pranks rotate through sock flags, lime paint, and a folding gate. A correct retry restores profile choices, upgrades the gate/lock/shield, and emits repaired. No game-over state exists.

## Assumptions and scope

- The 8-letter minimum is the brief's teaching threshold. Finale guidance also encourages longer, unique real passwords and trusted adult help.
- Next lesson opens the existing sharing-board preview; a second lesson game was not supplied.
- Cosmetic settings persist locally in `user://player_profile.cfg`; lesson completion is session state. No child identifiers or passwords are stored.
- Pip's supplied sculpt is preserved, with a shader that recolors fur while retaining painted markings.
- Simple lighting is used instead of costly volumetrics or depth-of-field effects. Procedural meshes are intentional placeholders for the new treehouse and Glitch.
- Music, clicks, snaps, boings, and celebration notes are generated placeholder audio.

## Verification

Run Godot 4.x with `--headless --path . res://tests/lesson_flow.tscn` for validator/data consistency, eight customization choices, all three pranks and repairs, profile restoration, signals, upgrades, and finale.

Run `--headless --path . res://tests/bedroom_flow.tscn` for first-person computer picking/click, preserved typing handoff, shared viewport, completion, camera return, and Next lesson preview.

To capture rendered evidence, run either test without `--headless` and append `-- --capture`. PNGs are saved under `.impeccable/review/new-*.png`. The tests use the active profile; run them with a separate user-data directory/environment to avoid changing your cosmetics.
