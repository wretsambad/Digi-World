extends RefCounted
## Everything the players read in The Glitch's Last Trick. Each round is one
## trick on the phone; catching it brings back one piece of the party.
##
## tools: the detective kit buttons shown this round, in order.
##   sender = Magnifier (who really sent it), link = Link Peek (where a link
##   really goes), wants = What does it want?, ask = Ask someone you trust.
## clues: what a tool uncovers. Every clue must be found before deciding.
## plain: what a tool says when there is nothing odd for it to find.

const TOOL_NAMES := {
	"sender": "Magnifier",
	"link": "Link Peek",
	"wants": "What does it want?",
	"ask": "Ask someone",
}

const CONTACTS := {
	"pip": {"name": "Pip", "color": Color("5d7d4f"), "last": "On my way to the party!"},
	"family": {"name": "Family", "color": Color("3f8a86"), "last": "Have fun tonight!"},
}

const TITLE := "The Glitch's Last Trick"
const SUBTITLE := "Catch the tricks. Save the party."

const OPENING := [
	["PIP", "Tonight is the big Digi-World party in Willow Park! I'm on my way."],
	["PIP", "Uh oh. Someone switched the whole party off. And your phone keeps buzzing..."],
	["PIP", "I bet it's the Glitch. Catch each trick, and we can turn the party back on!"],
]

