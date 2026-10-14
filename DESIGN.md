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
  sunset-plum: "#3b2147"
  sunset-plum-deep: "#241330"
  sunset-plum-soft: "#553163"
  sunset-butter: "#ffd166"
  sunset-cream: "#fff6ea"
  sunset-cream-muted: "#e9d3e6"
  sunset-tangerine: "#ff8a3d"
  sunset-tangerine-hover: "#ffa15c"
  sunset-tangerine-lip: "#c95a1c"
  sunset-shadow: "rgba(36, 10, 41, 0.42)"
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
  sunset-wordmark:
    fontFamily: Fredoka
    fontSize: "68px"
    fontWeight: 700
  sunset-hero:
    fontFamily: Fredoka
    fontSize: "60px"
    fontWeight: 700
  sunset-headline:
    fontFamily: Fredoka
    fontSize: "52px"
    fontWeight: 700
  sunset-title:
    fontFamily: Fredoka
    fontSize: "32px"
    fontWeight: 700
  sunset-button:
    fontFamily: Fredoka
    fontSize: "26px"
    fontWeight: 700
  sunset-body:
    fontFamily: Fredoka
    fontSize: "21px"
    fontWeight: 600
  sunset-chip:
    fontFamily: Fredoka
    fontSize: "18px"
    fontWeight: 700
  sunset-caption:
    fontFamily: Fredoka
    fontSize: "17px"
    fontWeight: 600
rounded:
  button: "14px"
  card: "22px"
  meter: "6px"
  sunset-panel: "20px"
  sunset-button: "16px"
  sunset-focus-ring: "21px"
  sunset-chip: "12px"
  sunset-pill: "23px"
  sunset-tip-tail: "4px"
spacing:
  compact: "10px"
  stack: "12px"
  button-horizontal: "16px"
  card-horizontal: "22px"
  sunset-stack-tight: "8px"
  sunset-stack: "12px"
  sunset-panel-x: "24px"
  sunset-button-x: "30px"
  sunset-button-y: "12px"
  sunset-pause-inset: "34px"
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
  sunset-button-primary:
    backgroundColor: "{colors.sunset-tangerine}"
    textColor: "{colors.sunset-plum-deep}"
    typography: "{typography.sunset-button}"
    rounded: "{rounded.sunset-button}"
    padding: "12px 30px"
  sunset-button-primary-hover:
    backgroundColor: "{colors.sunset-tangerine-hover}"
  sunset-button-secondary:
    backgroundColor: "{colors.sunset-plum-soft}"
    textColor: "{colors.sunset-cream}"
    typography: "{typography.sunset-button}"
    rounded: "{rounded.sunset-button}"
    padding: "12px 30px"
  sunset-panel:
    backgroundColor: "{colors.sunset-plum}"
    textColor: "{colors.sunset-cream}"
    rounded: "{rounded.sunset-panel}"
    padding: "18px 24px 20px"
  sunset-tour-card:
    backgroundColor: "{colors.sunset-plum}"
    textColor: "{colors.sunset-cream}"
    rounded: "{rounded.sunset-panel}"
    padding: "22px 30px"
  sunset-pause-panel:
    backgroundColor: "{colors.sunset-plum}"
    textColor: "{colors.sunset-cream}"
    rounded: "{rounded.sunset-panel}"
    padding: "{spacing.sunset-pause-inset}"
  sunset-tip-bubble:
    backgroundColor: "{colors.sunset-plum}"
    textColor: "{colors.sunset-cream}"
    typography: "{typography.sunset-body}"
    padding: "12px 18px"
    height: "104px"
  sunset-chip-play:
    backgroundColor: "{colors.sunset-tangerine}"
    textColor: "{colors.sunset-plum-deep}"
    typography: "{typography.sunset-chip}"
    rounded: "{rounded.sunset-chip}"
    padding: "5px 14px 5px 12px"
  sunset-chip-soon:
    backgroundColor: "{colors.sunset-plum-soft}"
    textColor: "{colors.sunset-cream-muted}"
    typography: "{typography.sunset-chip}"
    rounded: "{rounded.sunset-chip}"
    padding: "5px 14px 5px 12px"
  sunset-progress-pill:
    backgroundColor: "{colors.sunset-plum}"
    rounded: "{rounded.sunset-pill}"
    width: "300px"
    height: "46px"
---

# Design System: Protect Your Base

## Overview

**Creative North Star: "My Treehouse Workshop"**

