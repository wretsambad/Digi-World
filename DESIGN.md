---
name: Protect Your Base
description: A personal treehouse workshop in the Digi World neighborhood.
colors:
  action-orange: "#ff7f42"
  cream-paper: "#fff5df"
  navy-ink: "#18394a"
  hover-peach: "#ffddb2"
  pressed-mint: "#b7dfc4"
  focus-gold: "#e3ae24"
  progress-teal: "#368b77"
  progress-track: "#dfd7bd"
  world-mint: "#b8d9c9"
  lawn-green: "#83b999"
  timber-brown: "#99704c"
  roof-teal: "#315f60"
  plastic-gold: "#f0b365"
  wood-brown: "#a77549"
  metal-blue: "#94b7c0"
  choice-teal: "#409b89"
  choice-apricot: "#ef9d59"
  choice-sky: "#76a8ce"
  choice-lilac: "#b68cc7"
  choice-rose: "#df7990"
  choice-sunshine: "#e2c468"
  choice-leaf: "#92b96b"
  choice-sand: "#d9c8ac"
typography:
  display:
    fontFamily: Fredoka
    fontSize: "36px"
    fontWeight: 550
  headline:
    fontFamily: Fredoka
    fontSize: "31px"
    fontWeight: 550
  dialogue:
    fontFamily: Fredoka
    fontSize: "23px"
    fontWeight: 550
  body:
    fontFamily: Fredoka
    fontSize: "22px"
    fontWeight: 550
  label:
    fontFamily: Fredoka
    fontSize: "17px"
    fontWeight: 550
rounded:
  button: "14px"
  card: "22px"
  meter: "6px"
spacing:
  compact: "10px"
  stack: "12px"
  button-horizontal: "16px"
  card-horizontal: "22px"
components:
  button-primary:
    backgroundColor: "{colors.action-orange}"
    textColor: "{colors.navy-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.button}"
    padding: "10px 16px"
    height: "48px"
  button-secondary:
    backgroundColor: "{colors.cream-paper}"
    textColor: "{colors.navy-ink}"
    rounded: "{rounded.button}"
    padding: "10px 16px"
    height: "48px"
  button-hover:
    backgroundColor: "{colors.hover-peach}"
  button-pressed:
    backgroundColor: "{colors.pressed-mint}"
  card:
    backgroundColor: "{colors.cream-paper}"
    textColor: "{colors.navy-ink}"
    rounded: "{rounded.card}"
    padding: "16px 22px"
---

# Design System: Protect Your Base

## Overview

**Creative North Star: "My Treehouse Workshop"**

This document covers only the replacement **Protect Your Base** lesson: its native Godot desktop interface, treehouse, Pip integration, Glitch, and lesson feedback. The player's own hideout is the teaching surface. A friendly faceted neighborhood provides the setting; chunky Fredoka lettering, cream paper panels, navy outlines, and orange actions make the workshop legible and inviting.

Visual authority comes from the supplied brief and the preserved opening's authored assets. This lesson is a new implementation. The preserved neighborhood opening, bedroom arrival, and typing animation remain outside this document's scope. Their existing metadata, including root `.impeccable/design.json`, is retained separately. This lesson's extensions live in `.impeccable/protect-your-base/design.json`.

**Key Characteristics:**

- A living low-poly treehouse with immediately visible personal choices.
- Flat cream panels with confident navy outlines and rounded controls.
- A friendly sculpted Pip whose fur colour belongs to the player.
- Physical plastic, wood, and metal upgrades that mirror learning progress.
- Repairable visual jokes and a gentle-motion setting.

### Asset provenance

The authoritative implementation is `ui/LessonUI.gd`, `scripts/MonitorGame.gd`, `scripts/Treehouse.gd`, `scripts/Pip.gd`, `scripts/Glitch.gd`, and `autoload/PlayerProfile.gd`.

