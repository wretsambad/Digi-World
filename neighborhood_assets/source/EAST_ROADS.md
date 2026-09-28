# Eastern streets

The eastern curve and background street network are one connected surface in
`../preview/east_background_roads.tscn`, instanced as
`ExistingNeighborhood/EastBendExtension/ConnectingRoads` in the main scene.
The original east-curve GLBs remain available, but their three scene instances
were replaced to prevent overlapping pavement at the new junction.

The road geometry uses the original east route from `../sightline_routes.json`
and the original imported asphalt, sidewalk, and cream materials. Asphalt is
at Y=0, sidewalks at 0.15m, and curbs at 0.17m. Roads are 7.2m wide; sidewalks
are 1.8m wide, with a 0.15m curb. Center stripes are 0.14m wide, with 1.95m
dashes on a 3.4m spacing. Junctions have rounded corners and clear entrances.

The four mesh children separate asphalt, sidewalks, curbs, and center lines.
The camera path and animation are independent and unchanged. Temporary
clearance testing does not add permanent gameplay collision shapes.