The canonical sections below, Overview through Do's and Don'ts, cover only the replacement **Protect Your Base** lesson: its native Godot desktop interface, treehouse, Pip integration, Glitch, and lesson feedback. The player's own hideout is the teaching surface. A friendly faceted neighborhood provides the setting; chunky Fredoka lettering, cream paper panels, navy outlines, and orange actions make the workshop legible and inviting.

Visual authority comes from the supplied brief and the preserved opening's authored assets. This lesson is a new implementation. The game's 2D interface follows **Sunset Treehouse**, documented in its own section at the end of this file with `sunset-` tokens: the opening start screen, the bedroom welcome and guided tour, the seated Play button, the first-person inspect popup and crosshair, the Esc pause menu, and, since the lesson restyle, every screen inside the computer lesson (`ui/LessonUI.gd`: title card, Pip dialogue and captions, password bar and rule chips, the four option buttons, the customization panel and the Great Job card) plus the bedroom Continue button. The cream-paper, navy-ink and orange descriptions of lesson panels and buttons in the canonical sections below are superseded by Sunset Treehouse; the lesson's 3D world, Pip, Glitch, defenses and choice palettes described there still apply. The neighborhood's 3D models, the opening's globe-and-orbit logo, and the shared typing animation belong to neither system. Sunset Treehouse extensions, together with the earlier opening metadata, live in root `.impeccable/design.json`. This lesson's extensions live in `.impeccable/protect-your-base/design.json`.

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
- **Don't** apply this lesson's layout, cream-and-navy tokens, or metadata to the opening, bedroom, inspect popup, or pause menu; those surfaces use Sunset Treehouse. Equally, don't carry `sunset-` tokens into the computer lesson.

## Sunset Treehouse: Opening, Bedroom and Pause

**Creative North Star: "The Treehouse at Golden Hour"**

Sunset Treehouse is the interface world for everything around the computer lesson: the opening start screen (wordmark, slogan, Play, and safety-tip bubble), the bedroom welcome and four-stop guided tour, the seated Play button, the first-person inspect popup and crosshair, and the Esc pause menu. Warm plum boards carry butter titles and cream copy; tangerine buttons sit on a darker lip that squishes flat when pressed. The 3D room is the subject, so the interface docks to the edges and keeps the centre of the screen clear during play.

Every element is a native Godot `Control` styled in GDScript through the shared kit `ui/sunset_ui.gd` (`SunsetUI`). No raster assets were created for this system: boards and buttons are `StyleBoxFlat`, and the chevron, mouse icon, crosshair, eye badge, leader line, and progress dots are drawn with Godot draw calls. Sizes are logical pixels at the 1280 × 720 canvas; the opening scales by `clamp(min(width / 1280, height / 720), 0.62, 1.6)` and the inspect popup by the same ratio clamped to 0.62–1.5.

**Key Characteristics:**

- Deep plum boards with a plum-deep edge and a warm plum-tinted drop shadow.
- Butter titles, cream body copy, and soft lilac muted copy.
- Tangerine primary buttons on a darker lip; plum secondary buttons; a butter focus ring.
- A drawn crosshair that blooms tangerine on lesson objects, with a docked popup and dashed leader line.
- Springy, short motion: slide-ins from the left, a card pop from the bottom edge, a squash on press.

### Colors

The palette is a dusk gradient: plum for surfaces, butter and tangerine for light, cream for reading. Frontmatter `sunset-` values are normative; these are the roles.

- **Tangerine** (`sunset-tangerine`): the forward action. Primary button face (Play, Next, Resume), the "Click to play" chip, and completed progress dots. The crosshair ring blooms to it.
- **Tangerine Glow** (`sunset-tangerine-hover`): primary button hover.
- **Ember Lip** (`sunset-tangerine-lip`): the thick bottom lip under primary buttons.
- **Butter** (`sunset-butter`): titles, the wordmark, corner mark, and welcome hero; the focus ring; crosshair ticks; the eye badge rim; the leader line; the current progress dot; the "Tip:" prefix.
- **Plum** (`sunset-plum`): every board, from popup, tour card, and pause panel to the progress pill, tip bubble, and eye badge disc.
- **Plum Deep** (`sunset-plum-deep`): board borders, secondary button lips, ink on tangerine, outlines on text over the 3D world, and the resting crosshair ring. At 55% opacity it is the welcome shade; at 38% it is the pause dim.
- **Plum Soft** (`sunset-plum-soft`): secondary button face (tour Pause, Sound, Quit game) and the "Coming soon" chip.
- **Cream** (`sunset-cream`): body copy, slogan, secondary button labels, the crosshair dot, and the eye.
- **Cream Muted** (`sunset-cream-muted`): muted copy (pause note, tour step counter), "Coming soon" text, and upcoming progress dots.
- **Warm Shadow** (`sunset-shadow`): every drop shadow and the hero and wordmark text shadows.

