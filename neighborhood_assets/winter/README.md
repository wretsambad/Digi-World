# Winter neighborhood

Use `res://neighborhood_assets/preview/neighborhood_filled_winter.tscn` as the game environment. It has no camera, player controller, intro UI, camera path, opening animation, or bedroom handoff.

For inspection, open `res://neighborhood_assets/winter/preview/winter_preview.tscn` and press **F6**. Its separate free camera uses **WASD**, **Q/E** for down/up, **Shift** for faster movement, and **right-drag** to look around. The preview camera and input script are not part of the map.

This is a new scene. `neighborhood_filled.tscn`, the project main-scene setting, and `treehouse_animated.tscn` are unchanged.

The winter layout has three distinct destinations: **Frost Pond** with an ice surface, log benches, lanterns and a snowman; **Birch Grove** with bare birches, spruce trees, stacked logs, sleds and footprint trails; and **Sled Hill** with a shaped slope, runner tracks and a collision surface. The village also has roadside snowbanks, a mix of bare and evergreen trees, muted house colors, patchy roof snow, and wind-shaped ground shading.

The lighting uses bright golden hour: a low yellow sun with energy **0.58**, warm neutral ambient fill at **0.50**, a pale gold horizon, soft lavender-blue upper sky, and dim warm streetlights. Snow retains its surface variation and visible detail in shadow. The fall treehouse's sky shader remains shared with a separate winter palette; original scenes and assets remain untouched. `winter_lighting.gd` defines this palette. Run `source/update_winter_lighting.gd` to refresh lighting alone while preserving map edits.

Select and move complete objects in the map: one tree, house, snowman, sled, bench, lantern, footprint trail or snowbank at a time. Each is a grouped scene instance. Branches and attached snow remain inside their tree; the ice and shoreline snow form one pond object; each log bench includes its legs. The reusable assets live in `objects/` if component editing is needed. Organizational parents keep destinations together, and the map has no runtime MultiMesh batching. `source/group_winter_objects.gd` applies this grouping to an existing map without changing its layout or sunset lighting.

`GameplayAnchors` provides `PlayerSpawn`, `PondEntrance`, `GroveEntrance`, and `HillStart` markers for the future game. These are placement anchors, not game mechanics. The pond and hill have collision surfaces; player movement, objectives, and a complete navigation/collision pass belong to the game that instances this environment.

`WinterAmbience` follows the host game's active camera. Assign `camera_path` to override that choice, toggle `snowfall_enabled` for weather, and set `weather_exposed = false` when indoors. It safely stays inactive when there is no camera. It has no dependency on the original opening sequence.

To regenerate the winter scene and isolated material variants from the original:

```text
Godot --headless --path . --script res://neighborhood_assets/source/style_winter.gd
```

To validate the independent map, lighting, weather binding, markers and hill collision:

```text
Godot --headless --path . --script res://neighborhood_assets/source/check_winter.gd
```

For graphical preview captures, omit `--headless` and append `-- --capture`. The checker writes `validation.json`; images are saved in `preview/`.
