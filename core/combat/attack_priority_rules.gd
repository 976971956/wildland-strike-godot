class_name AttackPriorityRules
extends RefCounted

enum Outcome {
	UNCONTESTED,
	WIN,
	TRADE,
	LOSE,
}


static func resolve(incoming_attack: Resource, defender: Node) -> int:
	if incoming_attack == null or not is_instance_valid(defender):
		return Outcome.UNCONTESTED
	if not _has_unresolved_attack(defender):
		return Outcome.UNCONTESTED
	var defender_attack: Resource = defender.current_attack
	if incoming_attack.priority > defender_attack.priority:
		return Outcome.WIN
	if incoming_attack.priority < defender_attack.priority:
		return Outcome.LOSE
	return Outcome.TRADE


static func interrupts_defender(outcome: int) -> bool:
	return outcome == Outcome.WIN


static func allows_hit(outcome: int) -> bool:
	return outcome != Outcome.LOSE


static func _has_unresolved_attack(defender: Node) -> bool:
	return (
		defender.current_attack != null
		and defender.attack_timer > 0.0
		and not defender.attack_hit_done
	)
