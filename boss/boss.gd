# res://boss/boss.gd
# Boss — Boss 實體根節點，FSM 的「上下文」。
# 提供座標 / 玩家查詢 / 發射 helper 給各 State 呼叫；本身不決定要做哪個動作。
# 動作的決策與執行在 BossFSM ＋ 各 BossState（節點式狀態機）。
# 階段 3 片 1：移除舊「笨發射」，改由 FSM 驅動。
class_name Boss
extends Node2D

@export var projectile_scene: PackedScene

@onready var _muzzle: Marker2D = $Muzzle


# ── 上下文 API：給 State 使用 ──────────────────────────────
func get_muzzle_position() -> Vector2:
	return _muzzle.global_position if _muzzle else global_position


func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


# 朝指定方向從槍口發一發 Projectile（方向發射瞬間鎖定，不追蹤）
func fire_projectile(direction: Vector2) -> void:
	if not projectile_scene:
		push_error("Boss: projectile_scene 未設定，請在 Inspector 拖入 projectile.tscn")
		return
	var projectile := projectile_scene.instantiate() as Projectile
	projectile.global_position = get_muzzle_position()
	projectile.init(direction)
	get_tree().current_scene.add_child(projectile)
