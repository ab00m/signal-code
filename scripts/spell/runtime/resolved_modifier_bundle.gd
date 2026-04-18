class_name ResolvedModifierBundle
extends RefCounted

var damage_mul: float = 1.0
var speed_mul: float = 1.0
var lifetime_mul: float = 1.0
var size_mul: float = 1.0
var add_spread_degrees: float = 0.0
var projectile_count_add: int = 0
var pierce_add: int = 0
var bounce_add: int = 0
var echo_delay: float = -1.0


static func from_modifiers(modifiers: Array[ModifierCardData]) -> ResolvedModifierBundle:
	var bundle := ResolvedModifierBundle.new()
	for modifier in modifiers:
		bundle.apply_modifier(modifier)
	return bundle


func apply_modifier(modifier: ModifierCardData) -> void:
	match modifier.modifier_type:
		ModifierCardData.ModifierType.DAMAGE_MULTIPLY:
			damage_mul *= modifier.value_float
		ModifierCardData.ModifierType.SPEED_MULTIPLY:
			speed_mul *= modifier.value_float
		ModifierCardData.ModifierType.LIFETIME_MULTIPLY:
			lifetime_mul *= modifier.value_float
		ModifierCardData.ModifierType.SIZE_MULTIPLY:
			size_mul *= modifier.value_float
		ModifierCardData.ModifierType.ADD_SPREAD:
			add_spread_degrees += modifier.value_float
		ModifierCardData.ModifierType.ADD_PROJECTILE_COUNT:
			projectile_count_add += modifier.value_int
		ModifierCardData.ModifierType.PIERCE_ADD:
			pierce_add += modifier.value_int
		ModifierCardData.ModifierType.BOUNCE_ADD:
			bounce_add += modifier.value_int
		ModifierCardData.ModifierType.MULTICAST:
			pass
		ModifierCardData.ModifierType.ECHO:
			echo_delay = maxf(0.0, modifier.value_float)
