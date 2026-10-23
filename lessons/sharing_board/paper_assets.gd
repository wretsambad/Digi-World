extends RefCounted
## Photograph printed on the public hobby note; sorting UI is unchanged.
const PHOTOS := {
	"hobby": preload("res://lessons/sharing_board/art/soccer_snow.png"),
}
static func photo_for(id: String) -> Texture2D:
	return PHOTOS.get(id)
