class_name TriggerActionCardData
extends ActionCardData

enum TriggerMode {
	ON_HIT,
	ON_TIMER,
}

@export var trigger_mode: TriggerMode = TriggerMode.ON_HIT
@export var timer_delay: float = 0.35
@export_range(0, 4, 1) var payload_action_count: int = 1