State colours are computed in code, not stored as tokens: primary pressed is Tangerine darkened 6%; secondary hover is Plum Soft lightened 12%, and pressed is darkened 6%; disabled faces darken 25% with the label at 45% opacity.

**The Tangerine Means Go Rule.** Tangerine marks only the action that moves the player forward, and progress already made. Pausing, sound, and quitting stay plum.

**The Warm Board Rule.** Copy sits on a plum board, or carries a plum-deep outline when it floats over the 3D world (wordmark, slogan, welcome hero and intro).

### Typography

**Font:** Fredoka, bundled at `neighborhood_assets/preview/fonts/Fredoka.ttf` under the SIL Open Font License, loaded directly with no fallback stack. `SunsetUI.font()` builds and caches a `FontVariation` on the `wght` axis at two weights: **700** for titles, buttons, the wordmark, and the chip; **600** for body, muted copy, the slogan, and tips. Line spacing is Godot's default, except the two-line welcome hero at −10.

**Character:** round, chunky, and friendly; heavy enough to read over a busy room at a glance.

- **Wordmark** (700, 68 × scale): "DIGI WORLD" on the opening; butter, plum-deep outline 15 × scale, warm shadow 10 below. The corner mark during the flight uses 27 × scale with a 6 outline.
- **Hero** (700, 60): the bedroom "Welcome to / Digi-World" title; butter with a plum-deep outline of max(6, size / 5) and a warm shadow 6 below.
- **Headline** (700, 52): "Paused".
- **Title** (700): tour card title at 32, inspect popup heading at 28.
- **Button** (700): menu buttons at 26, Play at 32 (the opening clamps it to 22–42 by scale), tour buttons at 24, tour Pause at 18.
- **Body** (600): welcome intro 24, slogan 23, tour body 22, tip and pause note 21, popup description 20.
- **Chip / Caption:** the action chip at 18 / 700; the tour chapter label at 18 / 600; the step counter at 17 / 600 in Cream Muted.

### Shapes

Soft, well-rounded boards. Panels use the 20 px radius with a 2 px plum-deep border and anti-aliased corners. Buttons use 16 px with a 7 px bottom lip that flattens to 2 px when pressed. The focus ring is a 4 px butter outline, 5 px outside the button, at 21 px radius. The action chip uses 12 px; the progress pill's 23 px radius on a 46 px height makes a full capsule. The tip bubble is a standard board with one tight 4 px bottom-left corner pointing back at the street. Drawn glyphs are line-based: a 4 px three-point chevron in an 18 × 22 box, and a mouse outline with a 2 px stroke and its left button lit tangerine.

### Elevation & Depth

Lifted. Boards and buttons float above the 3D world on warm, plum-tinted shadows; the world behind dims rather than blurs when a modal moment needs focus.

- **Board** (`StyleBoxFlat` shadow size 18, offset 0, 9): popup, tour card, pause panel, tip bubble.
- **Button** (size 12, offset 0, 7; pressed size 4, offset 0, 2): the press visibly sinks the button.
- **Progress pill** (size 12, offset 0, 6).
- **Text over the world:** hero shadow 6 below; wordmark and corner mark 10 below.
- **Crosshair:** a soft halo at 25% shadow strength, 1.5 below the ring; the eye badge sits on a 40% shadow 2 below.

**The Warm Shadow Rule.** Every shadow uses Warm Shadow; never neutral black or grey.

### Components

**Buttons.** Tactile and springy. Primary: tangerine face, Ember Lip, plum-deep label. Secondary: Plum Soft face, Plum Deep lip, cream label. Padding is 12 top and bottom with 30 at the sides; when pressed, the top grows to 17, so the label drops as the lip flattens. Hover scales to 1.05 in 0.18 s with a back ease-out and returns in 0.2 s; press squashes to 1.04 × 0.93 in 0.06 s; release springs back in 0.28 s. Each press plays the click sound; the cursor is a pointing hand. Forward actions add a drawn chevron 34 px from the right edge, with right padding widened to 56. Instances: opening Play (220 wide); seated Play (220 × 64, bottom centre, 44 from the bottom; fades in over 0.45 s); welcome Next (210 × 64); tour Next (190 × 58, "Meet your player" on the last stop); tour Pause and Resume (secondary, minimum 110 × 52); pause menu buttons (62 tall, left-aligned).

