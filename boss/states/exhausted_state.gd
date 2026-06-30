# res://boss/states/exhausted_state.gd
# ExhaustedState（#8 疲憊）— 原地不動 rest_time 秒（壓力釋放閥）。
# 權重動態：= (當前 dress 破壞度 − 上次疲憊時破壞度) × scale，夾在 0 ~ max_weight。
#   dress 完整 → 差值 0 → 權重 0 → 加權池裡幾乎不被選。
#   破壞越多 → 權重越高 → 跟其他動作同級競爭。
#   觸發疲憊後記錄當下破壞度，差值歸零 → 權重掉回 0 → 要再破壞才回升。
# 「上次疲憊破壞度」記在自己身上（疲憊的邏輯都關在這個 state）。
# rest_time 內完全不動（FSM 在 state 執行期間不跑散步），之後由 AnimationPlayer 接動畫。
class_name ExhaustedState
extends BossState

@export var rest_time: float = 3.0
@export var scale: float = 30.0       # 破壞度差值(0~1) 放大成權重數值的倍率
@export var max_weight: float = 15.0  # 權重上限（夾住）

# 上次疲憊時的 dress 破壞度（0~1）；初始 0 = 開場起就以「從 0 累積」計算
var _last_destruction_pct: float = 0.0
var _timer: float = 0.0


# 動態權重：自上次疲憊以來「新增的」破壞度 × scale，夾 0~max_weight。
# 全程 float，不轉 int（破壞度是 0~1 比例，轉 int 會歸零）。
func get_weight() -> float:
	var delta_pct: float = boss.get_destruction_pct() - _last_destruction_pct
	return clampf(delta_pct * scale, 0.0, max_weight)


func enter() -> void:
	# 記錄當下破壞度 → 下次 get_weight 的差值從這裡重新累積（清零效果）
	_last_destruction_pct = boss.get_destruction_pct()
	_timer = rest_time
	# rest_time 內完全不動：不設 position、不 tween、不散步
	# （未來 AnimationPlayer 的疲憊動畫在此 play）


func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		finished.emit()


func exit() -> void:
	# 被中斷時無殘留可清（沒開 tween、沒改 position）
	pass
