# Digi-World teenage bedroom

This is a NEW scene: `C:/Users/samar/Documents/digi-world/bedroom_assets/teen_bedroom.tscn`.

Open that scene in Godot and press F6. The existing neighborhood, previous bedroom, other scenes, model assets and project startup settings were preserved. This room is not automatically substituted into the opening sequence.

## Room and detail

The room uses the existing bedroom's 7.4 x 6.6m proportions and a 3.2m ceiling. It has separate architectural models, an actual west-window opening with an open sash, individual oak floorboards, layered bedding, storage furniture, a detailed study desk, pinned photographs and notes, posters, music and sports props, school supplies, plants and small everyday objects.

There are 65 new GLB models, 50,140 unique model triangles, and 198 individually placed architectural/furniture/prop instances recorded in placement.json. The scene also has three distant trees for the window view and a native curtain-rod mesh. The trees reuse the existing neighborhood oak GLB. “10x more detail” is treated as a substantial visual-detail increase, not a measured rendering-quality multiplier.

Each GLB remains separate in models/. Blender source in source/teen_bedroom.blend preserves separately named model collections and their component meshes. Furniture and equipment retain ordinary meter-like dimensions.

## Four future lesson objects

| Scene group | Object/location | Intended later lesson |
| --- | --- | --- |
| Lesson_Computer | Computer on the study desk | Passwords and account protection |
| Lesson_Phone | Phone on the bedside notebook | Suspicious messages |
| Lesson_SharingBoard | Corkboard with fictional photos and notes | What to share and keep private |
| Lesson_BackupRobot | Robot and separate backup drive on the creative shelf | Backup and recovery |

Each group has a FocusAnchor Marker3D and metadata describing its intended lesson. These are visual placeholders: no click handlers, lesson UI, gameplay, ball physics, save data or animation controllers are installed. The monitor and phone screens are static model geometry using fictional content.

## Inspect the scene

EntryCamera is current by default. StudyCamera, CreativeCamera and BedsideCamera provide additional saved views; make one current in the inspector to use it when running the scene. Normal editor navigation also works. No navigation/controller script is attached.

The west window has a real opening and a FutureWindowPassage marker. Nine temporary rays checked a 0.2m-wide corridor from outside into the room; this is preparation for a later fly-through, not a completed transition. Permanent collision shapes are not included.

The scene was imported and rendered with the project's current Compatibility/OpenGL renderer. Scene lighting is local to this new scene. The environment includes optional SSAO settings for higher-capability renderers; Compatibility does not use them. Target-device performance has not been benchmarked.

## Validation and backup

All new GLBs load in Godot 4.7.2. Geometry structure and finite bounds were checked. Four lesson groups have scene-owned, separately editable children and no active interactions. Four rendered views cover the full room, study, robot corner and bedside.

SHA-256 comparisons confirmed all 151 pre-existing scenes/model files/project configuration files in the snapshot are byte-for-byte unchanged. The task writes into bedroom_assets only; Godot's import cache is generated normally.

Source generators are included for repeatability. Build the models in Blender, assemble the new scene, then run finalize_bedroom.gd in Godot to add its saved cameras. Regeneration replaces only this new bedroom build, so review before running it over subsequent hand edits.

Digi-World-teen-bedroom.zip is an additive package for the existing Digi-World project. Extract its bedroom_assets folder into that project.
