extends RefCounted
## Teaching rules for fake examples, not an estimate of real cracking time.
static func score(password: String, stage: int) -> Dictionary:
	var letters: int = 0
	var lower: bool = false
	var upper: bool = false
	var number: bool = false
	var symbol: bool = false
	for ch in password:
		if ch >= "a" and ch <= "z":
			lower = true
			letters += 1
		elif ch >= "A" and ch <= "Z":
			upper = true
			letters += 1
		elif ch >= "0" and ch <= "9": number = true
		else: symbol = true
	var failed: Array[String] = []
	if letters < 8: failed.append("length")
	if "password" in password.to_lower(): failed.append("common")
	if "alex" in password.to_lower() or "2016" in password: failed.append("personal")
	if stage >= 2 and not (lower and upper): failed.append("case")
	if stage >= 3 and not (number and symbol): failed.append("extras")
	var tips := {"length":"That is too short. Choose at least 8 letters.", "common":"That is a common guess. Pick an unusual made-up phrase.", "personal":"Names and birthdays can be guessed. Use make-believe words.", "case":"Keep both small and CAPITAL letters.", "extras":"Keep the letters, then add a number AND a symbol."}
	return {"valid":failed.is_empty(), "failed":failed, "score":int(letters >= 8) + int(lower and upper) + int(number and symbol), "explanation":"" if failed.is_empty() else tips[failed[0]]}
