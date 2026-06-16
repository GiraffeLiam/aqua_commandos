# res://boss/boss_fsm.gd
# BossFSM — 節點式狀態機 ＋ 決策中樞（兩者整合，無獨立 DecideState 節點）。
# 自動蒐集底下所有 BossState 子節點；動作結束 → decide_cooldown 決策冷卻 → 挑下一個。
# 決策兩層：① 條件式反應規則（片 1 留空，待玩家技能上線再掛）② 加權隨機。
class_name BossFSM
extends Node

@export var decide_cooldown: float = 0.3

var _boss: Boss
var _states: Array[BossState] = []
var _current: BossState = null
var _decide_timer: float = 0.0


func _ready() -> void:
	_boss = get_parent() as Boss
	if not _boss:
		push_error("BossFSM: 父節點不是 Boss，請確認場景結構")
		return

	for child in get_children():
		if child is BossState:
			var state := child as BossState
			state.setup(_boss)
			state.finished.connect(_on_state_finished)
			_states.append(state)

	if _states.is_empty():
		push_error("BossFSM: 底下沒有任何 BossState 子節點")
		return

	# 開場先進決策冷卻，冷卻結束後挑第一個動作
	_enter_decide()


func _process(delta: float) -> void:
	if _current:
		_current.update(delta)
		return

	# 決策冷卻中
	_decide_timer -= delta
	if _decide_timer <= 0.0:
		_decide_next()


func _on_state_finished() -> void:
	if _current:
		_current.exit()
	_enter_decide()


func _enter_decide() -> void:
	_current = null
	_decide_timer = decide_cooldown


func _decide_next() -> void:
	var next := _pick_reactive()
	if not next:
		next = _pick_weighted()
	if not next:
		# 沒有可選動作，再等一個冷卻
		_decide_timer = decide_cooldown
		return
	_current = next
	_current.enter()


# 第一層：條件式反應規則。片 1 留空。
# 玩家衝刺(4-3)、技能(6-2) 上線後，在這裡依「玩家剛做的事」回傳對應 State。
func _pick_reactive() -> BossState:
	return null


# 第二層：加權隨機
func _pick_weighted() -> BossState:
	var total: float = 0.0
	for state in _states:
		total += maxf(state.get_weight(), 0.0)
	if total <= 0.0:
		return null

	var roll: float = randf() * total
	var acc: float = 0.0
	for state in _states:
		acc += maxf(state.get_weight(), 0.0)
		if roll <= acc:
			return state
	return _states.back()
