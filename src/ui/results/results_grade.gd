class_name ResultsGrade
extends RefCounted
## Turns fight statistics into a letter grade. Pure logic, unit-tested.
##
## Score (0..100): time 40 pts, health 30 pts, parries 15 pts, super cards 15 pts.

const GRADES := ["D", "C", "B", "A", "S"]
const GRADE_THRESHOLDS := [0.0, 40.0, 60.0, 80.0, 95.0]


## Returns a score 0..100. [param par_time] is the "full marks" time in seconds.
static func score(time: float, health: int, max_health: int, parries: int, super_cards: int,
		par_time: float = 120.0, par_parries: int = 3) -> float:
	var time_pts: float = 40.0 * clampf(par_time / maxf(time, 0.001), 0.0, 1.0)
	var hp_pts: float = 30.0 * clampf(float(health) / float(maxi(max_health, 1)), 0.0, 1.0)
	var parry_pts: float = 15.0 * clampf(float(parries) / float(maxi(par_parries, 1)), 0.0, 1.0)
	var super_pts: float = 15.0 * clampf(float(super_cards) / 5.0, 0.0, 1.0)
	return time_pts + hp_pts + parry_pts + super_pts


## Letter for a 0..100 score.
static func letter(value: float) -> String:
	var result: String = GRADES[0]
	for i: int in GRADES.size():
		if value >= GRADE_THRESHOLDS[i]:
			result = GRADES[i]
	return result
