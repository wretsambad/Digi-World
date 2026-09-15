---
name: Digi-World teenage bedroom
description: A detailed, lived-in teenage study and retreat in Digi-World's soft low-poly visual world.
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

This new bedroom extends Digi-World's established soft low-poly environment with ordinary furniture proportions and substantially more modeled personal detail. Warm timber, quiet painted walls and slate textiles create a comfortable teenage room. Schoolwork, music, sports and making are visible through useful objects and informal arrangements. The direction comes from `BRIEF.md`; this document records the completed build, rather than introducing a new visual direction.

The scope is `bedroom_assets/teen_bedroom.tscn` and its new asset library. The room is a separate scene, with local lighting and saved inspection cameras. It does not replace the previous bedroom, alter the neighborhood, or change project startup settings. The earlier neighborhood design remains the visual reference for the wider world. This is a native 3D environment specification; it does not define application interface controls.

**Key Characteristics:**

- Broad, recognizable furniture silhouettes with softened edges and matte materials.
- Layered detail at three scales: architecture and furniture, personal-object groups, and modeled construction details.
- Warm oak and cream balanced by sage, slate blue, rust and mustard.
- Four ordinary objects prepared as static lesson placeholders.
- Separately editable assets and a real west-window opening for later integration.

## Colors

The frontmatter records the authored material colors from `build_teen_bedroom.py` and its shared `bedroom_helpers.py`. They are sRGB source values; the helper converts them to linear values for Blender materials. Rendered appearance also depends on lighting and tonemapping. Do not use screenshot samples to replace these material values.

### Primary

- **Warm oak (`oak`, `oaklight`, `oakdark`):** floorboards, furniture bodies, worktops, bed construction and the guitar. Light and dark timber parts distinguish surfaces, grain, frames and supports without image textures.
- **Slate ink and denim (`ink`, `denim`):** bedding, chair and equipment, book covers, rug borders and small structural details. These darker surfaces keep the large pale room readable.

### Secondary

- **Muted sage (`sagewall`):** the east accent wall, storage details and selected book or device surfaces.
- **Soft rust (`rust`):** the fringed bed throw, phone case, backpack, skateboard and basketball.
- **Mustard (`mustard`):** accent cushion, lamp parts, notebook and small motifs or equipment details.

### Tertiary

- **Deep screen and mint display (`screen`, `screenlight`):** static monitor, phone and robot details. The shared display material has authored emission strength (0.45); it is not an animated screen or interactive state.
- **Cork and clay (`cork`, `claypot`):** the sharing board and plant pots.
- **Leaf, light leaf and soil (`leaf`, `lightleaf`, `soil`):** faceted houseplants. The three distant trees reuse the incumbent neighborhood oak model and its materials.

### Neutral

- **Warm plaster (`plaster`):** the main walls and ceiling.
- **Paper cream and woven gray (`paper`, `fabric`):** trim, mattress, bedding, curtains, rug, storage bins and small paper objects.
- **Rubber and muted metal (`rubber`, `metal`):** equipment and hardware details. Most generated materials use roughness (0.8); the shared metal material uses metallic (0.25).

**The Material Separation Rule.** Preserve the visible distinction between pale walls, trim, textiles and wood when changing lighting. The reviewed room keeps those materials legible across its four saved views.

## Typography

Text belongs to modeled objects: monitor content, posters and small object labels. The generator converts Blender text curves to mesh geometry with shallow extrusion. There is no authored interface font stack, typography token scale or live text field to document. Keep this limited fictional content as part of the scenery; the monitor and phone do not display real accounts, messages or personal data.

## Layout

The room interior is approximately (7.4 x 6.6 x 3.2 meters). Godot uses +Y up; west is -X, east is +X, north is -Z and the entry wall is +Z. Furniture follows meter-like dimensions: the study desk is (2.7 meters) wide, the bed frame is (1.65 x 2.3 meters), and the central rug is (3.6 x 2.8 meters). The central floor remains a broad visual breathing space between the furnished perimeter zones.

