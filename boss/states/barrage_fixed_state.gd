# res://boss/states/barrage_fixed_state.gd
# BarrageFixedState — 重現舊「固定射擊」：從 boss 錨點朝固定下方 5 道、8 波。
# 佈局寫死(B 方案)。不以玩家為目標。
class_name BarrageFixedState
extends ReleaseSchedulerState


func _build_layout() -> Array:
	return [
		{
			"mode": SpawnMode.LOCAL,
			"anchor": 3,
			"delay": 0.0,
			"blocking": true,
			"params": {
				"target_mode": ReleasePoint.TargetMode.FIXED_DOWN,
				"lane_count": 5,
				"lane_step_degrees": 30.0,
				"wave_count": 5,
				"fire_interval": 0.35,
				"pre_delay": 0.3,
				"post_delay": 0.3,
			},
		},
	]
