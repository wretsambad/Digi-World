extends RefCounted
## Content for Sharing Board, Round 1: "Who should see it?"
## Edit the zones and cards here; the board UI builds itself from this data.

## The four places a card can go, left to right on the board.
const ZONES := [
	{
		"id": "everyone",
		"title": "Everyone",
		"subtitle": "On the park board",
		"color": Color("#7FB6D5"),
	},
	{
		"id": "friends",
		"title": "Friends I know",
		"subtitle": "People I trust",
		"color": Color("#E3A72F"),
	},
	{
		"id": "grownup",
		"title": "Trusted adults",
		"subtitle": "Who looks after me",
		"color": Color("#E58A6E"),
	},
	{
		"id": "secret",
		"title": "Keep it private",
		"subtitle": "Don't share",
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
		"ok": ["everyone", "friends", "grownup"],
		"why": "A favorite color is a fun fact. Fine for anyone!",
	},
	{
		"id": "snowman_drawing",
		"kind": "Something I made",
		"text": "A drawing of the snowman I built",
		"ok": ["everyone", "friends", "grownup"],
		"why": "Share your drawing! Just make sure your full name isn't on it.",
	},
	{
		"id": "hobby",
		"kind": "Fun fact",
		"text": "I love playing soccer",
		"ok": ["everyone", "friends", "grownup"],
		"why": "Liking soccer is fine to share. Keep practice times private.",
	},
	{
		"id": "party_invite",
		"kind": "Where I'll be",
		"text": "My party invite (time and place)",
		"ok": ["friends", "grownup", "secret"],
		"why": "Give invites to friends you trust. The time and place stay off the board.",
	},
	{
		"id": "snow_angel_photo",
		"kind": "My face",
		"text": "A silly photo of me in the snow",
		"ok": ["friends", "grownup", "secret"],
		"why": "Photos of you are for people you trust. Keeping it private is okay too.",
	},
	{
		"id": "home_address",
		"kind": "Where I live",
		"text": "My home address",
		"ok": ["friends", "grownup", "secret"],
		"why": "Your address shows where you live. Never put it on a public board.",
	},
	{
		"id": "phone_number",
		"kind": "How to reach me",
		"text": "My phone number",
		"ok": ["friends", "grownup", "secret"],
		"why": "Ask a grown-up before giving out your number. Never post it.",
	},
	{
		"id": "school_name",
		"kind": "Where I'll be",
		"text": "The name of my school",
		"ok": ["friends", "grownup", "secret"],
		"why": "Your school tells strangers where to find you. Keep it off the board.",
	},
	{
		"id": "ski_trip",
		"kind": "When I'm away",
		"text": "\"We're away on a ski trip all next week!\"",
		"ok": ["friends", "grownup", "secret"],
		"why": "This tells everyone your home is empty. Post trip photos after you're back.",
	},
	{
		"id": "dog_photo",
		"kind": "Where I live",
		"text": "My dog by our house number",
		"ok": ["friends", "grownup", "secret"],
		"why": "The house number shows where you live. Crop it out before posting.",
	},
	{
		"id": "password",
		"kind": "Secret key",
		"text": "My game password",
		"ok": ["secret", "grownup"],
		"why": "Passwords are secret. Only a parent or carer may help with it.",
	},
]
