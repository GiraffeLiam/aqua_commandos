# res://boss/release_point.gd
# ReleasePoint — 獨立的投射物釋放點。生命週期：
#   出現(淡入放大) → pre_delay → 射彈幕 → post_delay → 消失(淡出縮小) → 自刪，emit finished。
# 完全自包含：自帶 projectile_scene、自己查 player、自己計時，不回呼 boss。
# 定位由生成者(調度 state)決定：LOCAL 掛 boss 下隨之移動 / GLOBAL 掛世界固定。
# 視覺：給了 sprite_texture 就用 Sprite2D，否則 fallback 用 _draw 畫佔位圓球。
class_name ReleasePoint
extends Node2D

enum TargetMode { FIXED_DOWN, PLAYER }  # 朝固定下方 / 朝玩家（追蹤屬投射物行為，押後）

# ── 射擊行為參數（走 @export，由調度 state 的 params 覆寫）─────
@export var projectile_scene: PackedScene
@export var target_mode: TargetMode = TargetMode.PLAYER
@export var lane_count: int = 3
@export var lane_step_degrees: float = 15.0
@export var wave_count: int = 3
@export var fire_interval: float = 0.3

# ── 時序參數 ───────────────────────────────────────────────
# 淡入佔用 pre_delay、淡出佔用 post_delay（不額外加時間）。
@export var pre_delay: float = 0.3
@export var post_delay: float = 0.3

# ── 視覺 ───────────────────────────────────────────────────
# 有 texture 就用 sprite；沒有則 fallback 畫圓球。換美術＝拖一張圖進來。
@export var sprite_texture: Texture2D
@export var orb_radius: float = 12.0
@export var orb_color: Color = Color(1.0, 0.4, 0.4, 0.9)
@export var appear_scale: float = 0.3   # 出現/消失時的起訖縮放(相對 1.0)

signal finished

var _waves_left: int = 0
var _fire_timer: float = 0.0
var _firing: bool = false
var _visual: Node2D    # sprite 或 self(圓球畫在自己身上)


func _ready() -> void:
	_setup_visual()
	_run()


func _setup_visual() -> void:
	if sprite_texture:
		var s := Sprite2D.new()
		s.texture = sprite_texture
		add_child(s)
		_visual = s
	else:
		# 圓球用自己的 _draw；縮放就縮放 self
		_visual = self
		queue_redraw()


func _draw() -> void:
	# 僅在沒給 sprite 時作為 fallback 視覺
	if not sprite_texture:
		draw_circle(Vector2.ZERO, orb_radius, orb_color)


# 整段生命週期：出現淡入 → pre 緩衝 → 射 → post 緩衝 → 消失淡出
func _run() -> void:
	# 出現：縮放 appear_scale→1、alpha 0→1，佔用 pre_delay
	_visual.scale = Vector2.ONE * appear_scale
	modulate.a = 0.0
	if pre_delay > 0.0:
		var tw_in := create_tween().set_parallel(true)
		tw_in.tween_property(_visual, "scale", Vector2.ONE, pre_delay)
		tw_in.tween_property(self, "modulate:a", 1.0, pre_delay)
		await tw_in.finished
	else:
		_visual.scale = Vector2.ONE
		modulate.a = 1.0

	_fire_all_waves()
	while _firing:
		await get_tree().process_frame

	# 消失：縮放 1→appear_scale、alpha 1→0，佔用 post_delay
	if post_delay > 0.0:
		var tw_out := create_tween().set_parallel(true)
		tw_out.tween_property(_visual, "scale", Vector2.ONE * appear_scale, post_delay)
		tw_out.tween_property(self, "modulate:a", 0.0, post_delay)
		await tw_out.finished

	finished.emit()
	queue_free()


func _fire_all_waves() -> void:
	_waves_left = wave_count
	_fire_timer = 0.0   # 立刻射第一波
	_firing = true


func _process(delta: float) -> void:
	if not _firing:
		return
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	_fire_one_wave()
	_waves_left -= 1
	if _waves_left <= 0:
		_firing = false
		return
	_fire_timer = fire_interval


func _fire_one_wave() -> void:
	if not projectile_scene:
		push_error("ReleasePoint: projectile_scene 未設定")
		return
	var base_angle: float = _get_base_direction().angle()
	var half: float = float(lane_count - 1) / 2.0
	for i in lane_count:
		var offset_deg: float = (float(i) - half) * lane_step_degrees
		var angle: float = base_angle + deg_to_rad(offset_deg)
		_spawn_projectile(Vector2.RIGHT.rotated(angle))


func _spawn_projectile(direction: Vector2) -> void:
	var projectile := projectile_scene.instantiate() as Projectile
	projectile.global_position = global_position
	projectile.init(direction)
	get_tree().current_scene.add_child(projectile)


func _get_base_direction() -> Vector2:
	if target_mode == TargetMode.FIXED_DOWN:
		return Vector2.DOWN
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return Vector2.DOWN
	return (player.global_position - global_position).normalized()


# 由調度 state 在生成後注入彈幕參數（B 方案）。必須在 add_child 觸發 _ready 前呼叫。
func apply_params(params: Dictionary) -> void:
	if params.has("target_mode"):
		target_mode = params["target_mode"]
	if params.has("lane_count"):
		lane_count = params["lane_count"]
	if params.has("lane_step_degrees"):
		lane_step_degrees = params["lane_step_degrees"]
	if params.has("wave_count"):
		wave_count = params["wave_count"]
	if params.has("fire_interval"):
		fire_interval = params["fire_interval"]
	if params.has("pre_delay"):
		pre_delay = params["pre_delay"]
	if params.has("post_delay"):
		post_delay = params["post_delay"]