**Inspect popup.** A plum board docked at the lower left, never over the centre: 28 × scale from the left, 32 × scale from the bottom, width 34% of the viewport clamped to 300–440. Contents stack at 8: the object's title (Title, 28), a description (Body, 20) that types in at 70 characters per second, a 6 px gap, then the action chip. The computer's chip is tangerine with the mouse icon (16 × 24) and "Click to play" in Plum Deep; the other objects show a Plum Soft "Coming soon" chip in Cream Muted with no icon. The popup never takes clicks; clicking the world while aiming at the computer starts its lesson.

**Leader line.** A dashed butter line (3 px, 9 px dashes every 16 px, 85% opacity) from a butter dot (radius 5, plum-deep centre 2.2) at the object's projected anchor to the popup's top edge, 36 px in from its right.

**Crosshair.** At rest: a cream dot (radius 3.2) in a plum-deep ring (radius 5.5, 2.5 stroke) on a soft halo. On a lesson object it blooms: the ring grows to 17 with a 4 px stroke and turns tangerine, breathes ±4%, and four butter ticks (7 long, 3 wide) circle it, turning slowly; an eye badge (plum disc, radius 13, butter rim, cream eye, plum-deep pupil) appears 27 px down and right. It shows only while playing with the mouse captured.

**Pause panel.** Esc during first-person play pauses the game, hides the crosshair and popup, and slides a plum board in from the left edge, vertically centred, over a 38% Plum Deep dim. Width is 30% of the viewport clamped to 320–420, inset 20–40 from the left; inner padding 34, stack 14. Contents: "Paused" (Headline), "Take a breather. Your room will wait for you." (Body, Cream Muted), a 12 px gap, then Resume (primary, focused), "Sound: on/off" and "Quit game" (secondary). Esc or Resume closes it.

**Progress pill.** During the tour, a 300 × 46 plum capsule sits 24 from the top centre with "Room discoveries" (18 / 600) at the left and four dots: the current stop butter (radius 8), completed stops tangerine (5.5), upcoming stops a Cream Muted ring (5, 2 stroke).

**Tour card and welcome.** The welcome is a 520-wide centred column, 23% down, over a 55% Plum Deep shade: Hero title, cream intro (24, plum-deep outline 6), and Next, stacked at 18. The tour card sits low and centred under the framed object: width up to 760 (viewport minus 48), 36 from the bottom, padding 22 × 30, stack 12; title, body, then a footer (gap 14) with the "1 / 4 · Computer" step counter, Pause, and Next.

**Tip bubble.** A plum board in the opening's lower left, 21% of the viewport wide clamped to 250–270, 104 tall, inset 18 × 12. Body copy at 21 / 600 in cream with a butter "Tip:" prefix; five tips rotate every 5 s (0.2 s fade out, 0.25 s fade in) and the bubble fades out over 0.45 s when the flight begins.

### Motion

Short, springy, and directional: things arrive from the left or pop up from below, and settle with an overshoot or an exponential ease-out.

- **Popup entrance:** slides from 30 px left to rest in 0.32 s (exponential ease-out) while fading in over 0.22 s. **Exit:** fades over 0.14 s while sliding 16 px left (quadratic ease-in).
- **Crosshair bloom:** eases exponentially toward its target (rate 14 per second); the ticks appear once bloom passes 0.3.
- **Tour card pop:** on arrival at each stop, the card scales from 0.92 to 1 about its bottom edge over 0.35 s with a back overshoot, fading in across the first ~60%.
- **Welcome:** the overlay fades in over 0.65 s; the hero, then intro, type in.
- **Pause:** opens in 0.38 s (exponential ease-out) with the dim fading in over 0.25 s and a whoosh; closes in 0.22 s (quartic ease-in).
- **Kit helper:** `SunsetUI.slide_in` offers the same entrance (28 px from the left, 0.32 s exponential ease-out, fade over 70% of the duration).

**The Clear Centre Rule.** During first-person play, only the crosshair occupies the screen centre. The popup docks lower left; the leader line starts at least 64 px from the centre; the pause panel enters from the left edge so the room stays visible.

### Sunset Do's and Don'ts

- **Do** build new opening, bedroom, and pause UI from `SunsetUI` (`panel_style`, `style_label` roles, `style_button`) instead of restyling controls by hand.
- **Do** keep a visible butter focus ring and focus the forward action when a screen appears.
- **Do** draw small glyphs in GDScript, as the chevron, mouse icon, and crosshair are.
- **Don't** place UI in the centre clear zone during first-person play.
- **Don't** use tangerine for secondary actions such as pause, sound, or quit.
