# Autumn Explorer appearance

Open `res://treehouse_animated.tscn` and run the current scene (F6).

This is an appearance-only version of the user's animated scene. It retains the original node hierarchy, unique IDs in the top-level scene, transforms, cameras, mesh geometry and scripts. No houses, branches, props, decks or ladders were added, removed or moved. The only additions are a lowered golden-hour sun and one `AutumnAmbience` node.

The look follows the sunset-maple reference painting: crimson, scarlet, ember and amber foliage with a warm rim light; dark evergreen poplars for contrast; honey cedar decks and warm bark; sage cabin paint under a deep red roof; cream trim; lamp-lit amber windows; and an olive lawn buried in drifts of fallen leaves. `autumn_sky.gdshader` paints a lavender-to-apricot sunset with slowly drifting clouds and hazy hills on the horizon. A low sun from the right of the backyard view casts long golden shadows, with warm fog, light glow and a small saturation lift.

`autumn_ambience.gd` (on the `AutumnAmbience` node) builds the living layer at load time, so none of it is saved into the scene. It adds maple leaves falling from the canopy and across the yard, glowing motes, warm light from the cabin windows, and a crackling campfire with flickering light. In play mode it also adds a gentle sway to the canopy. Pip (`res://protect_base_assets/pip.tscn`) uses the same palette: rust fur, toasted cream, chocolate paws, a sage jacket and a gold zip. `res://work/pip_fit_preview.tscn` shows Pip standing in the backyard.

The 43 scenes in `models/` provide isolated material variants. Original shared treehouse and neighborhood assets, the original `treehouse.tscn`, the bedroom and the project main scene are untouched. These variants retain all mesh geometry and node paths from their source assets.

`../source/style_autumn.gd` creates the material variants and updates appearance fields in the target scene. Its input is the pre-restyle snapshot `res://work/treehouse_animated_before_autumn.tscn`. Do not rerun it after structural edits without deliberately updating that snapshot.

`../source/check_autumn.gd` compares the target against that snapshot. It ignores `AutumnAmbience` and the sun's angle. The check passed for 8,128 nodes, 6,890 mesh instances and 644 unique mesh pairs. The input snapshot contained no AnimationPlayer nodes; scripts and all existing node paths were retained. The checker also compares animation tracks and keyframes if present.

Append `-- --capture` to a graphical check run to refresh `../preview/autumn_explorer.png` and `../preview/autumn_overview.png`.
