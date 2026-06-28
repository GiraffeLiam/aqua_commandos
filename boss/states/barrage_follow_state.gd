# res://boss/states/barrage_follow_state.gd
# BarrageFollowState — 重現舊「跟隨射擊」：從 boss 錨點朝玩家 3 道(±15°)、8 波。
# 佈局寫死(B 方案)，數值要調就改這裡。一個 state 可串多步，往 layout 加項即可。
class_name BarrageFollowState
extends ReleaseSchedulerState


func _build_layout() -> Array:
	return [
		{
			"mode": SpawnMode.LOCAL,
			"anchor": 0,
			"delay": 0.0,
			"blocking": true,
			"params": {
				"target_mode": ReleasePoint.TargetMode.PLAYER,
				"lane_count": 3,
				"lane_step_degrees": 15.0,
				"wave_count": 3,
				"fire_interval": 0.5,
				"pre_delay": 0.3,
				"post_delay": 0.3,
			},
		},
	]
