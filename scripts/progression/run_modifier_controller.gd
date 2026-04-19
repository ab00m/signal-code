class_name RunModifierController
extends Node

signal modifier_changed(target_key: StringName)

const DAMAGE_MULTIPLIER := &"damage_multiplier"
const CAST_RATE_MULTIPLIER := &"cast_rate_multiplier"
const GOLD_DROP_CHANCE := &"gold_drop_chance"
const EXP_GAIN_MULTIPLIER := &"exp_gain_multiplier"
const KNOCKBACK_MULTIPLIER := &"knockback_multiplier"
const PROJECTILE_SPEED_MULTIPLIER := &"projectile_speed_multiplier"
const AOE_RADIUS_MULTIPLIER := &"aoe_radius_multiplier"
const MAX_HP_BONUS := &"max_hp_bonus"

var additive_percent := {
	DAMAGE_MULTIPLIER: 0.0,
	CAST_RATE_MULTIPLIER: 0.0,
	GOLD_DROP_CHANCE: 0.0,
	EXP_GAIN_MULTIPLIER: 0.0,
	KNOCKBACK_MULTIPLIER: 0.0,
	PROJECTILE_SPEED_MULTIPLIER: 0.0,
	AOE_RADIUS_MULTIPLIER: 0.0,
}

var flat_values := {
	MAX_HP_BONUS: 0.0,
}


func reset_modifiers() -> void:
	for key in additive_percent.keys():
		additive_percent[key] = 0.0
	for key in flat_values.keys():
		flat_values[key] = 0.0
	modifier_changed.emit(&"")


func apply_stat_modifier(option: UpgradeOptionConfig) -> void:
	if option == null:
		return

	match option.operation:
		&"add_flat":
			flat_values[option.target_key] = flat_values.get(option.target_key, 0.0) + option.value
		&"add_percent":
			additive_percent[option.target_key] = additive_percent.get(option.target_key, 0.0) + option.value
		&"mul":
			additive_percent[option.target_key] = additive_percent.get(option.target_key, 0.0) + option.value
		_:
			push_warning("Unknown upgrade operation: %s" % option.operation)
			return

	modifier_changed.emit(option.target_key)


func get_damage_multiplier() -> float:
	return 1.0 + additive_percent.get(DAMAGE_MULTIPLIER, 0.0)


func get_cast_rate_multiplier() -> float:
	return maxf(0.01, 1.0 + additive_percent.get(CAST_RATE_MULTIPLIER, 0.0))


func get_gold_drop_chance_bonus() -> float:
	return additive_percent.get(GOLD_DROP_CHANCE, 0.0)


func get_exp_gain_multiplier() -> float:
	return maxf(0.0, 1.0 + additive_percent.get(EXP_GAIN_MULTIPLIER, 0.0))


func get_knockback_multiplier() -> float:
	return 1.0 + additive_percent.get(KNOCKBACK_MULTIPLIER, 0.0)


func get_projectile_speed_multiplier() -> float:
	return 1.0 + additive_percent.get(PROJECTILE_SPEED_MULTIPLIER, 0.0)


func get_aoe_radius_multiplier() -> float:
	return 1.0 + additive_percent.get(AOE_RADIUS_MULTIPLIER, 0.0)


func get_max_hp_bonus() -> int:
	return maxi(0, roundi(flat_values.get(MAX_HP_BONUS, 0.0)))
