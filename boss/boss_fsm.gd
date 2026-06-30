# res://boss/boss_fsm.gd
# BossFSM — 節點式狀態機 ＋ 決策中樞（兩者整合，無獨立 DecideState 節點）。
# 自動蒐集底下所有 BossState 子節點；動作結束 → decide_cooldown 決策冷卻 → 挑下一個。
# 決策兩層：① 條件式反應規則（片 1 留空，待玩家技能上線再掛）② 加權隨機。
class_name BossFSM
extends Node

@export var decide_cooldown: float = 0.3
@export var repeat_weight_factor: float = 0.3  # 上一個動作的權重打折（避免連續重複；1.0=關閉）

var _boss: Boss
var _states: Array[BossState] = []
var _current: BossState = null
var _decide_timer: float = 0.0
var _last_state: BossState = null   # 上一個執行過的動作（加權時打折）

func _ready() -> void:
	_boss = get_parent() as Boss
	if not _boss:
		push_error("BossFSM: 父節點不是 Boss，請確認場景結構")
		set_process(false)
		return

	for child in get_children():
		if child is BossState:
			var state := child as BossState
			state.setup(_boss)
			state.finished.connect(_on_state_finished)
			_states.append(state)

	if _states.is_empty():
		push_error("BossFSM: 底下沒有任何 BossState 子節點")
		set_process(false)
		return

	# 開場先進決策冷卻，冷卻結束後挑第一個動作
	_enter_decide()


# REPLACE func _process(delta)
func _process(delta: float) -> void:
	if _current:
		_current.update(delta)
		return

	# 決策冷卻中：以散步（細微 8 字漂移）取代僵直待機
	_boss.stroll_step(delta)
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
	_last_state = next   # 記錄這次選的，下次對它打折
	_current = next
	_current.enter()


# 第一層：條件式反應規則。片 1 留空。
# 玩家衝刺(4-3)、技能(6-2) 上線後，在這裡依「玩家剛做的事」回傳對應 State。
func _pick_reactive() -> BossState:
	return null


# 第二層：加權隨機
func _pick_weighted() -> BossState:
	# 上一個動作的權重打折（不那麼具體地避免連續重複）
	var total: float = 0.0
	for state in _states:
		total += _effective_weight(state)
	if total <= 0.0:
		return null

	var roll: float = randf() * total
	var acc: float = 0.0
	for state in _states:
		acc += _effective_weight(state)
		if roll <= acc:
			return state
	return _states.back()


# 有效權重 = state 自報權重（疲憊會動態變）× 是否為上一個動作的折扣
func _effective_weight(state: BossState) -> float:
	var w: float = maxf(state.get_weight(), 0.0)
	if state == _last_state:
		w *= repeat_weight_factor
	return w
