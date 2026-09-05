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

The map covers approximately 210 x 240 meters, with 25 houses, 215 large trees and 1,040 individually editable model instances. Approximately one Godot unit represents one meter. Six original-derived house models are enlarged eight times, with widths of approximately 8-14 meters. The earlier 32 props retain their original compact dimensions and require suitable scene scaling; the new models generally import at scale 1.

The main road is 7.2 meters wide; sidewalks are 1.8 meters wide with approximately 15-centimeter curb heights. Front gardens, layered tree belts and distant low hills fill street and overview compositions. Trees use broad forms approximately 9-12 meters tall before instance variation.

LearningHouse has a 12 x 10 meter building footprint, with exterior details extending beyond it. It is centered at world (17, 0, -27). Its upper bedroom measures approximately 7.4 x 6.6 meters, with the floor at elevation 3.51 meters. Keep the real front window passage clear: the separate sash is open outward 72 degrees, and curtains flank the opening. Nine parallel rays validated a 0.36-meter camera corridor through the house, sash and curtains.

Both `../../houses.tscn` and `../preview/neighborhood_filled.tscn` contain the expanded layout. Each has a Node3D root and a local `ExistingNeighborhood` Node3D, with the 1,040 model instances directly beneath that container and owned by the scene. The two scenes are independently editable copies; subsequent edits do not synchronize. Preserve Godot +Y up and each model's documented pivot. Curtains and sash use installation pivots rather than ground pivots.

## Elevation & Depth

Solid geometry, faceted surfaces and scene shadows provide depth. The accepted street, overview, learning-house exterior and bedroom views use Godot Forward+ on D3D12, with sun energy 0.55, ambient energy 0.5 and fog density 0.0012. These describe the current presentation rather than universal lighting requirements. All four final views received a SHIP review disposition.

## Shapes

Preserve readable low-poly silhouettes and simplified painted surfaces. House variation comes from roof and wall colors, porch steps, columns, canopies, planters, awnings, chimneys and pergolas. Broad overlapping foliage masses and recognizable compact cars support the larger architectural scale. Furniture should remain recognizable at bedroom camera distance.

## Components

The pack contains 34 new GLBs in `../expanded_models/`, alongside the original 32 in `../models/`. New unique model geometry totals 65,734 triangles; repeated placement increases rendered geometry, and target-device performance has not been benchmarked.

`expanded_neighborhood.blend` retains separately editable parts in named model collections. GLB exports merge static parts into one mesh with material surfaces. The bedroom contains separately placed bed, desk, chair, computer, phone, bookshelf, rug, lamp, artwork, curtains and sash models. Only LearningHouse has a furnished, enterable interior; the six other house variants are background exteriors.

FlyThroughMarkers records the intended camera route, and the computer and phone have lesson anchors. These are preparation assets: animation, lesson logic, navigation and permanent collision shapes are not implemented. See `../README.md`, `../expanded_catalog.json` and `../expanded_scene_summary.json` for usage, dimensions and layout facts. Pre-expansion scenes are retained in `before_expansion/`.

## Do's and Don'ts

- Do use the current meter-like proportions and check original props' placement scales.
- Do retain the inherited palette alongside the documented architectural color variety.
- Do keep model instances independently editable and preserve the bedroom window corridor.
- Do check pale-material separation and green ground when changing scene lighting.
- Don't assume background houses have navigable interiors.
- Don't treat route markers, separate mesh parts or lesson anchors as implemented gameplay or animation.
