class_name WandData
extends Resource

@export var deck: Array[SpellCardData] = []
@export_range(1, 8, 1) var draws_per_cast: int = 1
@export var cast_delay: float = 0.12
@export var recharge_time: float = 0.25
@export var mana_max: float = 100.0
@export var mana_recharge_per_second: float = 0.0
@export var shuffle_each_cycle: bool = false
