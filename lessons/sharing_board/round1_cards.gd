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
		"subtitle": "People I know and trust",
		"color": Color("#E3A72F"),
	},
	{
		"id": "grownup",
		"title": "Trusted adults",
		"subtitle": "People who look after me:",
		"color": Color("#E58A6E"),
	},
	{
		"id": "secret",
		"title": "Keep it private",
		"subtitle": "I don't need to share this",
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
		"why": "A favorite color is a general fun fact. It is usually fine to share publicly, with friends, or with your parents or carers.",
	},
	{
		"id": "snowman_drawing",
		"kind": "Something I made",
		"text": "A drawing of the snowman I built",
		"ok": ["everyone", "friends", "grownup"],
		"why": "You can share your drawing with friends, parents or carers, or on the park board. Check that it has no full name, address, or other private details.",
	},
	{
		"id": "hobby",
		"kind": "Fun fact",
		"text": "I love playing soccer",
		"ok": ["everyone", "friends", "grownup"],
		"why": "Saying you enjoy soccer is usually fine to share. Keep your team's meeting place and practice times out of public posts.",
	},
	{
		"id": "party_invite",
		"kind": "Where I'll be",
		"text": "Invite to my birthday party (with the time and place)",
		"ok": ["friends", "grownup", "secret"],
		"why": "Send invitations privately to friends you know and trust, and check the plans with a parent or carer. The time and place do not belong on a public board.",
	},
	{
		"id": "snow_angel_photo",
		"kind": "My face",
		"text": "A silly photo of me making a snow angel",
		"ok": ["friends", "grownup", "secret"],
		"why": "You can show a fun photo privately to trusted friends or your parents or carers. Share it only if you feel comfortable and anyone else pictured agrees. Keeping it private is okay too.",
	},
	{
		"id": "home_address",
		"kind": "Where I live",
		"text": "My home address",
		"ok": ["friends", "grownup", "secret"],
		"why": "A trusted friend may need your address to visit, with your parent's or carer's okay. Share it privately with them or your parents or carers. Never put it on a public board.",
	},
	{
		"id": "phone_number",
		"kind": "How to reach me",
		"text": "My phone number",
		"ok": ["friends", "grownup", "secret"],
		"why": "You can give your number privately to trusted friends or your parents or carers to stay in touch. Check with a parent or carer before sharing it, and keep it off public posts.",
	},
	{
		"id": "school_name",
		"kind": "Where I'll be",
		"text": "The name of my school",
		"ok": ["friends", "grownup", "secret"],
		"why": "It can be okay to tell trusted friends or your parents or carers which school you attend. Posting it for everyone can tell strangers where to find you each weekday.",
	},
	{
		"id": "ski_trip",
		"kind": "When I'm away",
		"text": "\"We're away on a ski trip all next week!\"",
		"ok": ["friends", "grownup", "secret"],
		"why": "Discuss travel plans privately with trusted friends or your parents or carers. A public post could reveal that your home will be empty. Save public trip photos for after you return.",
	},
	{
		"id": "dog_photo",
		"kind": "Where I live",
		"text": "Photo of my dog in the snow, with our house number behind her",
		"ok": ["friends", "grownup", "secret"],
		"why": "You can show this privately to trusted friends or your parents or carers. Before posting it publicly, crop out the house number or take another photo that keeps your address private.",
	},
	{
		"id": "password",
		"kind": "Secret key",
		"text": "My game password",
		"ok": ["secret", "grownup"],
		"why": "Keep your password private. A parent or carer may help you look after your account, but friends and strangers should never get your password.",
	},
]
