# res://camera/game_camera.gd
# GameCamera — 放在 World 上的相機。兩種模式：
#   跟隨（gameplay）：每幀對齊 follow_target，玩家水平置中、垂直偏下（底部留 bottom_margin）。
#   自由（演出）：關掉跟隨，由外部（進場動畫、環境平移、cutscene）控制 position。
# 兩種模式都吃 screen_shake_requested（offset 抖動，獨立於位置）。
class_name GameCamera
extends Camera2D

@export var follow_target: Node2D
@export var follow_enabled: bool = true
@export var bottom_margin: float = 100.0

var _duration: float = 0.0
var _time_left: float = 0.0
var _strength: float = 0.0


func _ready() -> void:
	event_bus.screen_shake_requested.connect(_on_screen_shake_requested)


func _process(_delta: float) -> void:
	if follow_enabled and follow_target:
		# 水平置中；垂直把相機中心抬到玩家上方，讓玩家落在下半部、距底部約 bottom_margin
		var visible_half_h: float = get_viewport_rect().size.y * 0.5 / zoom.y
		var y_lead: float = visible_half_h - bottom_margin
		global_position = Vector2(
			follow_target.global_position.x,
			follow_target.global_position.y - y_lead
		)
	_update_shake(_delta)


func _update_shake(delta: float) -> void:
	if _time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_time_left -= delta
	var current_strength: float = _strength * (_time_left / _duration)
	offset = Vector2(
		randf_range(-current_strength, current_strength),
		randf_range(-current_strength, current_strength)
	)
	if _time_left <= 0.0:
		offset = Vector2.ZERO


func _on_screen_shake_requested(duration: float, strength: float) -> void:
	_duration = duration
	_time_left = duration
	_strength = strength


# 演出用：外部切換跟隨／自由，以及換跟隨對象
func set_follow(enabled: bool) -> void:
	follow_enabled = enabled


func set_follow_target(target: Node2D) -> void:
	follow_target = target
