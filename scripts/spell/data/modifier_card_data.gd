class_name ModifierCardData
extends SpellCardData

enum ModifierType {
	DAMAGE_MULTIPLY,
	SPEED_MULTIPLY,
	LIFETIME_MULTIPLY,
	SIZE_MULTIPLY,
	ADD_SPREAD,
	ADD_PROJECTILE_COUNT,
	PIERCE_ADD,
	BOUNCE_ADD,
	MULTICAST,
	ECHO,
}

@export var modifier_type: ModifierType = ModifierType.DAMAGE_MULTIPLY
@export var value_float: float = 1.0
@export var value_int: int = 0
