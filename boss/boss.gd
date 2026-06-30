# res://boss/boss.gd
# Boss — Boss 實體根節點，FSM 的「上下文」。
# 提供座標 / 玩家查詢 / 散步移動 / 殘影控制 / 釋放點定位 給各處呼叫；本身不決定要做哪個動作。
# 動作的決策與執行在 BossFSM ＋ 各 BossState（節點式狀態機）。
# 階段 3 片 1：射擊改由獨立 ReleasePoint 負責，boss 不再自己發射。
# 階段 3 片 2：Body(AnimatableBody2D 子節點) 當物理障礙，玩家撞不進、推不動 boss。
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
# 物理障礙：AnimatableBody2D 子節點，玩家撞上被擋（軟推開由 player.gd 既有邏輯處理）
@onready var _body: AnimatableBody2D = $Body
# 錨點容器：boss 下擺一個 Node2D「ReleaseAnchors」，內含 5 個 Marker2D
@onready var _anchors: Node2D = $ReleaseAnchors

const GRID_COLS: int = 16
const GRID_ROWS: int = 9
const _BOSS_LAYER_BIT: int = 64   # 物理層 7 = boss（2^(7-1)）

# 散步軸心 = 當前啟用的預設點位；相位只在冷卻期間由 FSM 累進。
# 【單一真相來源】散步、晃動回歸、所有動作歸位都讀 _stroll_home，
# 故未來切換點位只需改這一個變數，全體行為自動跟隨新軸心。
##
## ──────────────────────────────────────────────────────────
## 【未來擴展】多預設點位（boss 進階變化，配合 6.5 / 6-3）
## 目標：boss 擁有 3~5 個預設駐紮點，戰鬥中切換以表現變化性。
## 因現在已統一用 _stroll_home 當單一軸心，未來切點位 = 改 _stroll_home 指向，
## 散步/晃動/歸位全部自動跟隨，不必重構各動作。實作要點：
##   1. 點位來源：複用 Marker2D 組（仿 ReleaseAnchors，擺一組 HomePositions），
##      或複用世界格 get_grid_world_position()。兩者基礎都已就緒。
##   2. 過渡方式：瞬間切換（直接改 _stroll_home，配閃現類動作）
##      或平滑過渡（boss 用一段時間「走」到新點，可做成 RelocateState）。
##   3. 觸發者（待定）：獨立 RelocateState 丟進加權池（最符合節點式 FSM）／
##      某 state 順便切／dress 破壞到階段觸發。傾向獨立 state。
## ──────────────────────────────────────────────────────────
var _stroll_home: Vector2
var _stroll_phase: float = 0.0


func _ready() -> void:
	_stroll_home = position
	_setup_body_collision()


# Body 當「被動障礙」：自己在 Layer 7（被玩家偵測），不主動偵測別人（mask=0）。
# 玩家被擋 + 軟推開靠 player.gd 的 _resolve_boss_contact（它認 Layer 7）。
func _setup_body_collision() -> void:
	if not _body:
		push_warning("Boss: 找不到 Body(AnimatableBody2D)，物理阻擋未生效")
		return
	_body.collision_layer = _BOSS_LAYER_BIT
	_body.collision_mask = 0
	# 擊飛擱置：sync_to_physics 維持 false（純障礙；true 是為了主動推飛，現不需要）
	_body.sync_to_physics = false


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

# 散步軸心（當前預設點位）。晃動等動作的回歸點讀此值，確保結束後精確回到軸心、
# 不把散步的瞬時 offset 焊進基準位置（避免多次動作累積漂移）。
func get_stroll_home() -> Vector2:
	return _stroll_home

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

# dress 已破壞比例（委派給 dress）。疲憊 state 用此算動態權重。
func get_destruction_pct() -> float:
	return _dress.get_destruction_pct() if _dress else 0.0

func start_ghost_trail() -> void:
	if _ghost_trail:
		_ghost_trail.start()


func stop_ghost_trail() -> void:
	if _ghost_trail:
		_ghost_trail.stop()


## ──────────────────────────────────────────────────────────
## 【擱置】衝撞擊飛（knockback）——日後當外掛加，現不實作
## 評估：技術集中、維護成本高，故片 2 暫緩，衝撞先做純表演型位移。
## 若要實作「boss 衝撞把玩家撞飛到反方向」，需要以下三塊：
##
## func _apply_charge_knockback() 的技術內容說明：
## 1. 衝撞傷害區（新增 Area2D）：衝撞期間啟用，偵測撞到玩家。
##    物理阻擋的 CollisionShape2D「不回報」撞擊事件，故需獨立 Area2D 拿到
##    「撞到玩家」這個信號來觸發擊飛。形狀可與 Body 重疊但是不同節點。
## 2. 擊飛方向與力道：以 boss 衝撞方向（或 boss→玩家向量）為擊飛方向，
##    給玩家一個初速 knockback_speed，沿該方向彈開。
## 3. 玩家擊退狀態（改 player.gd）：玩家需新增「被擊退」狀態——
##    該狀態期間 velocity 由擊飛主導（非玩家輸入），隨時間衰減，
##    衰減完還給玩家控制。平常 velocity=input*speed，被擊退時覆寫。
## ──────────────────────────────────────────────────────────
