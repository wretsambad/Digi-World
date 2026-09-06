---
name: Digi-World expanded neighborhood
description: A colorful low-poly neighborhood with full-size buildings, a furnished learning-house bedroom and three recreation areas.
colors:
  mint: "#61CB8B"
  leaf: "#4EAC76"
  light-leaf: "#8DDD9B"
  grass: "#A3CDA0"
  cream: "#F9EFDA"
  coral: "#FF7E44"
  slate: "#515566"
  teal: "#407E80"
  roof-blue: "#5D7598"
  clay: "#BC765B"
  sage: "#759E86"
  lavender: "#9487AD"
  butter: "#F4DEAA"
  peach: "#F0C9AF"
  court: "#487F88"
  courtkey: "#D79B79"
  rubber: "#DCB574"
  sand: "#EAD39B"
  net: "#D2DED6"
  turf: "#79B080"
  turf2: "#70A677"
---

# Design System: Expanded Neighborhood

## Overview

The neighborhood extends the original mint-roof, cream-wall visual identity into a colorful, low-poly residential environment for children learning data security. Buildings now have ordinary architectural proportions, varied exteriors and generous tree cover. The featured LearningHouse includes a real furnished upper-floor bedroom. The independently edited preview scene also contains a basketball court, Willow Park and a small soccer area at the user's former recreation markers. This document describes the environment assets and current authored scenes; it does not govern interface design.

## Colors

Mint, cream and coral retain the inherited identity. Teal, roof blue, clay, sage, lavender, butter and peach broaden the house and furnishing palette while keeping its soft painted character. Leaf and light-leaf separate faceted foliage masses; grass provides a quieter ground field. Slate anchors dark structural details. Maintain separation between pale walls, trim, paving and furnishings under scene lighting. GLBs carry embedded materials and do not require external textures.

Recreation materials extend the same painted palette: muted teal `court` defines the basketball surface, warm `courtkey` separates its keys, golden `rubber` identifies the play surface and pale `sand` fills the sandbox. `turf` and `turf2` make restrained soccer stripes; pale `net` keeps the modeled net cords visible. These tokens match `build_recreation.py`. Existing mint canopies, coral play equipment, cream backboards, teal frames, timber furniture and concrete paths tie the areas to the neighborhood. White sports markings remain distinct from the colored surfaces. Keep fences and nets visibly open rather than using opaque panels.

## Layout

The original ground area covers approximately 210 x 240 meters and now extends into screened road bends. The earlier fill layout recorded 31 houses, 350 large trees and 1,583 individually editable model instances per main scene; the reusable dressing scene contains 1,540. The current independently edited `../preview/neighborhood_filled.tscn` contains 1,676 model instances after recreation placement. Its pre-recreation layout already included user edits, so its total is not the earlier 1,583 plus 96. `../../houses.tscn` and the reusable dressing scene retain their earlier layouts and were not updated for recreation. Approximately one Godot unit represents one meter. Six original-derived house models are enlarged eight times, with widths of approximately 8-14 meters. The earlier 32 props retain their original compact dimensions and require suitable scene scaling; the new models generally import at scale 1.

The main road is 7.2 meters wide; sidewalks are 1.8 meters wide with approximately 15-centimeter curb heights. Front gardens, layered tree belts and distant low hills fill street and overview compositions. Trees use broad forms approximately 9-12 meters tall before instance variation.

Six additional peach/cedar houses, front paths, layered gardens and corner vegetation fill gaps near the origin and through street turns. East, west and south road ends continue into tree-screened curves, with partial upper-facade and roof silhouettes suggesting more homes beyond. The scenery remains finite; preserve the screened continuation illusion from street height. The fill pass added 568 instances to each main scene and removed 16 trees and nine distant mounds to clear the new roads. A temporary geometry check found all 936 rays clear along the new curve centerlines, across a 0.36-meter camera corridor at 2.4 meters above ground.

