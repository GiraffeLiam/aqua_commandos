# res://boss/states/release_scheduler_state.gd
# ReleaseSchedulerState — 「投射物動作」的調度基底。繼承 BossState。
# 不自己發射，而是依「佈局」生出多個 ReleasePoint，由釋放點各自跑射擊週期。
#
# blocking 機制（底層一次到位，未來只加外掛不改底層）：
#   用「待完成計數器」_pending。生成項標 blocking=true → 計入計數器、連 finished；
#   blocking=false → 不計入（fire-and-forget，放完不管）。
#   計數器歸 0 才 emit finished → FSM 才換下一個 state。
#   同一動作可混合：要等的計入、不等的不計入。全等 / 全不等 / 混合 三態皆涵蓋。
#
# 子類只需覆寫 _build_layout()：回傳一串「生成項」，定義在哪、何時、生什麼釋放點。
# 佈局寫死（程式碼），單顆釋放點的彈幕數值走該釋放點場景的 @export。
class_name ReleaseSchedulerState
extends BossState

# 釋放點場景（佔位圓球版；之後換含 sprite 的釋放點場景）
@export var release_point_scene: PackedScene

var _pending: int = 0
var _spawn_tweens: Array = []   # 延遲生成用的計時，exit 時清


# 生成項格式（Dictionary）：
#   "mode"     : ReleasePoint 掛 LOCAL(boss下) 或 GLOBAL(世界格)。見下方 enum。
#   "anchor"   : LOCAL 用 — boss 錨點索引(int)
#   "cell"     : GLOBAL 用 — 世界格座標 Vector2i(列, 欄)
#   "delay"    : 從進入此 state 起算，延遲多久生這個釋放點(float)
#   "blocking" : 是否計入待完成計數器(bool)
enum SpawnMode { LOCAL, GLOBAL }


# 子類覆寫：回傳生成項陣列（佈局寫死在這）
func _build_layout() -> Array:
	return []


func enter() -> void:
	_pending = 0
	_spawn_tweens.clear()

	var layout: Array = _build_layout()
	if layout.is_empty():
		# 沒有任何釋放點，直接結束
		finished.emit()
		return

	for item in layout:
		var delay: float = item.get("delay", 0.0)
		if delay <= 0.0:
			_spawn_one(item)
		else:
			# 用 boss 的 tween 排延遲生成（避免自己管一堆計時器）
			var tw := boss.create_tween()
			tw.tween_interval(delay)
			tw.tween_callback(_spawn_one.bind(item))
			_spawn_tweens.append(tw)
			
func _spawn_one(item: Dictionary) -> void:
	if not release_point_scene:
		push_error("ReleaseSchedulerState: release_point_scene 未設定")
		return

	var rp := release_point_scene.instantiate() as ReleasePoint

	# 注入彈幕參數（B 方案）。必須在 add_child 觸發 _ready 之前。
	if item.has("params"):
		rp.apply_params(item["params"])

	var mode: SpawnMode = item.get("mode", SpawnMode.GLOBAL)

	if mode == SpawnMode.LOCAL:
		# 掛 boss 下，隨 boss(及未來動畫錨點)移動
		var anchor_idx: int = item.get("anchor", 0)
		boss.add_child(rp)
		rp.position = boss.get_anchor_local_position(anchor_idx)
	else:
		# 掛世界，固定在格子中心(生成當下換算，之後不跟隨)
		var cell: Vector2i = item.get("cell", Vector2i.ZERO)
		get_tree().current_scene.add_child(rp)
		rp.global_position = boss.get_grid_world_position(cell)

	var blocking: bool = item.get("blocking", true)
	if blocking:
		_pending += 1
		rp.finished.connect(_on_release_finished)
	# 非阻塞：不計入、不連 finished，釋放點自生自滅

func _on_release_finished() -> void:
	_pending -= 1
	if _pending <= 0:
		finished.emit()


func exit() -> void:
	# 被中斷：清掉還沒觸發的延遲生成計時（已生成的釋放點讓它自己跑完/自刪）
	for tw in _spawn_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_spawn_tweens.clear()
