class_name CounterHitRules
extends RefCounted


static func is_counterable(target: Node) -> bool:
	if not is_instance_valid(target) or target.current_attack == null:
		return false
	return (
		target.attack_timer > target.current_attack.hit_trigger_remaining
		and not target.attack_hit_done
		and target.hurt_timer <= 0.0
	)


static func damage_for(attack: AttackFrameData, counter_hit: bool) -> int:
	return attack.damage + (attack.counter_hit_damage_bonus if counter_hit else 0)


static func knockback_for(attack: AttackFrameData, facing: int, counter_hit: bool) -> Vector2:
	var scale_factor := attack.counter_hit_knockback_scale if counter_hit else 1.0
	return Vector2(facing * attack.knockback.x, attack.knockback.y) * scale_factor


static func launch_for(attack: AttackFrameData, counter_hit: bool) -> bool:
	return attack.launch or (counter_hit and attack.counter_hit_launch)


static func stun_bonus_for(attack: AttackFrameData, counter_hit: bool) -> float:
	return attack.counter_hit_stun_bonus if counter_hit else 0.0
