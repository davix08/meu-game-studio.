# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the cast -> bite -> tension-fight loop tense and rewarding with one thumb on a phone?
# Date: 2026-11-18
# Headless balance sim: godot --headless --path . -s sim.gd
extends SceneTree

static func run(strategy: String, sp: Dictionary, seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var f := Fight.new(sp["strength"], sp["surge"], rng)
	var t := 0.0
	var reeling := false
	while f.result == "" and t < 120.0:
		match strategy:
			"smart": # reel, back off when tension gets high, resume when it settles
				if f.tension > 0.85: reeling = false
				elif f.tension < 0.55: reeling = true
			"always": reeling = true
			"never": reeling = false
			"human": # smart, but only re-decides every 0.3 s (thumb reaction)
				if fmod(t, 0.3) < 1.0 / 60.0:
					if f.tension > 0.85: reeling = false
					elif f.tension < 0.55: reeling = true
			"lazy": # reacts late: lets go only at the limit
				if f.tension >= 1.0 and f.over > 0.2: reeling = false
				elif f.tension < 0.5: reeling = true
		f.step(1.0 / 60.0, reeling)
		t += 1.0 / 60.0
	return [f.result, t]

func _init() -> void:
	for strategy in ["smart", "human", "lazy", "always", "never"]:
		var line: String = String(strategy).rpad(7)
		for sp in Species.LIST:
			var c := {"caught": 0, "broke": 0, "escaped": 0, "": 0}
			var tt := 0.0
			for s in 200:
				var r := run(strategy, sp, s + 1)
				c[r[0]] += 1
				tt += r[1]
			line += " | %s c%3d b%3d e%3d %4.1fs" % [sp["id"].substr(0, 4), c["caught"], c["broke"], c["escaped"], tt / 200.0]
		print(line)
	quit()