| Scene zone | Placement and built contents |
| --- | --- |
| `Architecture` | Separate walls, ceiling, skirting, outlets, switch and ajar door; 80 individual oak floorboards form a 20-by-4 arrangement. |
| `StudyCorner` | Northwest desk and chair, computer equipment, lamp, speakers, headphones, school supplies, drinkware, backpack, cabling and a wall shelf. |
| `SharingCorner` | North-wall cubby storage beneath the separate lesson board, with plant, notebook and storage bins. |
| `SleepCorner` | East-side bed with layered mattress, duvet, pillows and fringed throw; bedside table, wardrobe, storage, laundry, shoes and basketball. |
| `CreativeCorner` | Southwest cubby shelf, books, bins and plants, plus guitar, skateboard and the separate robot lesson group. |
| `PersonalDetails` | Central rug, posters, photos, clock, static decorative string lights and pendant shade. |
| `WindowView` | Three distant instances of the existing neighborhood oak model visible beyond the room. |

The west wall has an actual aperture (2.1 meters wide, from Y 0.95 to 2.6 meters). The frame and leaves are modeled as open forms. One sash is rotated (72 degrees), curtains flank the opening, and a native curtain rod spans above it. `Architecture/FutureWindowPassage` records a potential route at (-3.7, 1.85, 0.55). Nine temporary rays checked a narrow (0.2-meter-wide) corridor from outside into the room; this does not certify the entire opening or a complete camera route. The south wall has a modeled doorway (1 meter wide, 2.2 meters high) with an ajar door leaf.

Four saved cameras inspect the completed scene: `EntryCamera` is current by default (76-degree FOV); `StudyCamera` (68 degrees), `CreativeCamera` (72 degrees) and `BedsideCamera` (70 degrees) provide detail views. All use near/far distances (0.04 / 80 meters). Their transforms are authored by `finalize_bedroom.gd`. This is a fixed 3D composition, with no responsive-layout system or navigation controller.

## Elevation & Depth

Solid geometry, bevels, faceting, fabric folds, layered objects and directional shadows establish depth. Fine detail is modeled: floorboard grain and seams, quilt stitching, blanket fringe, curtain pleats and rings, keyboard keys, furniture pulls, guitar strings and basket openings. Embedded materials carry the painted appearance without external texture files.

The final room was reviewed using the project's Compatibility/OpenGL renderer. Local lighting combines cool ambient and window fill with a warm sun, ceiling fill and two low-energy practical lights. The values below match the saved scene and `assemble_teen_bedroom.py` after the review correction.

| Source | Godot color (R, G, B) | Energy | Relevant settings |
| --- | --- | --- | --- |
| Environment ambient | (0.76, 0.80, 0.83) | 0.32 | Ambient source `COLOR`; explicit ambient color is used. |
| `WindowSun` | (1.00, 0.91, 0.76) | 0.38 | Rotation (-28, -88, 0 degrees); shadows enabled. |
| `WindowFill` | (0.85, 0.94, 1.00) | 0.20 | Range 8 meters; shadows enabled. |
| `CeilingFill` | (1.00, 0.91, 0.77) | 0.16 | Range 7.5 meters; shadows enabled. |
| `DeskGlow` | (1.00, 0.79, 0.52) | 0.07 | Range 2.2 meters. |
| `BedsideGlow` | (1.00, 0.78, 0.49) | 0.06 | Range 2 meters. |

The environment retains optional SSAO settings for higher-capability renderers; Compatibility does not use them. Do not rely on SSAO to supply the room's basic depth. The final four rendered views received a ship disposition after one lighting correction, with no material regression visible in the confirmation views. This records sampled static-view acceptance, not a performance benchmark or complete fly-through validation.

## Shapes

The form language is low-poly and gently softened. Box-based furniture uses modest bevels; many common boxes use a nominal bevel (0.02 meters), constrained by each part's smallest dimension. Larger textile and cushion forms use broader rounding and explicit folds. Cylindrical hardware, faceted plant leaves and simplified sports or music equipment retain recognizable silhouettes. The teenager's belongings use small rotations, repeated books and layered pieces to imply use without obscuring the main objects.

