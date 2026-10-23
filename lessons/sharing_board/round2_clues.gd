extends RefCounted
## Content for Sharing Board, Round 2: "Spot it before you post".
## Each id matches a node under PhotoSet/Clues or PhotoSet/Decoys in
## round2_photo_set.tscn; move those nodes to move the clues in the photo.

## Things in the photo that give away who you are or where you live.
const CLUES := [
	{
		"id": "house_number",
		"name": "House number",
		"why": "It shows exactly which house is yours.",
		"hint": "Look next to the front door.",
	},
	{
		"id": "away_note",
		"name": "\"Gone skiing\" note",
		"why": "It tells everyone that nobody is home.",
		"hint": "Is anything stuck on the door?",
	},
	{
		"id": "family_sign",
		"name": "Family name sign",
		"why": "Your last name plus your house makes you easy to find.",
		"hint": "Check the garden by the steps.",
	},
	{
		"id": "school_backpack",
		"name": "School backpack",
		"why": "It shows where you are every school day.",
		"hint": "What's sitting by the porch?",
	},
	{
		"id": "window_pennant",
		"name": "\"Sam's room\" flag",
		"why": "It shows your name and which window is your bedroom.",
		"hint": "Look up at the windows.",
	},
]

## Things that are fine to share, so tapping them teaches what's safe.
const DECOYS := {
	"snowman": "That's your snowman, the star of the photo. Safe to share!",
	"sled": "A sled doesn't tell anyone where you live. Safe!",
	"snowballs": "Just snowballs. Nothing private there!",
}
