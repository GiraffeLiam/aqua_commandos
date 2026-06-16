# res://boss/states/boss_state.gd
# BossState — 所有 Boss 動作狀態的基底。封裝生命週期介面與共用脈絡。
# 每個動作 = 一個繼承此類的 Node，掛在 BossFSM 底下。
# 動作結束時 emit finished，BossFSM 收到後進決策冷卻、再挑下一個。
class_name BossState
extends Node

# 動作完成通知 FSM
signal finished

# 加權隨機用的權重；疲憊之類要隨狀態縮放的，覆寫 get_weight()
@export var weight: float = 1.0

# FSM 注入的 Boss 上下文
var boss: Boss


func setup(boss_ref: Boss) -> void:
	boss = boss_ref


# 進入此動作（一次性初始化）
func enter() -> void:
	pass


# 每幀更新（由 FSM 驅動）
func update(_delta: float) -> void:
	pass


# 離開此動作（清理；被中斷時也會呼叫）
func exit() -> void:
	pass


# 加權隨機的有效權重，預設回傳 weight
func get_weight() -> float:
	return weight