const ROUNDS := [
	{
		"piece": "lights",
		"name": "The Lights",
		"intro": [["PIP", "First, the lights. Hey, you've got a message!"]],
		"kind": "message",
		"sender": "D1gi-World Party",
		"handle": "d1gi-world-party@prize-zone.biz",
		"avatar": "star",
		"avatar_color": Color("8a46ff"),
		"lines": ["You're invited!! Party lights stay OFF unless you RSVP right now!"],
		"link": "digi-world-party.com/rsvp",
		"link_real": "prize-zone.biz/grab",
		"bait": "RSVP now!",
		"timer_text": "RSVP closes in",
		"timer": 30,
		"tools": ["sender", "link"],
		"new_tools": ["sender", "link"],
		"clues": {
			"sender": {"title": "Look at the name", "body": "\"D1gi\" has the number 1, not the letter i. And it came from prize-zone.biz, not from Pip."},
			"link": {"title": "Where does it go?", "body": "The link says digi-world-party.com, but it really goes to prize-zone.biz/grab. That's not the party!"},
		},
		"plain": {},
		"choices": [
			{"text": "Tap the RSVP link", "right": false, "why": "That link went to prize-zone.biz, not the party. A real invite never makes you rush."},
			{"text": "Delete it and report it", "right": true},
			{"text": "Send it to all my friends", "right": false, "why": "Sending it on spreads the trick to your friends too."},
		],
		"bait_why": "Gotcha! A rushed tap is the Glitch's favorite trick. Real invites can wait while you check.",
		"solved": [
			["PIP", "The lights are back! Tricks lose their power when you stop and check."],
			["PIP", "Wait... did you see that? Something flickered by the speaker!"],
		],
		"lesson": "Pause & Check: real friends can wait.",
	},
	{
		"piece": "music",
		"name": "The Music",
		"intro": [["PIP", "Next, the music. Hmm, a pop-up just burst onto your phone..."]],
		"kind": "shop",
		"sender": "Digi Prize Shop",
		"handle": "digi-prize-shop.win",
		"avatar": "gift",
		"avatar_color": Color("ff6fa8"),
		"lines": ["WINNER!! Everything is FREE tonight! Claim your prizes before the timer runs out!"],
		"link": "",
		"bait": "Claim all 3!",
		"timer_text": "Offers end in",
		"timer": 25,
		"tools": ["wants"],
		"new_tools": ["wants"],
		"offers": [
			{"icon": "treehouse", "title": "Golden Treehouse", "small_print": "To claim, type your Digi-World password.", "trap": "password"},
			{"icon": "balloon", "title": "Unlimited Decorations", "small_print": "To claim, tell us your full name, home address and school.", "trap": "private"},
			{"icon": "snowman", "title": "Flying Snowman", "small_print": "To claim, download snowman_FLY.exe", "trap": "download"},
		],
		"traps": {
			"password": "Your password",
			"private": "Private details",
			"download": "A mystery download",
		},
		"trap_notes": {
			"password": "Nobody needs your password to give you a prize.",
			"private": "Your name, address and school are private. Remember the Sharing Board!",
			"download": "A mystery download can sneak bad stuff onto your phone.",
		},
		"clues": {},
		"plain": {},
		"choices": [
			{"text": "Claim all three prizes", "right": false, "why": "All three prizes were traps: a password, private details and a mystery download."},
			{"text": "Just claim the Flying Snowman", "right": false, "why": "Even one mystery download can bring in a virus."},
			{"text": "Close the shop and tell a grown-up", "right": true},
		],
		"bait_why": "Gotcha! Prizes that sound too good to be true usually are. Always read what they want first.",
		"solved": [
			["PIP", "Music! You didn't fall for a single prize. Too good to be true means: check!"],
			["PIP", "Did you hear that crackle? Something is hiding behind the speaker..."],
		],
		"lesson": "Free prizes that want a password, private details or a download are traps.",
	},
	{
		"piece": "decorations",
		"name": "The Decorations",
		"intro": [["PIP", "Now the decorations. They should be here by now..."]],
		"kind": "message",
		"sender": "Party Delivery Co",
		"handle": "+1 555 0199  (not in your contacts)",
		"avatar": "truck",
		"avatar_color": Color("e2b13c"),
		"lines": ["Your party decorations are STUCK on our truck!", "Reply with your home address and phone number so we can drop them off."],
		"link": "",
		"bait": "Send my address",
		"timer_text": "Truck leaves in",
		"timer": 30,
		"tools": ["sender", "link", "wants", "ask"],
		"new_tools": ["ask"],
		"clues": {
			"sender": {"title": "Who is it from?", "body": "A number that isn't in your contacts. And you never ordered any decorations."},
			"wants": {"title": "What does it want?", "body": "Your home address and phone number. Those are private details. Keep them safe!"},
			"ask": {"title": "Your family says", "body": "Nobody ordered decorations. Never send our address to a stranger."},
		},
		"plain": {"link": "No links in this one. It wants you to reply instead."},
		"chat": {
			"contact": "family",
			"ask": "A delivery company wants our address for party decorations. Did we order some?",
			"reply": "Nope, we didn't order anything! Thanks for asking first. Don't send our address. Let's block that number.",
		},
		"choices": [
			{"text": "Block the number and report it", "right": true},
			{"text": "Send our home address", "right": false, "why": "Your address is private. Strangers should never get it from a message."},
			{"text": "Ask them where they live", "right": false, "why": "Chatting with a trickster keeps the trick going. Just block and report."},
		],
		"bait_why": "Gotcha! Your address is private. When in doubt, ask a grown-up you trust first.",
		"solved": [
			["PIP", "Decorations! Asking a grown-up you trust was the perfect move."],
			["PIP", "Look! A shadow behind the balloons... It has pointy ears!"],
		],
		"lesson": "Ask a grown-up you trust before sending private details.",
	},
	{
		"piece": "celebration",
		"name": "The Celebration",
		"intro": [
			["PIP", "Everything is ready! I'm just grabbing the party hats from my treehouse..."],
			["", "Pip has gone quiet. Then your phone buzzes, really loudly."],
		],
		"kind": "message",
		"sender": "Treehouse Rescue Team",
		"handle": "@treehouse_rescue_team  (made today)",
		"avatar": "siren",
		"avatar_color": Color("ff5a5a"),
		"lines": ["HELP!! Pip's treehouse is LOCKED and Pip is stuck inside!", "Send YOUR password right now so we can rescue Pip!"],
		"link": "",
		"bait": "Send my password",
		"timer_text": "Rescue ends in",
		"timer": 20,
		"tools": ["sender", "link", "wants", "ask"],
		"new_tools": [],
		"clues": {
			"sender": {"title": "Who is it from?", "body": "A brand new account made today. Real rescue teams don't text kids."},
			"wants": {"title": "What does it want?", "body": "Your password! Nobody needs your password to rescue anyone. Not even Pip."},
			"ask": {"title": "Pip says", "body": "Pip is safe and walking to the party. The message was a trick!"},
		},
		"plain": {"link": "No links this time. It just wants your password."},
		"chat": {
			"contact": "pip",
			"ask": "Pip, are you locked in your treehouse??",
			"reply": "Locked in? Nope! I'm walking to the park right now. That message isn't from me!",
		},
		"choices": [
			{"text": "Send my password to save Pip", "right": false, "why": "Pip was never locked in. Your password is just for you. Never send it."},
			{"text": "Reply \"Who is this?\"", "right": false, "why": "Replying tells the trickster you're listening. Report it instead."},
			{"text": "Report it and tell a grown-up", "right": true},
		],
		"bait_why": "Gotcha! Scary, rushed messages are a trick. Check with the real person in your usual chat.",
		"solved": [
			["PIP", "I'm here! And look who was behind every trick..."],
		],
		"lesson": "Check with the real person, in the chat you already use.",
	},
]

const GLITCH_CAUGHT := [
	["THE GLITCH", "Bzzt! You caught ALL my tricks? My fake invite, my prize shop, my delivery truck... even my best one!"],
]

## Score is the number of rounds caught without being tricked even once.
const ENDING_SPARK := [
	["THE GLITCH", "Without anyone falling for my tricks, I'm just... a tiny spark."],
	["THE GLITCH", "Um. Can I come to the party too?"],
	["PIP", "Only if you play fair! Party time, everyone!"],
]
const ENDING_ESCAPE := [
	["THE GLITCH", "Hee hee! I still got a few of you. See you next time..."],
	["PIP", "It zipped away! Next time, Pause & Check from the very start."],
	["PIP", "But the party is saved. Party time, everyone!"],
]
const SPARK_SCORE := 3
