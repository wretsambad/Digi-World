# Digi-World expanded neighborhood

The neighborhood now uses ordinary building proportions, with approximately one Godot unit per meter. It contains a 210 x 240 meter ground area, 25 houses, 215 large trees and 1,040 individually editable model instances.

## Open the updated scene

Open `C:/Users/samar/Documents/digi-world/houses.tscn` in Godot and press F6.

The same expanded layout is also in `C:/Users/samar/Documents/digi-world/neighborhood_assets/preview/neighborhood_filled.tscn`. Both files are ordinary authored scenes, with a Node3D root and a local `ExistingNeighborhood` Node3D. Every house, tree, car, paving piece and room object is directly instanced beneath that node. It is no longer a CharacterBody3D or a nested instance of houses.tscn. Edit either scene independently; edits do not synchronize between the two copies.

The main game startup scene and lesson scripts were not changed. F6 runs the scene you have open. The included camera nodes are OpeningCamera, OverviewCamera and BedroomCamera; switch their Current property to choose a running view. In the editor, the usual 3D scene navigation also lets you inspect everything freely.

## What changed

- Six detailed house variants derived from the existing models, enlarged about eight times. House widths span approximately 8–14 meters, with different roof and wall colors, porch steps and columns, canopies, planters, awnings, chimneys and pergolas. They retain the original low-poly visual character.
- A separate LearningHouse with a 12 x 10 meter footprint, real window openings and a furnished upper-floor bedroom of approximately 7.4 x 6.6 meters.
- New full-size road modules, 1.8-meter-wide sidewalks, approximately 15-centimeter curbs, driveway pads and curb-cut aprons. Main road width is 7.2 meters.
- Ocean blue, sage, yellow, lilac and cream compact cars.
- Three broad tree forms, generally 9–12 meters tall before instance variation; the surrounding tree belts include larger versions. Front gardens, layered tree lines and low hills fill the camera's distant views.
- Separate bedroom models for the bed, desk, chair, computer, phone, bookshelf, rug, lamp, artwork, curtains and open window sash.

The 34 new GLB files are in `C:/Users/samar/Documents/digi-world/neighborhood_assets/expanded_models/`. The earlier 32 prop files remain in the sibling `models/` folder. Earlier props are placed at suitable larger scales in this scene. New GLBs generally import at scale 1 with meter-like dimensions; curtains and window sash use installation pivots rather than ground pivots.

## Bedroom and fly-through preparation

LearningHouse is centered at world (17, 0, -27) and faces the main street. Bedroom floor elevation is approximately 3.51 meters. Its open front window is around world (12, 5.6, -29.3). The sash is a separate model swung outward 72 degrees to leave enough passage for the camera; it can be animated independently later.

The FlyThroughMarkers node records StreetStart, StreetApproach, WindowApproach, WindowPassage and BedroomArrival. These are editable route markers, not a completed animation. The window and bedroom are real geometry; the room is not a facade or a separate cutaway stage. Computer_LessonAnchor and Phone_LessonAnchor are individually placed models ready for later lesson interactions.

Only the featured house has a furnished, enterable bedroom. The other detailed houses are background exteriors. Game movement, Play-button animation, lessons, navigation and persistent collision shapes are not implemented by this environment update.

## Editable models and backups

- `C:/Users/samar/Documents/digi-world/neighborhood_assets/source/expanded_neighborhood.blend` contains the editable new models, one named collection per model. Source geometry retains separate parts. GLB exports combine static parts into a single mesh with material surfaces to avoid unnecessary per-part scene nodes.
- `expanded_catalog.json` and `source/expanded_catalog.csv` list dimensions and triangle counts. The new unique model geometry totals 65,734 triangles; placement instances multiply render geometry, and actual game performance has not been benchmarked on target devices.
- `preview/neighborhood_dressing.tscn` contains the expanded environment without the houses, bedroom furniture, lights or cameras, for reuse inside another scene.
- `source/before_expansion/` contains the pre-edit houses scene and earlier populated/dressing scenes. This folder sits beneath `.gdignore` so Godot does not import backup scenes or source spreadsheets.

## Checks completed

Loaded all 34 new GLBs in Godot 4.7.2. Checked both main neighborhood scenes have local Node3D containers with 1,040 directly owned instances. Checked the GLB structure, finite position bounds and triangle counts. Tested nine parallel rays across a 0.36-meter camera corridor through the house, sash and curtains into the bedroom. Rendered the opening street, full map, learning-house exterior and bedroom using the project's Forward+ renderer on D3D12.

## Backup package

`Digi-World-expanded-neighborhood.zip` contains the updated houses.tscn and neighborhood_assets folder. Extract into the existing Digi-World project to restore this update. This is an environment package, not a standalone replacement for the project's lesson code.
