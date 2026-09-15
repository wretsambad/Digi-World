---
name: Digi-World teenage bedroom
description: A detailed teenage retreat connected to Digi-World's LearningHouse.
colors:
  plaster: "#E8E6D9"
  sagewall: "#97B2A5"
  oak: "#C79B6F"
  oaklight: "#DBB78D"
  oakdark: "#AF8058"
  ink: "#344E60"
  denim: "#59778A"
  rust: "#C77F62"
  mustard: "#D9B65F"
  paper: "#F3EBD9"
  fabric: "#D3D6C9"
  screen: "#254858"
  screenlight: "#79BCAD"
  cork: "#BD9265"
  rubber: "#3D454B"
  claypot: "#D2997E"
  metal: "#7B8295"
  leaf: "#4EAC76"
  lightleaf: "#8DDD9B"
  soil: "#755642"
---

# Design System: Digi-World Teenage Bedroom

## Overview

**Creative North Star: "A lived-in teenager's study and retreat"**

The teenage study and retreat now occupies the actual LearningHouse, preserving Digi-World’s soft low-poly style. teen_bedroom.tscn instances learning_house_detailed.tscn and nearby_neighborhood.tscn. The same detailed house appears in window_transition_preview.tscn, a neighborhood copy with its old house/interior replaced. The existing neighborhood_filled.tscn also uses this shared house at ExistingNeighborhood/LearningHouse. Its old bedroom furnishings and extra fill light were removed; other neighborhood nodes, other authored scenes and startup settings remain unchanged.

## Colors

The retained frontmatter records authored material colors. Warm oak, cream and sage support slate textiles, rust/mustard accents and mint display details. Thin plaster/sage interior linings and a new inner wooden sill complement the shared original shell.

## Typography

Fictional text remains modeled scenery. No lesson UI or live typography system is implemented.

## Layout

The fitted footprint is (6.52 x 7.52 meters) beneath the existing approximately (3.53-meter) ceiling. Interior origin is (15.400566, 3.471898, -28.989725). The real window center is (11.840566, 5.551898, -29.289725); its original (72-degree) sash is retained.

The destination bakes 544 nearby exterior instances, including 10 neighboring houses and 80 trees, with retained source placements and a cropped ground included in that total. It does not load the entire neighborhood.

## Elevation & Depth

Shared neighborhood_environment.tres and a copied Sun match the current neighborhood. Local room fills provide warmth: WindowFill energy (0.30), CeilingFill (0.68; range 12; shadows disabled), desk (0.07), bedside (0.06). Geometry, softened edges, textile folds and directional shadows retain material separation.

Eight static views/handoff frames received SHIP with zero material fixes. A small pendant-shadow difference remains visible; the transition is not pixel-identical. Continuous performance is not certified.

## Shapes

Keep recognizable low-poly furniture, faceted plants and layered personal details. The original 65-GLB library and Blender source remain unchanged; some original architectural models are unused in the connected room.

## Components

The four Lesson_ groups—Computer, Phone, SharingBoard and BackupRobot—now sit beneath LearningHouseDetailed/BedroomInterior. Each retains a static FocusAnchor. The robot and backup drive remain separate objects; lesson interactions remain unimplemented.

The preview animates an eight-second street turn/window flight, then calls change_scene_to_packed when the camera is 1.5 meters inside. It transfers world transform, FOV (76), near/far (0.04/180) and keep-aspect. The bedroom holds the first drawn pose before a four-second settle. Runtime animation affects cameras only. The actual handoff was tested and the full source scene unloaded; 1,629 temporary camera-corridor rays were clear.

Logic is in source/connect_bedroom.gd, window_transition.gd and bedroom_arrival.gd. CONNECTION_BRIEF.md records the continuity direction. Earlier model generators remain asset sources; connected-scene reconstruction belongs to the connection workflow.

## Do's and Don'ts

- Do preserve shared house geometry, neighborhood lighting and source exterior placements.
- Do keep the window corridor clear and lesson anchors static.
- Don’t treat camera animation as lesson functionality.
- Don’t promise pixel-identical lighting or certified continuous performance.

