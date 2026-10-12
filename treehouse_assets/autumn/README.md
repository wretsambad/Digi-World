# Autumn Explorer appearance

Open `res://treehouse_animated.tscn` and run the current scene (F6).

This is an appearance-only version of the user's animated scene. It retains the original node hierarchy, unique IDs in the top-level scene, transforms, cameras, mesh geometry and scripts. No houses, branches, props, decks or ladders were added, removed or moved.

The playful autumn palette uses golden-yellow, apricot, coral and raspberry foliage; honey-colored cedar and warm bark; turquoise cabin paint; a coral roof; buttery cream trim; amber glazing; a lighter sky and soft daylight; and a brighter grassy lawn with small procedural fallen-leaf marks. Exposure and light energy are balanced to preserve detail in the brighter colors. Wood grain and ground litter are material effects, not added geometry. Sun orientation is unchanged.

The 43 scenes in `models/` provide isolated material variants. Original shared treehouse and neighborhood assets, the original `treehouse.tscn`, the bedroom and the project main scene are untouched. These variants retain all mesh geometry and node paths from their source assets.

`../source/style_autumn.gd` creates the material variants and updates appearance fields in the target scene. Its input is the pre-restyle snapshot `res://work/treehouse_animated_before_autumn.tscn`. Do not rerun it after structural edits without deliberately updating that snapshot.

`../source/check_autumn.gd` compares the target against that snapshot. The check passed for 8,128 nodes, 6,890 mesh instances and 644 unique mesh pairs. The input snapshot contained no AnimationPlayer nodes; scripts and all existing node paths were retained. The checker also compares animation tracks and keyframes if present.

Append `-- --capture` to a graphical check run to refresh `../preview/autumn_explorer.png` and `../preview/autumn_overview.png`.
