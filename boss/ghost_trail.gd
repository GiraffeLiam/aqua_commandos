# res://boss/ghost_trail.gd
# GhostTrail — 殘影元件（掛 Boss 下，由動作 State 開關）。
# 啟動後每 interval 拍一張當下快照（body ＋ dress 拼像），快照壓成純藍剪影
# （保留貼圖 alpha 輪廓、丟棄原色，避免半透明分層互透穿幫）。
# 快照生到世界空間（不跟 boss 移動）、淡出後自刪。晃動 / 衝撞共用。
class_name GhostTrail
extends Node2D

@export var interval: float = 0.08      # 拍照間隔（越小越密）
@export var fade_time: float = 0.3      # 每張殘影淡出時間
@export var start_alpha: float = 0.5    # 殘影初始透明度
@export var ghost_color: Color = Color(0.2, 0.5, 1.0)  # 剪影顏色（純藍）
@export var max_ghosts: int = 5         # 同時存活殘影硬上限（保險，正常不會觸發）
@export var ghost_z_index: int = 0      # 殘影 z（boss 在 battlefield 設 z=1，殘影壓其下）

var _boss: Boss
var _timer: float = 0.0
var _live_ghosts: Array[Node2D] = []


func _ready() -> void:
	_boss = get_parent() as Boss
	if not _boss:
		push_error("GhostTrail: 父節點不是 Boss")
		set_process(false)
		return
	set_process(false)  # 待 start() 才啟動


func start() -> void:
	_timer = 0.0  # 立刻拍第一張
	_live_ghosts.clear()
	set_process(true)


func stop() -> void:
	set_process(false)
	# 不清掉已生成的殘影，讓它們自然淡出


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = interval
		_spawn_ghost()


func _spawn_ghost() -> void:
	var ghost := Node2D.new()
	get_tree().current_scene.add_child(ghost)
	# 凍結在 boss 當前世界 transform；之後 boss 移動，ghost 不跟（已在世界空間）
	ghost.global_transform = _boss.global_transform
	ghost.z_index = ghost_z_index
	ghost.modulate.a = start_alpha

	# body 剪影：複製當前 body sprite，套純色處理
	var body_src := _boss.get_body_sprite()
	if body_src:
		var body_ghost := body_src.duplicate() as Node2D
		_tint_silhouette(body_ghost)
		ghost.add_child(body_ghost)

	# dress 剪影：用存活塊資料拼純 Sprite2D，同樣套純色
	var texture := _boss.get_dress_texture()
	if texture:
		for item in _boss.get_dress_snapshot_data():
			var s := Sprite2D.new()
			s.texture = texture
			s.region_enabled = true
			s.region_rect = item["region"]
			s.position = item["position"]
			_tint_silhouette(s)
			ghost.add_child(s)

	_live_ghosts.append(ghost)
	_prune_ghosts()

	# 淡出後自刪
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, fade_time)
	tw.tween_callback(ghost.queue_free)


# 把一個 sprite 壓成純色剪影：用著色器把 RGB 全換成 ghost_color、
# 只保留原貼圖 alpha 當輪廓遮罩。各塊都是同一個顏色，疊起來不會互相透出。
func _tint_silhouette(node: Node2D) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = _get_silhouette_shader()
	mat.set_shader_parameter("silhouette_color", ghost_color)
	if node is CanvasItem:
		(node as CanvasItem).material = mat


# 剪影著色器（靜態快取，所有殘影共用一份）
static var _silhouette_shader: Shader = null

static func _get_silhouette_shader() -> Shader:
	if _silhouette_shader == null:
		_silhouette_shader = Shader.new()
		_silhouette_shader.code = """
shader_type canvas_item;

uniform vec4 silhouette_color : source_color = vec4(0.2, 0.5, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// RGB 全換成剪影色，alpha 沿用貼圖（保留輪廓）
	COLOR = vec4(silhouette_color.rgb, COLOR.a);
}
"""
	return _silhouette_shader


func _prune_ghosts() -> void:
	# 先清掉已自刪的殘影參照（從尾端往前刪，避免索引位移）
	for i in range(_live_ghosts.size() - 1, -1, -1):
		if not is_instance_valid(_live_ghosts[i]):
			_live_ghosts.remove_at(i)
	# 超過上限：硬砍最舊（陣列前端）
	while _live_ghosts.size() > max_ghosts:
		var oldest := _live_ghosts.pop_front() as Node2D
		if is_instance_valid(oldest):
			oldest.queue_free()
