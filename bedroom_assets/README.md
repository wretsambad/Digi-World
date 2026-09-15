# Digi-World connected teenage bedroom

Open `res://bedroom_assets/window_transition_preview.tscn` in Godot and press **F6** to test the street-to-window flight and real scene switch. Open `res://bedroom_assets/teen_bedroom.tscn` to inspect the destination directly.

The existing `neighborhood_assets/preview/neighborhood_filled.tscn` now uses the same detailed house at `ExistingNeighborhood/LearningHouse`. Its old bedroom furniture and extra fill light were removed. All other neighborhood nodes, houses.tscn, the main scene and project startup settings remain unchanged. The transition preview remains a separate copy of the neighborhood with the shared detailed house. It demonstrates the final street approach; it does not replace the project's opening/menu sequence.

## Scenes and editing

| File | Purpose |
| --- | --- |
| teen_bedroom.tscn | Separate destination: detailed house, nearby scenery, matching lighting and interior cameras. |
| learning_house_detailed.tscn | Shared original house shell/window sash, teenage furnishings, interior finishes, four lesson objects and local lights. Edit this scene to update both sides of the switch. |
| nearby_neighborhood.tscn | Baked nearby exterior only: 544 instances including 10 neighboring houses, 80 trees, roads, sidewalks, cars, fences, gardens and cropped ground. |
| neighborhood_environment.tres | Matching snapshot of the current neighborhood's sky, ambient lighting and fog. Shared by the preview and destination. |
| window_transition_preview.tscn | Separate full-neighborhood approach preview. The full neighborhood is removed when the bedroom becomes current. |

The destination has no dependency on the full neighborhood scene. Nearby buildings and props retain their exact current source transforms. Distant existing trees preserve the view beyond the street. This finite set is intended for the room's window views, not roaming outside the retained neighborhood.

## Alignment and transition

The shared house is aligned to the actual `ExistingNeighborhood/LearningHouse` in `neighborhood_assets/preview/neighborhood_filled.tscn`. The interior origin is approximately **(15.4006, 3.4719, -28.9897)** in neighborhood coordinates. Its fitted floor measures approximately **6.52 x 7.52 meters**, within the existing upper floor and ceiling. Thin interior wall finishes retain the actual shell and window passage.

The window center is approximately **(11.8406, 5.5519, -29.2897)**; the existing outward-open sash stays in place. `WindowPassage` and `InsideHandoff` are named markers in the shared house. Keep the shared scene at its authored world coordinates, or transform both sides and the flight path together.

The preview follows its editable `WindowApproachPath` over eight seconds. Once the camera is about 1.5m inside the window, `window_transition.gd` changes to the preloaded bedroom scene. It hands over the exact world transform, FOV, near/far planes and aspect mode. `bedroom_arrival.gd` preserves the first drawn pose, then eases the camera to the interior view over four seconds. The shared house and lighting are already present before entry; there is no fade or visible interior replacement at the threshold.

The environment and sun match the neighborhood. Shared local fill lights provide warm interior illumination. Any later neighborhood/environment changes require refreshing these matching scenes with the connection builder.

## Lesson objects and models

Under `LearningHouseDetailed/BedroomInterior`, `Lesson_Computer`, `Lesson_Phone`, `Lesson_SharingBoard` and `Lesson_BackupRobot` retain their local `FocusAnchor` markers and visual-placeholder metadata. These objects have no click handlers, lessons or gameplay. Only the preview/arrival camera is animated.

The 65-model GLB library and editable Blender collections remain available. Connected placement is recorded in `connected_placement.json`; the earlier `placement.json` describes the archived standalone layout. Some standalone architectural models are intentionally unused because the connected room shares the neighborhood house shell. Individual furniture, props and native interior finish meshes remain editable.

## Validation and source

All new scenes load in Godot 4.7.2 using the project's Compatibility/OpenGL renderer. Checks confirm exact retained exterior transforms, four static lesson groups, a 1,629-ray camera corridor through the street bend/window/arrival, and an actual scene change with the first camera pose/lens preserved. The cropped scene's window view closely matches the full scene. Static review accepted the supplied exterior/interior and handoff views; a small pendant-area ceiling-shadow update is visible at the cut, so the frames are not pixel-identical. Playback performance on target devices has not been benchmarked.

The initial connection pass preserved 156 non-bedroom files. The subsequent requested synchronization changes only neighborhood_filled.tscn among authored scenes; all unrelated node blocks in that scene and all other scene files remain unchanged. Checks confirmed 182 matching imported-model placements between the actual neighborhood house and the separate bedroom. The old standalone room and its documentation are preserved in `source/before_neighborhood_connection/`.

To refresh from the current neighborhood in Godot's command line, run `--headless --path <project> --script res://bedroom_assets/source/connect_bedroom.gd`, then `source/export_connected_inventory.gd`. This regenerates the connected scenes from the preserved standalone furnishings and current neighborhood; preserve later hand edits before regenerating. The old standalone assembler/finalizer now stop rather than overwrite the connected scene. `source/check_bedroom_connection.gd -- --check` runs geometry/structure checks; without `--check`, it captures views into Godot's user-data folder and tests the real handoff.

`Digi-World-connected-bedroom.zip` is an additive bedroom-assets package for the existing Digi-World project. It reuses that project's neighborhood GLBs.
