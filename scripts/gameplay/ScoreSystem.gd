## Score System.
## Calculates final scores, star ratings, and coin rewards.
class_name ScoreSystem
extends RefCounted

## Star rating thresholds (percentage of max possible score).
const STAR_THRESHOLDS: Array[float] = [0.0, 0.3, 0.6, 0.85]

## Base coin reward per star earned.
const COINS_PER_STAR: int = 50
## Bonus coins for a perfect (3-star) completion.
const PERFECT_BONUS: int = 100
## Bonus coins for chain of 10+.
const CHAIN_BONUS_THRESHOLD: int = 10
const CHAIN_BONUS_COINS: int = 50


## Calculate the star rating (1-3) based on score and level targets.
static func calculate_stars(score: int, score_targets: Array) -> int:
	# score_targets: [1_star_min, 2_star_min, 3_star_min]
	if score_targets.size() < 3:
		# Default thresholds if not specified
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

	# Perfect bonus
	if stars >= 3:
		coins += PERFECT_BONUS

	# Chain bonus
	if chain_count >= CHAIN_BONUS_THRESHOLD:
		coins += CHAIN_BONUS_COINS

	return coins


## Evaluate a level completion. Returns a result dictionary.
static func evaluate_level(
	chain_result: Dictionary,
	total_targets: int,
	score_targets: Array,
) -> Dictionary:
	var score: int = chain_result.get("total_score", 0)
	var chain: int = chain_result.get("chain_count", 0)
	var targets_hit: int = chain_result.get("targets_hit", 0)

	# Check completion
	var is_complete: bool = targets_hit >= total_targets

	# Calculate stars (only if completed)
	var stars: int = 0
	if is_complete:
		stars = calculate_stars(score, score_targets)
		stars = maxi(stars, 1)  # At least 1 star for completion

	# Calculate coins
	var coins: int = 0
	if is_complete:
		coins = calculate_coins(stars, chain)

	# Determine result label
	var label: String = ""
	if not is_complete:
		label = "INCOMPLETE"
	elif stars >= 3:
		label = "PERFECT!"
	elif stars >= 2:
		label = "GREAT!"
	elif stars >= 1:
		label = "COMPLETE!"

	# Check for chaos rating (exceptional chain)
	var chaos_rating: bool = chain >= 15

	return {
		"complete": is_complete,
		"score": score,
		"chain": chain,
		"stars": stars,
		"coins": coins,
		"targets_hit": targets_hit,
		"total_targets": total_targets,
		"label": label,
		"chaos_rating": chaos_rating,
		"chain_label": chain_result.get("label", ""),
	}
