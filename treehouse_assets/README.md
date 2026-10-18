# Treehouse garden

Open `res://treehouse.tscn` and press F6. This is an editable environment scene; the main game scene is unchanged.

## Tree and access

The tree has a broad, solid trunk with rounded root buttresses that merge into the lawn. A dominant leader leans left above the cabin, with a long low western bough and shorter eastern branches emerging much higher and farther back. Twenty-seven rotated, uneven foliage clusters form an off-center canopy, with gaps exposing the branch junctions. A central upper leader and several connected forks extend above the roof, while rear branches fill the tree in depth. A short old spur and drooping outer twig interrupt the silhouette. A living fork passes through fitted openings in the upper deck, left cabin wall and roof edge, with a framed recess and timber rim. A second fork cradles the platform from below and meets a timber saddle, then extends visibly beyond the right balcony. It clears the balcony, curves upward and back toward the cabin, and fills the gap beside the roof with two leafy offshoots. This compact returning curve remains distinct from the long western branches. Deck planks are cut around both western forks as well as the rear trunk. Outward-facing trunk geometry keeps the base solid.

The upper wraparound deck measures approximately 12.7 by 10.4 m, leaving generous space around the 5.7 m wide shelter. The lower lookout measures 9 by 9.2 m and has a larger opening for the thicker trunk. Both decks have perimeter railings with deliberate ladder openings.

Two ladder flights form a route from the ground to the 3.2 m lookout, across its front landing, and up to the 6.12 m upper deck. Their treads meet the deck surfaces, and the stringers extend above each landing as handholds. The garden path meets the ground ladder.

## Neighborhood

The approximately 32 by 39 m garden belongs to `NeighborhoodSlice/House_West_03`. Eighteen houses remain, together with source streets, sidewalks, cars and gardens. The previous garden expansion removed three neighboring houses and nearby trees/props.

Retained source objects keep their exact transforms under `NeighborhoodSlice`. `WorldEnvironment` and `Sun` are copied directly from `neighborhood_assets/preview/neighborhood_filled.tscn`: sky, ambient light, fog, tonemapping, sunlight direction/color/energy and shadows are unchanged.

## Reusable models

One Godot unit is approximately one metre. Each model is available as an editable `.tscn` and an exported `.glb`:

- `models/treehouse_oak`: complete tree, cabin and platform assembly.
- `models/living_tree`: thick trunk, six root buttresses, branching limbs and twenty-seven foliage clusters.
- `models/branch_platforms`: enlarged decks, trunk openings, perimeter rails, braces and connected ladder flights.
- `models/treehouse_cabin`: cedar shelter, steep roof, windows and pennant.

The roof ridge is approximately 12.5 m high; the tree reaches approximately 22.5 m. Source neighborhood models retain their original scale.

## Editing and rebuilding

`TreehouseBackyard/Treehouse` is the complete assembly instance. Its tree, cabin and platforms remain separate editable model instances.

`Views/BackyardCamera` is the default view. `Views/NeighborhoodOverview` shows the expanded garden and surrounding houses.

Run Godot with `--headless --path . --script res://treehouse_assets/source/build_treehouse.gd` to regenerate the scene and models. Rebuilding overwrites generated files; preserve manual edits first. `source/build_report.json` records omitted source objects.

`source/check_treehouse.gd` verifies exact source environment/sun properties, retained transforms, house count, garden dimensions, ladder landing support, the connecting deck route, outward trunk normals and absence of lesson UI. Append `-- --capture` to a graphical run to generate `preview/treehouse.png`, `preview/neighborhood.png` and `preview/deck_access.png`, and `preview/trunk_joinery.png`.

`preview/tree_only.png` shows the same tree with the cabin and platforms hidden only during capture, allowing its independent shape to be reviewed.