LearningHouse has a 12 x 10 meter building footprint, with exterior details extending beyond it. It is centered at world (17, 0, -27). Its upper bedroom measures approximately 7.4 x 6.6 meters, with the floor at elevation 3.51 meters. Keep the real front window passage clear: the separate sash is open outward 72 degrees, and curtains flank the opening. Nine parallel rays validated a 0.36-meter camera corridor through the house, sash and curtains.

Both `../../houses.tscn` and `../preview/neighborhood_filled.tscn` contain the expanded layout, with a Node3D root and a local `ExistingNeighborhood` Node3D. The two scenes are independently editable copies; subsequent edits do not synchronize. The recreation pass changed only the preview scene containing the user's markers. Its 96 recreation placements are individually owned model instances inside three local Node3D groups beneath `ExistingNeighborhood`; they are not flattened into one environment mesh. The earlier fill pass preserved surviving original node definitions against `before_sightline_fill/`. The recreation pass preserves the latest scene against `before_recreation/neighborhood_filled.tscn`, except for the three replaced placeholder meshes and labels, four trees moved to area edges and one hedge shortened for the soccer entrance. All other existing scene/resource definitions, including user lighting and the two driveway placeholders, remain exactly preserved. Preserve Godot +Y up and each model's documented pivot. Curtains and sash use installation pivots rather than ground pivots.

### Recreation areas and access

| Group | Approximate world center (X, Y, Z) | Layout |
| --- | --- | --- |
| `BasketballCourt` | (23.50, 0, 64.36) | Compact 12 x 18-meter court including runoff, two hoops, painted lines, partial ball fencing, benches and a sidewalk entrance path. |
| `WillowPark` | (-26.89, 0, 63.21) | 18 x 14-meter walking loop with 2-meter-wide paths, a 10 x 8-meter play surface, play equipment, seating, picnic tables and planting. |
| `SoccerArea` | (56.01, 0, -40.21) | 12 x 18-meter turf area with a 10 x 16-meter marked field, two goals, end fencing, spectator benches and a path to the cross-street sidewalk. |

Keep the connected paths, fence openings and sports lanes visually clear when adjusting furniture or planting. Park placement uses the nested marker's world position, avoiding its former fence parent's rotation and five-times scale. Basketball linework is decorative for a compact neighborhood court; it is not a regulation venue. Fourteen temporary collision rays through sampled sports lanes and entrance connections were clear at 1.2 meters above ground. This is a limited geometry check, not a complete traversal, accessibility certification or permanent collision setup.

## Elevation & Depth

Solid geometry, faceted surfaces and scene shadows provide depth. Retain the user's current authored lighting; earlier recorded sun, ambient and fog values no longer describe the scene. The earlier seven street-level captures use the project's existing Forward+ lighting and received a SHIP disposition with no material fixes from the independent finish review. That acceptance covers the sampled static views: origin, both junction directions, both outer bends, south end and farther around the east bend. Five final recreation views cover all three areas and the park/court street approaches; their visual review found no visual fixes. These sampled static views do not establish a complete fly-through or target-device performance.

## Shapes

Preserve readable low-poly silhouettes and simplified painted surfaces. House variation comes from roof and wall colors, porch steps, columns, canopies, planters, awnings, chimneys and pergolas. Broad overlapping foliage masses and recognizable compact cars support the larger architectural scale. Furniture should remain recognizable at bedroom camera distance.

## Components

The pack contains 97 GLBs: 32 original props in `../models/`, 34 expansion models in `../expanded_models/`, ten continuation models in `../sightline_models/` and 21 recreation models in `../recreation_models/`. The continuation set comprises road, sidewalk and curb sets for three curves, plus a distant roofline model; those ten and the three scenes updated by that earlier pass loaded successfully in Godot 4.7.2. All 21 recreation GLBs and the updated preview scene also load in Godot 4.7.2. The 34 expansion models alone total 65,734 triangles; the 21 recreation models total 14,694 unique triangles before repeated placement. Repeated placement increases rendered geometry, and target-device performance has not been benchmarked.

