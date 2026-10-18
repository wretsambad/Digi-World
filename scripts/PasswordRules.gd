class_name PasswordRules
extends RefCounted
## Scores pretend passwords for the lesson and reports the first rule that fails.
## Only ever used on the made-up examples in data/protect_your_base.json.

const MIN_LENGTH := 8
## Checked in this order; the first failure is the one explained to the player.
const ORDER: Array[String] = ["common", "personal", "length", "mixed_case", "number", "symbol"]
const RULES: Dictionary = {
	"common": {"name": "Not a famous password", "message": "That's a famous password a Glitch tries first.", "tip": "Make up your own mix of words."},
	"personal": {"name": "Nothing about you", "message": "It uses a name or a birthday.", "tip": "Never use names, birthdays or ages."},
	"length": {"name": "At least 8 letters", "message": "That one was too short.", "tip": "Use at least 8 letters."},
	"mixed_case": {"name": "UPPER and lower case", "message": "It doesn't mix big and small letters.", "tip": "Use some CAPITALS and some small letters."},
	"number": {"name": "Has numbers", "message": "It has no numbers.", "tip": "Add a couple of random numbers."},
	"symbol": {"name": "Has symbols", "message": "It has no symbols.", "tip": "Add a symbol like # ! or ?"},
}
const COMMON: Array[String] = ["password", "123456", "12345678", "qwerty", "letmein", "iloveyou", "abc123", "admin", "welcome", "monkey", "dragon", "football", "sunshine"]
const NAMES: Array[String] = ["sam", "max", "emma", "alex", "mia", "leo", "lily", "jack", "zoe", "noah", "ava", "ben"]
const SYMBOLS := "!@#$%^&*?_-+=~.,:;"
const STRENGTH_NAMES: Array[String] = ["Very weak", "Weak", "Okay", "Strong", "Super strong"]


static func passes(password: String, rule: String) -> bool:
	var lower := password.to_lower()
	match rule:
		"common":
			var letters_only := ""
			for c in lower:
				if c >= "a" and c <= "z":
					letters_only += c
			for word: String in COMMON:
				if lower.contains(word) or letters_only == word:
					return false
			return true
		"personal":
			var year := RegEx.create_from_string("(19[5-9][0-9]|20[0-3][0-9])")
			if year.search(password) != null:
				return false
			var name_start := RegEx.create_from_string("^([a-z]+)[0-9]*$")
			var found := name_start.search(lower)
			return not (found != null and found.get_string(1) in NAMES)
		"length":
			return password.length() >= MIN_LENGTH
		"mixed_case":
			return password != password.to_lower() and password != password.to_upper()
		"number":
			return RegEx.create_from_string("[0-9]").search(password) != null
		"symbol":
			for c in password:
				if SYMBOLS.contains(c):
					return true
			return false
	push_warning("Unknown password rule: " + rule)
	return false


## Returns {ok, failed_rule, message, tip} for the given required rules.
static func check(password: String, required: Array) -> Dictionary:
	for rule: String in ORDER:
		if rule in required and not passes(password, rule):
			return {"ok": false, "failed_rule": rule, "message": RULES[rule].message, "tip": RULES[rule].tip}
	return {"ok": true, "failed_rule": "", "message": "", "tip": ""}


## 0 to 4: famous or personal passwords score 0; otherwise one point each for
## length, mixed case, numbers and symbols.
static func strength(password: String) -> int:
	if password.is_empty() or not passes(password, "common") or not passes(password, "personal"):
		return 0
	var score := 0
	for rule: String in ["length", "mixed_case", "number", "symbol"]:
		if passes(password, rule):
			score += 1
	return score


static func strength_name(score: int) -> String:
	return STRENGTH_NAMES[clampi(score, 0, STRENGTH_NAMES.size() - 1)]
