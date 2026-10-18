# Editing the bedroom

Open `teen_bedroom.tscn` in Godot and expand `LearningHouseDetailed/BedroomInterior`.
Architecture, StudyCorner, SleepCorner, CreativeCorner, PersonalDetails, and the
lesson groups contain separately selectable model instances. Each can be moved,
rotated, scaled, hidden, duplicated, or removed. Expand a model to edit its mesh
node and apply a material override. Make shared mesh/material resources unique
before changing the resource itself for just one instance.

`NearbyNeighborhood` likewise contains independent scenery instances. These two
containers are local nodes in this scene, rather than locked scene instances.
The individual models retain their source asset links and editable children.
The original model geometry, object paths, layout, and gameplay are preserved.

Edits made here belong to this bedroom scene. The separate
`learning_house_detailed.tscn` used by other scenes remains independent.

`source/separate_teen_bedroom.gd` performs the conversion and checks that packing
preserves the hierarchy, transforms, meshes, materials, and scripts. The connected
scene builder also applies `source/editable_bedroom.gd` when rebuilding.
