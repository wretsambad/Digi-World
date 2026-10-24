extends Node3D
## Use the separately authored winter environment directly. The map owns its
## golden-hour lighting, grouped objects and camera-following weather.
## Lesson cameras, the park board and photo clues stay with the GitHub game.

@onready var neighborhood: Node3D = $Neighborhood