- **Neighborhood models:** existing project GLBs: `neighborhood_assets/expanded_models/house_{peach,willow,buttercup,lavender,cedar}.glb`, `tree_oak_large.glb`, and `neighborhood_assets/models/shrub_round.glb`. Local Blender sources and model catalogs are retained under `neighborhood_assets/source/`; these are reused authored project assets, not newly sourced stock.
- **Pip:** existing `protect_base_assets/pip.tscn`, with local sculpt/build sources under `protect_base_assets/source/` and animation in `protect_base_assets/pip_animation.gd`. The lesson reuses the sculpt and applies `scripts/pip_color.gdshader` to warm vertex-painted fur, preserving cream markings and clothing.
- **Font:** existing `neighborhood_assets/preview/fonts/Fredoka.ttf`; bundled `OFL.txt` credits the Fredoka Project Authors and carries SIL Open Font License 1.1.
- **New lesson geometry:** authored in GDScript using `scripts/Geometry.gd`: the treehouse workshop, defenses, socks, Glitch, lawn/path, and celebratory cubes are Godot meshes. The oak and background houses remain imported models.
- **Runtime raster graphics:** colour swatches are generated as solid 22 × 22 images; flag patterns are generated as 128 × 72 images by `Treehouse.gd`. No ImageGen raster is a shipping lesson asset. Review PNGs under `.impeccable/review/` are Godot capture evidence, not game textures.

## Colors

Warm cream and orange sit against navy ink; subdued green and teal scenery lets the player's paint choices and new defenses remain visible. Frontmatter values are the code's actual colours, before lighting and tonemapping.

### Primary

- **Action Orange:** the current main progression button at rest.

### Secondary

- **Progress Teal:** completed teaching-rule meter fill.
- **Focus Gold:** the distinct keyboard focus outline.
- **Hover Peach / Pressed Mint:** button hover and pressed or selected states.
- **Choice Teal, Apricot, Sky, Lilac, Rose, Sunshine, Leaf, and Sand:** the same eight named choices for house paint, flag colour, and Pip's fur colour. Selection changes the actual 3D subject immediately.
- **Plastic Gold / Wood Brown / Metal Blue:** successive defense materials, distinguished by visible construction and lesson labels as well as colour.

### Neutral

- **Cream Paper / Navy Ink:** readable panels, text, and structural borders.
- **Progress Track:** the muted empty meter background.
- **World Mint / Lawn Green:** surrounding environment and ground.
- **Timber Brown / Roof Teal:** unpainted support structure and roof.

**The Personal Paint Rule.** Pip's colour changes fur. Preserve his cream markings and clothes; house paint and flag colour remain separate choices.

## Typography

**Display Font:** Fredoka. **Body Font:** Fredoka. The bundled font is loaded directly; no web font or CSS fallback stack is used by the game.

The UI uses a `FontVariation` at weight **550**. Godot receives the numeric OpenType axis tag from `TextServerManager.get_primary_interface().name_to_tag("wght")`, then stores that tag in `variation_opentype`. This is the implemented chunky rounded face, not a synthetic bold setting. Default line spacing remains Godot's font metrics; there is no authored line-height scale.

### Hierarchy

- **Display:** the lesson title.
- **Headline:** the workshop's current stage title.
- **Dialogue:** Pip's speech beneath the world.
- **Body:** default controls and general text.
- **Label:** progress and sound/motion controls. The safety reminder uses 16 logical pixels; Pip's speaker label uses 18; subtitles and build labels use 19; practice examples use 21; customization heading uses 24; finale rules use 26.

Sizes in frontmatter are logical pixels at the 1280 × 720 design canvas. `Label3D` signage uses the base Fredoka font directly, independent of the 550-weight UI variation.

## Layout

The native desktop canvas is authored at **1280 × 720**. `LessonUI.resize()` uniformly scales by `min(viewport width / 1280, viewport height / 720)` and centers the result. There are no mobile breakpoints or alternate stacked layouts.

The title card sits at (24, 16), sized 768 × 94. The workshop panel is at (820, 24), sized 428 × 580. Pip's speech card is at (32, 568), sized 758 × 128. Sound and motion controls start at (820, 618), with the safety reminder below at (820, 678). The composition leaves the broad left area for the treehouse and character.

The workshop uses a vertical stack with 12-pixel gaps; its content uses 10-pixel gaps. Customization presents eight choices in two columns with 10-pixel horizontal and vertical gaps, one subject per page. Card padding is 22 horizontally and 16 vertically. Buttons have a 48-pixel minimum height, not a fixed height; content can expand them.

