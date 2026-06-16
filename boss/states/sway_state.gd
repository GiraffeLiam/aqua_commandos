# res://boss/states/sway_state.gd
# SwayState（#1 晃動）— 製造閃避感。向一側快速移動 move_distance，再移回原位。
# ease-in-out（先加速後減速）；50% 機率改成先右後左。
# 用 Tween 跑位移，設 physics 模式配合 Body(AnimatableBody2D) 推開玩家。
class_name SwayState
extends BossState

@export var move_distance: float = 150.0
@export var half_duration: float = 0.5

var _tween: Tween = null


func enter() -> void:
	var dir: float = -1.0 if randf() < 0.5 else 1.0  # 50% 先左 / 先右
	var start: Vector2 = boss.position
	var offset := Vector2(move_distance * dir, 0.0)

	_tween = boss.create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(boss, "position", start + offset, half_duration)
	_tween.tween_property(boss, "position", start, half_duration)
	_tween.finished.connect(_on_tween_finished)


func _on_tween_finished() -> void:
	_tween = null
	finished.emit()


func exit() -> void:
	# 被中斷時殺掉殘留 Tween（片 1 不會發生，先備好）
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
