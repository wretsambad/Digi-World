---
version: 1
slug: "bedroom-assets-lesson-focus-gd"
primary_target: "bedroom_assets/lesson_focus.gd"
related_targets: ["bedroom_assets/bedroom_tour.gd","bedroom_assets/bedroom_gameplay.gd","neighborhood_assets/preview/welcome_overlay.gd","neighborhood_assets/preview/tips_popup.gd","ui/sunset_ui.gd","ui/pause_menu.gd"]
---

# Bedroom and opening interface: Sunset Treehouse

Scope: the game's world-facing UI outside the computer lesson. That covers the object hover popup and inspect crosshair in first-person, the bedroom welcome card and guided tour, the seated Play button, the opening Play button and tip popup, and a new pause menu. Experience mode: the 3D room is the work, and the UI frames it.

Audience and job: children aged 8–12 exploring the bedroom in first person. They need to see what an object is, know they can inspect it, and start, continue or pause, without the UI covering what they are looking at.

Constraints: native Godot 4 Controls drawn in GDScript, no web. Reuse the Fredoka font. Never cover the screen centre during play. Preserve the existing flow, timings, keyboard focus, and the APIs the tests use.

## Direction contract

THESIS: The UI is the treehouse at golden hour. Warm plum boards glow with tangerine and butter light. It refuses the cream-paper-and-navy card that every kids' quiz ships.

OWN-WORLD: Deep plum panels (#3b2147) with soft warm drop shadows and 20px corners. Butter-yellow titles (#ffd166) and cream-white body text (#fff6ea). Tangerine buttons (#ff8a3d) sit on a darker lip (#c95a1c) that squishes flat on press, with dark plum labels. A butter focus ring. Fredoka at 700 for display and buttons, 600 for body.

STORY: The player aims at something and a ring blooms around the crosshair. A plum card slides in at the lower left, naming the object and what clicking does. Esc opens a pause panel from the left edge, so the room stays visible.

FIRST VIEWPORT: In first-person, the centre stays clear apart from a small crosshair. The hover card is docked at the lower left, about 34% of the width. The tour card sits low and centred, under the framed object. The welcome title is large in the upper third, with Next below it.

FORM: Sunset Treehouse, direction A of two, chosen by the user over Toybox Pop. The seed was not rolled; the user pinned a two-direction choice.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