`expanded_neighborhood.blend` retains separately editable parts in named model collections; `sightline_continuations.blend` retains the new continuation geometry. GLB exports merge static parts into one mesh with material surfaces. The bedroom contains separately placed bed, desk, chair, computer, phone, bookshelf, rug, lamp, artwork, curtains and sash models. Only LearningHouse has a furnished, enterable interior; the six other house variants are background exteriors.

`recreation_amenities.blend` retains named model collections and individual source parts for the new recreation assets. `BasketballCourt`, `WillowPark` and `SoccerArea` contain 22, 55 and 19 separately editable placements respectively, combining the new GLBs with existing benches, bins, bicycle parking and planting. Hoops and goals have modeled open nets; the park includes a sheltered slide tower, two-seat swing frame, sandbox, picnic tables, drinking fountain and signs. These are static scenery models. Sports controls, ball physics, swing animation and permanent collision shapes were not added; no runtime generation script is required to display the placed areas.

In `../../houses.tscn`, FlyThroughMarkers records the intended camera route and saved cameras remain available. The independently edited `../preview/neighborhood_filled.tscn` has no saved cameras or route markers. The computer and phone have lesson anchors. These are preparation assets: camera animation, lesson logic, navigation and permanent collision shapes are not implemented. `../sightline_routes.json` records sampled centerlines for future animation along the new curves.

See `../README.md`, `../expanded_catalog.json`, `../expanded_scene_summary.json`, `../sightline_catalog.json`, `../sightline_placement.json` and `../sightline_changes.json` for earlier usage, dimensions and layout facts. `../RECREATION.md`, `../recreation_catalog.json` and `../recreation_placement.json` describe the current recreation update. Pre-expansion scenes remain in `before_expansion/`; `before_sightline_fill/` preserves the user's scenes immediately before the street-camera fill. `before_recreation/neighborhood_filled.tscn` preserves the preview immediately before recreation placement. The placement script reconstructs that pass from its snapshot; review it before using it over subsequent hand edits.

## Do's and Don'ts

- Do use the current meter-like proportions and check original props' placement scales.
- Do retain the inherited palette alongside the documented architectural color variety.
- Do keep model instances independently editable and preserve the bedroom window corridor.
- Do preserve the three recreation groups, their sidewalk connections and open sports lanes when making local edits.
- Do preserve layered gardens, corner planting and screened road bends in street-camera compositions while keeping the checked road corridors clear.
- Do check pale-material separation and green ground when changing scene lighting.
- Don't assume background houses have navigable interiors.
- Don't treat route markers, separate mesh parts or lesson anchors as implemented gameplay or animation.
- Don't treat static recreation models or temporary ray checks as implemented sports physics, permanent collisions or complete traversal validation.
- Don't describe the finite scenery or sampled static-view checks as a complete fly-through.

## Expanded park and Soccer sign

The current park uses a 24 x 18 meter loop at the original center (-26.88798, 0, 63.20904), a 71.4% footprint increase over its first 18 x 14 meter version. Retain two-meter paths and normal equipment proportions. The enlarged play surface is 14 x 11 meters; slide tower, swings and sandbox occupy separated positions, with picnic and bench seating around the lawn edge.

Thirty individually placed cream picket fence panels with teal rails and capped posts enclose the perimeter. Preserve the three-meter entrance gaps to the east and north. The east entrance connects to the street sidewalk; the north opening has a short garden approach. The nearby west oak moved from X=-39 to X=-41 to clear the fence. Other non-park scene definitions are preserved. The soccer sign reads exactly “Soccer”.

WillowPark contains 55 editable instances; all recreation groups total 96, and the preview scene contains 1,676 model instances. The library has 97 GLBs including 21 recreation models (14,694 unique recreation triangles). The added large path loop and fence panel are in recreation_models; recreation_amenities.blend and build_recreation.py contain the current sign and source geometry. The earlier park path model remains reusable.

Eighteen temporary clearance rays checked the two entrances and four loop sides across 0.8-meter corridors at a height of 0.75 meters. Three final views confirmed the park layout, street appearance and sign text; these remain static environment checks. Preserve the current user lighting. Before-edit evidence is retained in before_park_expansion; expand_park_scene.py records this placement pass against that snapshot.
