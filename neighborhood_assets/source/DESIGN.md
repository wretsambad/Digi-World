---
name: Digi-World expanded neighborhood
description: A colorful low-poly neighborhood with full-size buildings and a furnished learning-house bedroom.
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
---

# Design System: Expanded Neighborhood

## Overview

The neighborhood extends the original mint-roof, cream-wall visual identity into a colorful, low-poly residential environment for children learning data security. Buildings now have ordinary architectural proportions, varied exteriors and generous tree cover. The featured LearningHouse includes a real furnished upper-floor bedroom. This document describes the environment assets and current authored scenes; it does not govern interface design.

## Colors

Mint, cream and coral retain the inherited identity. Teal, roof blue, clay, sage, lavender, butter and peach broaden the house and furnishing palette while keeping its soft painted character. Leaf and light-leaf separate faceted foliage masses; grass provides a quieter ground field. Slate anchors dark structural details. Maintain separation between pale walls, trim, paving and furnishings under scene lighting. GLBs carry embedded materials and do not require external textures.

## Layout

The original ground area covers approximately 210 x 240 meters and now extends into screened road bends. Each main scene contains 31 houses, 350 large trees and 1,583 individually editable model instances; the reusable dressing scene contains 1,540. Approximately one Godot unit represents one meter. Six original-derived house models are enlarged eight times, with widths of approximately 8-14 meters. The earlier 32 props retain their original compact dimensions and require suitable scene scaling; the new models generally import at scale 1.

The main road is 7.2 meters wide; sidewalks are 1.8 meters wide with approximately 15-centimeter curb heights. Front gardens, layered tree belts and distant low hills fill street and overview compositions. Trees use broad forms approximately 9-12 meters tall before instance variation.

Six additional peach/cedar houses, front paths, layered gardens and corner vegetation fill gaps near the origin and through street turns. East, west and south road ends continue into tree-screened curves, with partial upper-facade and roof silhouettes suggesting more homes beyond. The scenery remains finite; preserve the screened continuation illusion from street height. The fill pass added 568 instances to each main scene and removed 16 trees and nine distant mounds to clear the new roads. A temporary geometry check found all 936 rays clear along the new curve centerlines, across a 0.36-meter camera corridor at 2.4 meters above ground.

LearningHouse has a 12 x 10 meter building footprint, with exterior details extending beyond it. It is centered at world (17, 0, -27). Its upper bedroom measures approximately 7.4 x 6.6 meters, with the floor at elevation 3.51 meters. Keep the real front window passage clear: the separate sash is open outward 72 degrees, and curtains flank the opening. Nine parallel rays validated a 0.36-meter camera corridor through the house, sash and curtains.

Both `../../houses.tscn` and `../preview/neighborhood_filled.tscn` contain the expanded layout. Each has a Node3D root and a local `ExistingNeighborhood` Node3D, with the 1,583 model instances directly beneath that container and owned by the scene. The two scenes are independently editable copies; subsequent edits do not synchronize. All surviving original node definitions were preserved exactly against `before_sightline_fill/`, including the user's LearningHouse, furniture and lighting edits. Preserve Godot +Y up and each model's documented pivot. Curtains and sash use installation pivots rather than ground pivots.

## Elevation & Depth

Solid geometry, faceted surfaces and scene shadows provide depth. Retain the user's current authored lighting; earlier recorded sun, ambient and fog values no longer describe the scene. The latest seven street-level captures use the project's existing Forward+ lighting and received a SHIP disposition with no material fixes from the independent finish review. That acceptance covers the sampled static views: origin, both junction directions, both outer bends, south end and farther around the east bend. It does not establish a complete fly-through or target-device performance.

## Shapes

Preserve readable low-poly silhouettes and simplified painted surfaces. House variation comes from roof and wall colors, porch steps, columns, canopies, planters, awnings, chimneys and pergolas. Broad overlapping foliage masses and recognizable compact cars support the larger architectural scale. Furniture should remain recognizable at bedroom camera distance.

## Components

The pack contains 76 GLBs: 32 original props in `../models/`, 34 expansion models in `../expanded_models/` and ten continuation models in `../sightline_models/`. The latest ten comprise road, sidewalk and curb sets for three curves, plus a distant roofline model; all ten and all three updated scenes were loaded successfully in Godot 4.7.2. The 34 expansion models alone total 65,734 triangles. Repeated placement increases rendered geometry, and target-device performance has not been benchmarked.

`expanded_neighborhood.blend` retains separately editable parts in named model collections; `sightline_continuations.blend` retains the new continuation geometry. GLB exports merge static parts into one mesh with material surfaces. The bedroom contains separately placed bed, desk, chair, computer, phone, bookshelf, rug, lamp, artwork, curtains and sash models. Only LearningHouse has a furnished, enterable interior; the six other house variants are background exteriors.

In `../../houses.tscn`, FlyThroughMarkers records the intended camera route and saved cameras remain available. The independently edited `../preview/neighborhood_filled.tscn` has no saved cameras or route markers. The computer and phone have lesson anchors. These are preparation assets: camera animation, lesson logic, navigation and permanent collision shapes are not implemented. `../sightline_routes.json` records sampled centerlines for future animation along the new curves.

See `../README.md`, `../expanded_catalog.json`, `../expanded_scene_summary.json`, `../sightline_catalog.json`, `../sightline_placement.json` and `../sightline_changes.json` for usage, dimensions and layout facts. Pre-expansion scenes remain in `before_expansion/`; `before_sightline_fill/` preserves the user's scenes immediately before the street-camera fill.

## Do's and Don'ts

- Do use the current meter-like proportions and check original props' placement scales.
- Do retain the inherited palette alongside the documented architectural color variety.
- Do keep model instances independently editable and preserve the bedroom window corridor.
- Do preserve layered gardens, corner planting and screened road bends in street-camera compositions while keeping the checked road corridors clear.
- Do check pale-material separation and green ground when changing scene lighting.
- Don't assume background houses have navigable interiors.
- Don't treat route markers, separate mesh parts or lesson anchors as implemented gameplay or animation.
- Don't describe the finite scenery or sampled static-view checks as a complete fly-through.
