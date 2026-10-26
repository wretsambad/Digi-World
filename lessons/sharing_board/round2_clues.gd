extends RefCounted
## Content for Sharing Board, Round 2: "Spot it before you post".
## Each clue id matches a named detail node inside its photo's physical prop.
## Move the prop to move the object and its identifying details together.
## Safe objects are also found by name, wherever they sit in the photo scene.

## Things in the photo that give away who you are or where you live.
const CLUES := [
	{
		"id": "house_number",
		"name": "House number",
		"why": "It shows where you live.",
		"hint": "Look for the number on the house.",
	},
	{
		"id": "family_sign",
		"name": "Family name sign",
		"why": "It shows who you are.",
		"hint": "Read the little welcome sign.",
	},
	{
		"id": "delivery_label",
		"name": "Parcel label",
		"why": "It shows your name and address.",
		"hint": "Check the label on the parcel.",
	},
]

## Things that are fine to share, so tapping them teaches what's safe.
const DECOYS := {
	"snowman": "Your snowman! Safe to share.",
	"sled": "Just a sled. Safe!",
	"snowballs": "Just snowballs. Safe!",
}

const SLED_CLUES := [
	{"id":"sled_name","name":"Sled owner's tag","why":"It shows your name.","hint":"Check the tag on the sled rope."},
	{"id":"phone_number","name":"Phone screen","why":"Strangers could call or text you.","hint":"Read the phone screen."},
	{"id":"hat_school","name":"School badge","why":"It shows your school.","hint":"Read the badge on the winter hat."},
	{"id":"street_sign","name":"Street name","why":"It shows where you are.","hint":"Read the street sign."},
]

const CRAFT_CLUES := [
	{"id":"drawing_name","name":"Drawing signature","why":"It shows your full name.","hint":"Check the name on the drawing."},
	{"id":"invite_address","name":"Party invitation","why":"It shows where the party is.","hint":"Read the party invitation."},
	{"id":"phone_trip","name":"Message notification","why":"It shows when your home is empty.","hint":"Read the phone screen."},
	{"id":"car_plate","name":"Car license plate","why":"It can identify your car.","hint":"Check the blue car."},
	{"id":"street_sign","name":"Street name","why":"It shows where you are.","hint":"Read the street sign."},
]

const PHOTOS := [
	{"id":"snowman","title":"Snow day","caption":"My snowman is the best!", "node":"PhotoSet", "fov":66.0,
		"intro":"You want to post your snowman!\n\nUse the [b]magnifying glass[/b] to find [b]{clue_count} private details[/b] to cover first.",
		"clues":CLUES,"decoys":DECOYS},
	{"id":"sled_break","title":"Sled break","caption":"A cozy sled break!", "node":"SledPhotoSet", "fov":55.0,
		"intro":"Cocoa after sledding! Find [b]{clue_count} private details[/b].\n\nThey're smaller this time. Look near and far.",
		"clues":SLED_CLUES,"decoys":{"sled":"The sled is fine. Check its labels, though!","mug":"Just cocoa. Safe!","boots":"Just boots. Safe!","InsulatedWaterBottle":"No name on it. Safe!"}},
	{"id":"park_crafts","title":"Park Day crafts","caption":"Made for Park Day!", "node":"CraftPhotoSet", "fov":60.0,
		"intro":"Your birdhouse is ready! Find [b]{clue_count} private details[/b].\n\nCheck the table, bench and street.",
		"clues":CRAFT_CLUES,"decoys":{"birdhouse":"Your birdhouse! Great to share.","paints":"Just paints. Safe!","mug":"Just a mug. Safe!"}},
]
