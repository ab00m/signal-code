class_name CastState
extends RefCounted

var wand: WandRuntime
var caster: Node
var origin: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT

var damage_mul: float = 1.0
var speed_mul: float = 1.0
var lifetime_mul: float = 1.0
var size_mul: float = 1.0
var spread_bonus_degrees: float = 0.0
var extra_projectiles: int = 0
var pierce_bonus: int = 0
var bounce_bonus: int = 0

var trigger_payload: Array[SpellCardData] = []
var flags: Dictionary = {}
