# Digi-World recreation areas

The three recreation placeholders are complete in `C:/Users/samar/Documents/digi-world/neighborhood_assets/preview/neighborhood_filled.tscn`.

## Find and edit the areas

Under ExistingNeighborhood, select BasketballCourt, WillowPark or SoccerArea. Each is a local Node3D group with separately editable model instances; no runtime generation script is required.

| Area | Approximate center (X, Y, Z) | Contents |
| --- | --- | --- |
| BasketballCourt | 23.50, 0, 64.36 | Compact 12 x 18m surface, painted lines, two hoops with nets, basketball, partial ball fencing, benches, fountain and entrance path |
| WillowPark | -26.89, 0, 63.21 | 24 x 18m fenced walking loop, play surface, sheltered slide tower, two swings, sandbox, picnic tables, benches, planting, bike parking, bins and fountain |
| SoccerArea | 56.01, 0, -40.21 | Small 12 x 18m turf area, field markings, two netted goals, ball, end fencing, spectator benches and path to the cross-street sidewalk |

These are finished scenery models. Sports controls, ball physics, swing animation and permanent collision shapes were not added.

## Assets and preservation

There are 21 recreation GLB models in `neighborhood_assets/recreation_models`, placed as 96 separate instances. Their combined unique geometry is 14,694 triangles before scene repetition. Embedded materials match the existing low-poly neighborhood palette. `neighborhood_assets/source/recreation_amenities.blend` retains named model collections and individual source parts.

The park's nested marker was converted using its world position, so its placement does not inherit the fence's rotation or five-times scale. Four existing trees were moved to the edges, and one hedge was shortened to open the soccer entrance. All other existing scene/resource definitions, including the latest lighting edits and the two driveway placeholders, were preserved exactly.

Only the scene containing your markers was updated. `houses.tscn` and the reusable dressing scene remain independent and were not overwritten. A pre-edit backup is in `neighborhood_assets/source/before_recreation/neighborhood_filled.tscn`. The source placement script reconstructs this pass from that snapshot; do not run it over subsequent hand edits without reviewing it.

## Validation

All 21 GLBs and the updated scene load in Godot 4.7.2. The three recreation groups contain 96 individually owned models, and the three recreation placeholder meshes and labels are removed. Fourteen temporary collision rays through the playing lanes and entry connections were clear at a height of 1.2m. Five final views cover all three areas and the park/court street approaches. These checks do not constitute a target-device performance benchmark or implemented sports gameplay.

`Digi-World-recreation-areas.zip` is a restore package for the existing project; it contains the updated neighborhood_assets folder. Open the neighborhood_filled scene to see this update.

## Park enlargement and Soccer sign

WillowPark now covers 24 x 18 meters (432 square meters), up from 18 x 14 meters (252 square meters). The slide, swings, sandbox, picnic tables and benches are spread across the larger space. Thirty cream-and-teal picket fence sections enclose the park, with a three-meter opening at the street entrance and a second opening to the north. The path loop stays two meters wide; the expanded play surface is 14 x 11 meters.

The park now has 55 separate model instances. One nearby oak was moved two meters farther west to clear the new boundary. All non-park scene definitions apart from that tree remain unchanged. The Soccer sign's lettering is now exactly “Soccer”.

Eighteen temporary rays across 0.8-meter corridors confirmed both entrances and all four sides of the walking loop remain clear at 0.75 meters above ground. Final previews show the expanded park, street approach and Soccer sign. The scene and Blender source are saved in the project; the pre-edit scene and source are in source/before_park_expansion.
