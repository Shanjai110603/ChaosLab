## Score System.
## Calculates final scores, star ratings, par efficiency bonus, and coin rewards.
class_name ScoreSystem
extends RefCounted

## Points awarded per unused inventory item.
const PAR_BONUS_PER_ITEM: int = 250

## Coin rewards.
const COINS_PER_STAR: int = 50
const PERFECT_BONUS: int = 100
const CHAIN_BONUS_THRESHOLD: int = 8
const CHAIN_BONUS_COINS: int = 75


## Calculate the star rating (1-3) based on score and level targets.
static func calculate_stars(score: int, score_targets: Array) -> int:
	if score_targets.size() < 3:
		if score >= 500:
			return 3
		elif score >= 200:
			return 2
		elif score > 0:
			return 1
		return 0

	if score >= score_targets[2]:
		return 3
	elif score >= score_targets[1]:
		return 2
	elif score >= score_targets[0]:
		return 1
	return 0


## Calculate coin reward based on stars and chain performance.
static func calculate_coins(stars: int, chain_count: int) -> int:
	var coins: int = stars * COINS_PER_STAR
	if stars >= 3:
		coins += PERFECT_BONUS
	if chain_count >= CHAIN_BONUS_THRESHOLD:
		coins += CHAIN_BONUS_COINS
	return coins


## Evaluate a level completion with detailed breakdown.
static func evaluate_level(
	chain_result: Dictionary,
	total_targets: int,
	score_targets: Array,
	unused_items: int = 0
) -> Dictionary:
	var raw_score: int = chain_result.get("total_score", 0)
	var chain: int = chain_result.get("chain_count", 0)
	var targets_hit: int = chain_result.get("targets_hit", 0)

	var is_complete: bool = targets_hit >= total_targets and total_targets > 0

	# Calculate par efficiency bonus
	var par_bonus: int = 0
	if is_complete and unused_items > 0:
		par_bonus = unused_items * PAR_BONUS_PER_ITEM

	var final_score: int = raw_score + par_bonus

	var stars: int = 0
	if is_complete:
		stars = calculate_stars(final_score, score_targets)
		stars = maxi(stars, 1)  # At least 1 star for clearing the objectives

	var coins: int = 0
	if is_complete:
		coins = calculate_coins(stars, chain)

	var label: String = ""
	if not is_complete:
		label = "INCOMPLETE"
	elif stars >= 3:
		label = "PERFECT EXPERIMENT!"
	elif stars >= 2:
		label = "EXCELLENT!"
	elif stars >= 1:
		label = "EXPERIMENT COMPLETE!"

	var chaos_rating: bool = chain >= 12

	return {
		"complete": is_complete,
		"score": final_score,
		"raw_score": raw_score,
		"par_bonus": par_bonus,
		"unused_items": unused_items,
		"chain": chain,
		"stars": stars,
		"coins": coins,
		"targets_hit": targets_hit,
		"total_targets": total_targets,
		"label": label,
		"chaos_rating": chaos_rating,
		"chain_label": chain_result.get("label", ""),
	}
