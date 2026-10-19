# Sharing Board with the authored winter neighborhood

This is the two-round Sharing Board game from GitHub main. The existing card sorting, felt UI, photo clues, posting, completion and bedroom return are retained.

Run the main game and click the sharing board in the bedroom, or run `round1.tscn` / `round2.tscn` directly with F6.

`winter_neighborhood.tscn` instances `res://neighborhood_assets/preview/neighborhood_filled_winter.tscn` directly. Keep the entire `neighborhood_assets/winter/` folder with that scene: it contains the grouped whole objects, isolated materials, weather and preview. The winter map is preserved as an independent environment with no lesson cameras or opening sequence. Its existing golden sunset lighting and camera-following snowfall remain in charge; the former runtime snow conversion and duplicate GPU snowfall are no longer used.

The GitHub game's snowmen, park board, cameras and clue props remain in the lesson wrapper/scenes. The window name flag is mounted beside the authored map's upper window. Round 2's photo camera inherits the map environment, so the photograph uses the same winter lighting as the neighborhood.

Validation:

- Run `res://tests/sharing_winter_flow.tscn` with a graphical renderer. It enters through the bedroom board, sorts all eleven cards, pins public patches, starts round 2, selects all five clues, covers and posts the real rendered photo, returns to the bedroom and reopens the lesson. Append `-- --capture` to save review images under ignored `work/runtime/github_winter_review/`.
- Run `--headless --script res://neighborhood_assets/source/check_winter.gd` to check whole-object selection, landmarks, lighting, weather and hill collision.
- Existing `tests/lesson_flow.tscn` and `tests/bedroom_flow.tscn` cover the first lesson.
