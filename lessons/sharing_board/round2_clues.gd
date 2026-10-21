extends RefCounted
## Content for Sharing Board, Round 2: "Spot it before you post".
## Each id matches a node under Clues or Decoys in its PHOTOS scene.
## Move those nodes to move the clues in the photo.

## Things in the photo that give away who you are or where you live.
const CLUES := [
	{
		"id": "house_number",
		"name": "House number",
		"why": "This number helps locate your home.",
		"hint": "Look above the porch, beside the front door.",
	},
	{
		"id": "family_sign",
		"name": "Family name sign",
		"why": "Your family name helps identify you.",
		"hint": "Check the little welcome sign at the far left of the garden.",
	},
	{
		"id": "delivery_label",
		"name": "Parcel label",
		"why": "It shows a full name and home address.",
		"hint": "Check the label on the parcel beside the porch.",
	},
]

## Things that are fine to share, so tapping them teaches what's safe.
const DECOYS := {
	"snowman": "That's your snowman, the star of the photo. Safe to share!",
	"sled": "A sled doesn't tell anyone where you live. Safe!",
	"snowballs": "Just snowballs. Nothing private there!",
}

const SLED_CLUES := [
	{"id":"sled_name","name":"Sled owner's tag","why":"A full name can identify you.","hint":"Check the little tag tied to the sled rope."},
	{"id":"bottle_phone","name":"Bottle return label","why":"That phone number is private.","hint":"Look at the return label on the bottle beside the boots."},
	{"id":"hat_school","name":"School badge","why":"It shows which school you attend.","hint":"Check the winter hat on the right end of the bench."},
	{"id":"street_sign","name":"Street name","why":"The street name gives away the location.","hint":"Look past the pond, at the street sign by the road on the left."},
]

const CRAFT_CLUES := [
	{"id":"drawing_name","name":"Drawing signature","why":"The drawing includes a full name.","hint":"Check the tiny signature on the drawing on the front bench."},
	{"id":"invite_address","name":"Party invitation","why":"A private party's time and address are private.","hint":"Read the invitation beside the drawing."},
	{"id":"phone_trip","name":"Message notification","why":"It reveals when the home will be empty.","hint":"Look at the message on the phone screen."},
	{"id":"car_plate","name":"Car license plate","why":"The plate identifies a specific car.","hint":"Look behind the table at the blue car's license plate."},
	{"id":"street_sign","name":"Street name","why":"It helps someone work out where this photo was taken.","hint":"Check the street sign beside the road in the upper right."},
]

const PHOTOS := [
	{"id":"snowman","title":"Snow day","caption":"My snowman is the best!", "scene":"res://lessons/sharing_board/round2_photo_set.tscn", "fov":66.0,
		"intro":"You built an awesome snowman in front of your house, and you want to post this photo on the park board.\n\nUse the [b]hoop[/b] to look closely. Find and cover the [b]three identifying details[/b] before you post.",
		"clues":CLUES,"decoys":DECOYS},
	{"id":"sled_break","title":"Sled break","caption":"A cozy sled break!", "scene":"res://lessons/sharing_board/round2_sled_photo.tscn", "fov":55.0,
		"intro":"Time for cocoa after sledding! This photo has [b]four identifying details[/b] in the winter gear and the scenery.\n\nThe print is a little finer this time. Check the foreground and background before sharing.",
		"clues":SLED_CLUES,"decoys":{"sled":"The wooden sled is fine to share. Check any labels attached to it, though!","mug":"Just a warm drink. There's nothing private on this mug.","boots":"Plain winter boots are safe to share."}},
	{"id":"park_crafts","title":"Park Day crafts","caption":"Made for Park Day!", "scene":"res://lessons/sharing_board/round2_craft_photo.tscn", "fov":53.0,
		"intro":"Your birdhouse is ready for Park Day! There are [b]five identifying details[/b] across this photo.\n\nCheck the table, the bench and the street behind them. Share the fun things while keeping personal details covered.",
		"clues":CRAFT_CLUES,"decoys":{"birdhouse":"Your handmade birdhouse is a great thing to share!","paints":"Paints and brushes don't identify anyone. Safe to share!","mug":"This plain mug doesn't show anything private."}},
]
