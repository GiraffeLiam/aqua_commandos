# res://boss/boss.gd
# Boss — Boss 實體根節點，FSM 的「上下文」。
# 提供座標 / 玩家查詢 / 散步移動 / 殘影控制 / 釋放點定位 給各處呼叫；本身不決定要做哪個動作。
# 動作的決策與執行在 BossFSM ＋ 各 BossState（節點式狀態機）。
# 階段 3 片 1：射擊改由獨立 ReleasePoint 負責，boss 不再自己發射。
class_name Boss
extends Node2D

# ── 散步參數（決策冷卻期間的細微 8 字漂移）─────────────────
@export var stroll_amp_x: float = 24.0
@export var stroll_amp_y: float = 10.0
@export var stroll_speed: float = 1.5

# ── 世界格參數（16×9 等距網格，以 boss 出生點為原點）─────────
# 格子總尺寸 = grid_screen_size；單格 = 該尺寸 / (16, 9)。
# 格座標 Vector2i(列 0~8, 欄 0~15)，(列,欄)=(0,0) 在左上、(8,15) 在右下。
@export var grid_screen_size: Vector2 = Vector2(1920, 1080)

@onready var _body_sprite: Node2D = $BodySprite
@onready var _dress: Dress = $Dress
@onready var _ghost_trail: GhostTrail = $GhostTrail
# 錨點容器：boss 下擺一個 Node2D「ReleaseAnchors」，內含 5 個 Marker2D
@onready var _anchors: Node2D = $ReleaseAnchors

const GRID_COLS: int = 16
const GRID_ROWS: int = 9

# 散步軸心 = 出生位置（固定）；相位只在冷卻期間由 FSM 累進
var _stroll_home: Vector2
var _stroll_phase: float = 0.0


func _ready() -> void:
	_stroll_home = position


# ── 上下文 API：給 State 使用 ──────────────────────────────
func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


# 散步一步（由 FSM 在決策冷卻期間每幀呼叫）。
# 橫向 8 字（Lemniscate of Gerono）：相位 0 時 offset 為 0，故永遠繞 home 內擺、不漂離。
# 不變量：每個動作結束時 boss 須回到進入時的位置（晃動 tween 回 start、彈幕不移動、
# 衝撞慢歸位皆滿足），冷卻恢復時 position 才會與 home + offset(phase) 連續、不跳動。
func stroll_step(delta: float) -> void:
	_stroll_phase += stroll_speed * delta
	var offset := Vector2(
		stroll_amp_x * sin(_stroll_phase),
		stroll_amp_y * sin(_stroll_phase) * cos(_stroll_phase)
	)
	position = _stroll_home + offset


# ── 釋放點定位 API ─────────────────────────────────────────
# LOCAL 用：回傳第 idx 個 boss 錨點的 local position（釋放點掛 boss 下、用此值定位）
func get_anchor_local_position(idx: int) -> Vector2:
	if not _anchors:
		push_warning("Boss: 找不到 ReleaseAnchors 容器")
		return Vector2.ZERO
	if idx < 0 or idx >= _anchors.get_child_count():
		push_warning("Boss: 錨點索引 %d 超出範圍" % idx)
		return Vector2.ZERO
	var marker := _anchors.get_child(idx) as Node2D
	return marker.position if marker else Vector2.ZERO


# GLOBAL 用：把世界格座標 Vector2i(列, 欄) 換成世界座標（格子中心）。
# 網格以 boss 出生點 _stroll_home 為中心鋪 16×9。
func get_grid_world_position(cell: Vector2i) -> Vector2:
	var cell_w: float = grid_screen_size.x / float(GRID_COLS)
	var cell_h: float = grid_screen_size.y / float(GRID_ROWS)
	# 網格左上角 = 出生點 - 半個網格
	var grid_origin := _stroll_home - grid_screen_size * 0.5
	# 第 (列,欄) 格的中心
	return grid_origin + Vector2(
		(float(cell.y) + 0.5) * cell_w,
		(float(cell.x) + 0.5) * cell_h
	)


# ── 殘影上下文 API：給 GhostTrail 取快照資料、給 State 開關 ──
func get_body_sprite() -> Node2D:
	return _body_sprite


func get_dress_texture() -> Texture2D:
	return _dress.dress_texture if _dress else null


func get_dress_snapshot_data() -> Array:
	return _dress.get_snapshot_data() if _dress else []


func start_ghost_trail() -> void:
	if _ghost_trail:
		_ghost_trail.start()


func stop_ghost_trail() -> void:
	if _ghost_trail:
		_ghost_trail.stop()
