class_name SpritesheetVisual
extends Sprite2D

@export var spritesheet: Texture2D : set = set_spritesheet
@export_range(1, 64, 1) var sheet_hframes: int = 1 : set = set_sheet_hframes
@export_range(1, 64, 1) var sheet_vframes: int = 1 : set = set_sheet_vframes
@export var idle_frame: int = 0
@export var walk_start_frame: int = 0
@export var walk_frame_count: int = 1
@export var frame_duration: float = 0.12

var _frame_timer: float = 0.0
var _walk_frame_offset: int = 0


func _ready() -> void:
	_apply_spritesheet()


func _process(delta: float) -> void:
	if spritesheet == null:
		visible = false
		return

	visible = true
	if walk_frame_count <= 1:
		frame = clampi(idle_frame, 0, hframes * vframes - 1)
		return

	_frame_timer += delta
	if _frame_timer >= maxf(0.01, frame_duration):
		_frame_timer = 0.0
		_walk_frame_offset = (_walk_frame_offset + 1) % walk_frame_count

	var max_frame := hframes * vframes - 1
	frame = clampi(walk_start_frame + _walk_frame_offset, 0, max_frame)


func set_spritesheet(value: Texture2D) -> void:
	spritesheet = value
	_apply_spritesheet()


func set_sheet_hframes(value: int) -> void:
	sheet_hframes = maxi(1, value)
	_apply_spritesheet()


func set_sheet_vframes(value: int) -> void:
	sheet_vframes = maxi(1, value)
	_apply_spritesheet()


func _apply_spritesheet() -> void:
	texture = spritesheet
	hframes = maxi(1, sheet_hframes)
	vframes = maxi(1, sheet_vframes)
	visible = spritesheet != null
	if spritesheet == null:
		return
	frame = clampi(idle_frame, 0, hframes * vframes - 1)
