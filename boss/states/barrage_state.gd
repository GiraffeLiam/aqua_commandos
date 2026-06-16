# res://boss/states/barrage_state.gd
# BarrageState（#2 跟隨射擊 ＋ #3 固定射擊，合併的參數化彈幕）。
# 同一份腳本，靠 @export 配出不同行為：
#   跟隨：target_mode = PLAYER、lane_count = 3、lane_step = 15
#   固定：target_mode = FIXED_DOWN、lane_count = 5
# 在「時間內」依 fire_interval 射 wave_count 波，每波是 lane_count 道扇形彈。
class_name BarrageState
extends BossState

enum TargetMode { PLAYER, FIXED_DOWN }

@export var target_mode: TargetMode = TargetMode.PLAYER
@export var lane_count: int = 3
@export var lane_step_degrees: float = 15.0
@export var wave_count: int = 8
@export var fire_interval: float = 0.35

var _waves_left: int = 0
var _timer: float = 0.0


func enter() -> void:
	_waves_left = wave_count
	_timer = 0.0  # 進場即射第一波


func update(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return

	_fire_wave()
	_waves_left -= 1
	if _waves_left <= 0:
		finished.emit()
		return
	_timer = fire_interval


func _fire_wave() -> void:
	var base_angle: float = _get_base_direction().angle()
	var half: float = float(lane_count - 1) / 2.0
	for i in lane_count:
		var offset_deg: float = (float(i) - half) * lane_step_degrees
		var angle: float = base_angle + deg_to_rad(offset_deg)
		boss.fire_projectile(Vector2.RIGHT.rotated(angle))


func _get_base_direction() -> Vector2:
	if target_mode == TargetMode.FIXED_DOWN:
		return Vector2.DOWN
	var player := boss.get_player()
	if not player:
		return Vector2.DOWN
	return (player.global_position - boss.get_muzzle_position()).normalized()
