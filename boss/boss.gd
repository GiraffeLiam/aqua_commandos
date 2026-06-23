# res://boss/boss.gd
# Boss — Boss 實體根節點，FSM 的「上下文」。
# 提供座標 / 玩家查詢 / 發射 helper / 散步移動 / 殘影控制 給各處呼叫；本身不決定要做哪個動作。
# 動作的決策與執行在 BossFSM ＋ 各 BossState（節點式狀態機）。
# 階段 3 片 1：移除舊「笨發射」，改由 FSM 驅動。
class_name Boss
extends Node2D

@export var projectile_scene: PackedScene

# ── 散步參數（決策冷卻期間的細微 8 字漂移）─────────────────
@export var stroll_amp_x: float = 24.0
@export var stroll_amp_y: float = 10.0
@export var stroll_speed: float = 1.5

@onready var _muzzle: Marker2D = $Muzzle
@onready var _body_sprite: Node2D = $BodySprite
@onready var _dress: Dress = $Dress
@onready var _ghost_trail: GhostTrail = $GhostTrail

# 散步軸心 = 出生位置（固定）；相位只在冷卻期間由 FSM 累進
var _stroll_home: Vector2
var _stroll_phase: float = 0.0


func _ready() -> void:
	_stroll_home = position


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
