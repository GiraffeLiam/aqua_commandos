# res://boss/states/barrage_world_track_state.gd
# BarrageWorldTrackState — 固定世界點的追蹤射擊。
# 在世界格 (列2, 欄8)(置中偏上)生一個釋放點，釘在世界不跟 boss，朝玩家追打。
# 與 Follow 的差別：Follow 從 boss 錨點(跟 boss 移動)；這個從固定世界格。
class_name BarrageWorldTrackState
extends ReleaseSchedulerState


func _build_layout() -> Array:
	return [
		{
			"mode": SpawnMode.GLOBAL,
			"cell": Vector2i(2, 8),
			"delay": 0.0,
			"blocking": true,
			"params": {
				"target_mode": ReleasePoint.TargetMode.PLAYER,
				"lane_count": 1,
				"lane_step_degrees": 15.0,
				"wave_count": 3,
				"fire_interval": 0.35,
				"pre_delay": 0.4,
				"post_delay": 0.3,
			},
		},
	]