The world uses an orthographic camera at (8, 7.3, 15), aimed at (0.3, 2.2, 0), with size 12.2. The treehouse is positioned at (-2, 0, 0); Pip stands at (-4, 0, 2.5) at 1.55 scale. These establish this lesson's composition, not requirements for unrelated game screens.

## Elevation & Depth

UI panels and buttons have no drop shadows. Cream fill and navy borders separate them from the scene. Depth comes from the 3D workshop, overlapping foliage, timber construction, and directional world shadows. The scene uses AGX tonemapping, mint ambient light at energy 0.5, and a warm directional sun at energy 0.55 with shadows enabled. Procedural materials are matte with roughness 0.85; Pip's recolouring shader uses 0.95 and disables specular.

**The World Depth Rule.** Let the 3D scene carry depth; keep the lesson controls flat and clearly outlined.

## Shapes

Cards have broad rounded corners; buttons use a smaller radius, and the thin progress meter uses the smallest radius. Cards and resting buttons have 2-pixel navy borders; keyboard focus adds a 4-pixel gold outline. The treehouse is assembled from simple box planks and tapered seven-sided timber poles. The upgrade shield is six-sided. These faceted shapes belong beside the preserved neighborhood's low-poly models.

## Components

### Buttons

Tactile, readable, and consistently outlined. Main actions use orange at rest; secondary actions use cream. All buttons share peach hover and mint pressed styles. Focus is a transparent gold-bordered overlay. The default disabled style remains cream with navy text; during feedback, option buttons are disabled in behavior without a distinct faded visual. Toggle choices retain the pressed treatment when selected.

### Cards / Containers

Cream paper with navy edges and no shadows. The same card helper forms the title, workshop, and Pip speech containers; exact radii and padding live in frontmatter.

### Personalization Choices

Eight text-labelled toggle buttons per page. Paint and fur choices include generated colour swatches; flag design choices use text labels: Sun, Moon, Star, Diamond, Stripes, Cross, Mountain, Dot. The flag pattern is visible on the 3D cloth. Selected choices persist locally. The pages are treehouse paint, rooftop flag design, flag colour, and Pip's colour.

### Teaching Progress

A 12-pixel-high, three-unit meter accompanies the current pretend example. It counts completed teaching rules, with no percentage label. The workshop shows four text choices during each build, with number shortcuts 1–4; native focus supports keyboard activation. Main progression actions label Enter explicitly.

### Pip Speech and Physical Feedback

The speech card has a small uppercase PIP label and a larger wrapping dialogue line. The preserved text writer reveals dialogue at 42 characters per second, or 60 with gentle motion. Pip's authored Idle, Startled, and Celebrate animations provide reactions; gentle motion selects Idle for reactions.

Defenses arrive with a 0.5-second back-eased position tween and scale-up. Mistakes show socks on the flag, lime paint, or a flattened gate; accepting a correct choice restores personal colours and rebuilds the defense. Full motion includes flag sway, Glitch movement, and a burst of 22 small golden cubes lasting one second. Gentle motion skips upgrade tweening and particles, stops flag and Glitch idle motion, and removes the Glitch immediately at the finale. The speech reveal remains animated at its faster rate.

### Settings

Text buttons report Sound: on/off and Motion: full/gentle. They save locally and remain visible below the workshop. This lesson has no password-entry text field: all examples are supplied choices.

## Do's and Don'ts

### Do:

- **Do** preserve the brief's cream, navy, orange, chunky Fredoka, and faceted neighborhood character.
- **Do** use the real treehouse and Pip to display personal choices immediately.
- **Do** retain text labels alongside colour and material changes.
- **Do** keep keyboard focus visible and respect the saved motion setting.
- **Do** reuse the authored Pip sculpt and neighborhood models with their local source provenance.

### Don't:

- **Don't** treat Pip's colour as a clothing or accessory choice; it recolours fur.
- **Don't** substitute web or iOS component conventions for the native Godot implementation.
- **Don't** present the teaching meter as a real password-strength evaluator.
- **Don't** apply this lesson's layout or metadata to the preserved opening and bedroom.
