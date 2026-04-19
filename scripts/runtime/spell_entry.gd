class_name SpellEntry
extends Resource

@export var instance_id: String = ""
@export var spell_id: StringName = &""
@export var source: StringName = &"debug"
@export var acquired_wave: int = 0
@export var tags: Array[StringName] = []
@export var stack_count: int = 1


static func create(spell_id_value: StringName, source_value: StringName = &"debug", wave: int = 0) -> SpellEntry:
	var entry := SpellEntry.new()
	entry.instance_id = "%s_%d_%d" % [String(spell_id_value), Time.get_ticks_usec(), randi()]
	entry.spell_id = spell_id_value
	entry.source = source_value
	entry.acquired_wave = wave
	entry.stack_count = 1
	return entry