Architectural openings remain real voids. Window leaves, basket sides and curtain folds use geometry that preserves depth and visible gaps. The robot uses compact body segments, a dark face, mint eyes and mustard details; it sits beside a separate drive, so both future lesson objects remain visually identifiable.

## Components

### Asset library and source organization

The library has 65 separate new GLBs and 50,140 unique model triangles before repeated placement. `placement.json` records 198 individually placed instances from that library. The saved scene additionally contains three reused distant tree instances and the native curtain-rod mesh. Counts describe the asset build, rather than target-device performance.

`teen_bedroom.blend` retains separately named model collections and their component meshes. The GLBs remain independent files under `../models/`; the scene groups keep object placement editable. `../catalog.json` and `catalog.csv` record dimensions, triangle counts and model notes. `../placement.json` records instance names, parents and transforms. `../README.md` contains opening, inspection and integration guidance.

Rebuild in the existing Digi-World project in this order:

1. Run `build_teen_bedroom.py` with Blender to generate the new models, catalog and Blender source. It uses `bedroom_helpers.py` for geometry and materials.
2. Run `assemble_teen_bedroom.py` with Python to generate this new room's instance layout, lesson groups, environment and lights.
3. Run `finalize_bedroom.gd` in Godot to save the four inspection cameras into the scene.

`check_capture_bedroom.gd` supports the verification/capture workflow. The `source/.gdignore` file keeps the source workspace out of normal Godot asset import. Regeneration replaces the new bedroom build, so review changes before running it over later hand edits. The asset package depends on the existing neighborhood oak GLB for its distant window view.

### Four static lesson groups

Each named root-level `Node3D` group has scene-owned children, a local `FocusAnchor` `Marker3D`, and lesson metadata with `status = "visual_placeholder"`.

| Group | Visible object and location | Lesson ID | Local `FocusAnchor` (X, Y, Z) |
| --- | --- | --- | --- |
| `Lesson_Computer` | Monitor on the northwest study desk. | `password_builder` | (0, 0.49, 0.08) |
| `Lesson_Phone` | Phone resting on the bedside notebook. | `message_detective` | (0, 0.13, 0) |
| `Lesson_SharingBoard` | Corkboard with fictional pinned photos and notes above north-wall storage. | `share_safely` | (0, 0, 0.14) |
| `Lesson_BackupRobot` | Robot, separate backup drive and cable on the southwest creative shelf. | `recover_project` | (0.1, 0.34, 0.12) |

Anchor coordinates are local to their groups; the robot group is rotated (180 degrees) in the room. Preserve the group transforms and use the anchors for later camera or lesson wiring.

**The Placeholder Rule.** These objects are static scenery. No click handlers, lesson UI, gameplay, ball physics, save data, animation controllers, navigation controller or permanent collision shapes are implemented. An open sash, named marker or modeled screen is preparation for later behavior, rather than evidence of that behavior.

### Verified build scope

All 65 new GLBs load in Godot 4.7.2; geometry structure and finite bounds were checked. Four lesson groups remain static and separately editable. SHA-256 comparisons confirmed that the 151 pre-existing scene/model/configuration files in the snapshot stayed byte-for-byte unchanged. Four final captures cover the full room, study, creative corner and bedside. These checks support the additive room deliverable; they do not imply automatic integration with an opening sequence.

## Do's and Don'ts

- Do preserve the separate bedroom scene and the existing project's authored scenes, models and startup settings.
- Do retain ordinary meter-like furniture proportions and the established soft low-poly world.
- Do build detail through furniture construction, layered textiles and recognizable personal objects.
- Do preserve distinct oak, plaster, fabric, sage and slate surfaces under the reviewed local lighting.
- Do keep the west-window corridor and entry opening clear when adjusting object placement.
- Do retain the four named static lesson groups and their local `FocusAnchor` markers.
- Do keep source collections, separate model files and scene instances editable.
- Don't introduce branded characters or real personal data into the fictional room contents.
- Don't turn object placeholders into lesson controls or gameplay as a visual-documentation change.
- Don't describe the room as automatically integrated into the existing scene or opening sequence.
- Don't treat unique triangle counts or sampled static renders as measured performance or a complete fly-through.
