# res://camera/shake_camera.gd
# ShakeCamera — 監聽 screen_shake_requested，用隨機 offset 抖動相機，強度隨時間衰減。
class_name ShakeCamera
extends Camera2D

var _duration: float = 0.0
var _time_left: float = 0.0
var _strength: float = 0.0


func _ready() -> void:
	event_bus.screen_shake_requested.connect(_on_screen_shake_requested)


func _on_screen_shake_requested(duration: float, strength: float) -> void:
	_duration = duration
	_time_left = duration
	_strength = strength


func _process(_delta: float) -> void:
	if _time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_time_left -= _delta
	var current_strength: float = _strength * (_time_left / _duration)
	offset = Vector2(
		randf_range(-current_strength, current_strength),
		randf_range(-current_strength, current_strength)
	)
	if _time_left <= 0.0:
		offset = Vector2.ZERO
