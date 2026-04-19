class_name UpgradeOptionConfig
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export var rarity: int = 0
@export var weight: float = 1.0

@export var category: StringName
@export var modifier_type: StringName = &"stat_modifier"
@export var target_key: StringName
@export var operation: StringName = &"add_percent"
@export var value: float = 0.0

@export var max_pick_count: int = 99
@export var exclusive_group: StringName
@export var required_tags: Array[StringName] = []
@export var blocked_tags: Array[StringName] = []
@export var granted_tags: Array[StringName] = []
