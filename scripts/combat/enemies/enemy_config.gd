class_name EnemyConfig
extends Resource

@export var enemy_id: StringName
@export var display_name: String = ""
@export var enemy_type: int = 0

@export var max_hp: float = 50.0
@export var move_speed: float = 120.0

@export var collision_radius: float = 16.0
@export var separation_radius: float = 18.0
@export var separation_strength: float = 80.0

@export var knockback_multiplier: float = 1.0
@export var hit_flash_duration: float = 0.08
@export var hit_flash_intensity: float = 1.0

@export var guaranteed_xp_drop: int = 1
@export_range(0.0, 1.0, 0.01) var gold_drop_chance: float = 0.25
@export var gold_drop_amount_min: int = 1
@export var gold_drop_amount_max: int = 3

@export var body_scene: PackedScene
@export var body_color: Color = Color(0.95, 0.22, 0.28, 1.0)
@export var outline_color: Color = Color(1.0, 1.0, 1.0, 0.55)

@export var boss_reset_anchor_path: NodePath
@export var spawn_weight: float = 1.0
