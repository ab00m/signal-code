class_name ActionCardData
extends SpellCardData

@export var damage: float = 5.0
@export var knockback_force: float = 120.0
@export var speed: float = 420.0
@export var lifetime: float = 1.2
@export var spell_size: float = 1.0
@export var projectile_count: int = 1
@export var spread_degrees: float = 0.0
@export var pierce: int = 0
@export var bounce: int = 0
@export var explosion_radius: float = 0.0
@export var projectile_color: Color = Color(0.45, 0.8, 1.0, 1.0)
@export var on_hit_effects: Array[StringName] = []
