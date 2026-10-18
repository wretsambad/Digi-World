extends RefCounted
## Content for Sharing Board, Round 1: "Who should see it?"
## Edit the zones and cards here; the board UI builds itself from this data.

## The four places a card can go, left to right on the board.
const ZONES := [
	{
		"id": "everyone",
		"title": "Everyone",
		"subtitle": "Pinned on the park board",
		"color": Color("#7FB6D5"),
	},
	{
		"id": "friends",
		"title": "Friends I know",
		"subtitle": "People I've met in real life",
		"color": Color("#E3A72F"),
	},
	{
		"id": "grownup",
		"title": "Ask a grown-up",
		"subtitle": "Check with them first",
		"color": Color("#E58A6E"),
	},
	{
		"id": "secret",
		"title": "Keep it secret",
		"subtitle": "Only me and my grown-ups",
		"color": Color("#A595C7"),
	},
]

## "ok" lists every zone that counts as a safe answer.
## "why" is shown when the card is put somewhere unsafe.
## "kind" is the sewn tag a patch earns once it is checked: what sort of info it is.
const CARDS := [
	{
		"id": "favorite_color",
		"kind": "Fun fact",
		"text": "My favorite color is purple",
		"ok": ["everyone", "friends"],
		"why": "Fun facts like your favorite color can't help a stranger find you. That one's fine to share!",
	},
	{
		"id": "snowman_drawing",
		"kind": "Something I made",
		"text": "A drawing of the snowman I built",
		"ok": ["everyone", "friends"],
		"why": "Your art is great to share, as long as it doesn't show where you live.",
	},
	{
		"id": "hobby",
		"kind": "Fun fact",
		"text": "I love playing soccer",
		"ok": ["everyone", "friends"],
		"why": "Hobbies are safe to share. They don't say who you are or where to find you.",
	},
	{
		"id": "party_invite",
		"kind": "Where I'll be",
		"text": "Invite to my birthday party (with the time and place)",
		"ok": ["friends", "grownup"],
		"why": "An invite tells people where you'll be and when. Only send it to friends you know in real life.",
	},
	{
		"id": "snow_angel_photo",
		"kind": "My face",
		"text": "A silly photo of me making a snow angel",
		"ok": ["friends", "grownup"],
		"why": "Photos of your face are for people you know. Once a photo is public, anyone can save a copy.",
	},
	{
		"id": "home_address",
		"kind": "Where I live",
		"text": "My home address",
		"ok": ["grownup", "secret"],
		"why": "Your address tells people exactly where you live. Ask a grown-up before sharing it with anyone.",
	},
	{
		"id": "phone_number",
		"kind": "How to reach me",
		"text": "My phone number",
		"ok": ["grownup", "secret"],
		"why": "With your number, anyone could call or text you. Check with a grown-up first.",
	},
	{
		"id": "school_name",
		"kind": "Where I'll be",
		"text": "The name of my school",
		"ok": ["grownup", "secret"],
		"why": "Your school's name tells people where to find you every weekday.",
	},
	{
		"id": "ski_trip",
		"kind": "When I'm away",
		"text": "\"We're away on a ski trip all next week!\"",
		"ok": ["grownup", "secret"],
		"why": "This tells everyone your home will be empty. Share your trip photos after you get back!",
	},
	{
		"id": "dog_photo",
		"kind": "Where I live",
		"text": "Photo of my dog in the snow, with our house number behind her",
		"ok": ["grownup", "secret"],
		"why": "Your dog is fine to share, but the house number shows where you live. Take a new photo without it!",
	},
	{
		"id": "password",
		"kind": "Secret key",
		"text": "My game password",
		"ok": ["secret"],
		"why": "Passwords are only for you and your grown-ups, not even best friends. Remember the treehouse!",
	},
]
