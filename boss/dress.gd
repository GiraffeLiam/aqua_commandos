# res://boss/dress/dress.gd
class_name Dress
extends Node2D

@export var dress_texture: Texture2D
@export var columns: int = 5
@export var rows: int = 6
@export var shatter_effect_scene: PackedScene

const ALPHA_THRESHOLD: int = 10

var _alive_count: int = 0
var _total_count: int = 0
# 每塊 block 對應的 region（破碎特效要用該塊貼圖當素材；block 銷毀前查表取得）
var _block_regions: Dictionary = {}


func _ready() -> void:
	if not dress_texture:
		push_error("Dress: dress_texture 未設定")
		return
	_build_blocks()


func _build_blocks() -> void:
	var image: Image = dress_texture.get_image()
	image.convert(Image.FORMAT_RGBA8)

	var tex_width: float = dress_texture.get_width()
	var tex_height: float = dress_texture.get_height()
	var block_w: float = tex_width / float(columns)
	var block_h: float = tex_height / float(rows)
	var block_size := Vector2(block_w, block_h)

	var origin := Vector2(
		-tex_width / 2.0 + block_w / 2.0,
		-tex_height / 2.0 + block_h / 2.0
	)

	for row in range(rows):
		for col in range(columns):
			var region := Rect2(
				col * block_w,
				row * block_h,
				block_w,
				block_h
			)

			if _is_region_transparent(image, region):
				continue

			var block := DressBlock.new()
			add_child(block)

			block.position = origin + Vector2(col * block_w, row * block_h)

			block.collision_layer = 16
			block.collision_mask = 2
			block.monitoring = true
			block.monitorable = true

			block.init(dress_texture, region, block_size, _on_block_destroyed)

			# 保存該塊 region，破碎特效時查表（不持有 block 參照）
			_block_regions[block] = region

			_alive_count += 1

	_total_count = _alive_count
	print("DressBlock 生成數量：", _total_count)

func _is_region_transparent(image: Image, region: Rect2) -> bool:
	var sample_step: int = 4
	var total: int = 0
	var count: int = 0

	var x_start: int = int(region.position.x)
	var y_start: int = int(region.position.y)
	var x_end: int = int(region.position.x + region.size.x)
	var y_end: int = int(region.position.y + region.size.y)

	for y in range(y_start, y_end, sample_step):
		for x in range(x_start, x_end, sample_step):
			var pixel: Color = image.get_pixel(x, y)
			total += int(pixel.a * 255)
			count += 1

	if count == 0:
		return true

	return (total / count) < ALPHA_THRESHOLD

func _on_block_destroyed(block: DressBlock) -> void:
	# 在 block queue_free 前，於其世界座標生破碎特效（碎片＝該塊貼圖）
	_spawn_shatter(block)
	_block_regions.erase(block)

	_alive_count -= 1
	event_bus.dress_progress_changed.emit(get_alive_pct())

	if _alive_count <= 0:
		print("dress_phase_cleared emitted")
		event_bus.dress_phase_cleared.emit()


# 於被擊破 block 的世界座標噴出該塊貼圖的碎片，掛到 Effects 容器（不隨 boss 移動）。
func _spawn_shatter(block: DressBlock) -> void:
	if not shatter_effect_scene:
		return
	var region: Rect2 = _block_regions.get(block, Rect2())
	if region.size == Vector2.ZERO:
		return

	var effect := shatter_effect_scene.instantiate() as ShatterEffect
	var effects_layer := get_parent().get_node_or_null("Effects")
	if effects_layer:
		effects_layer.add_child(effect)
	else:
		push_warning("Dress: 找不到 Effects 容器，破碎特效改掛場景根節點")
		get_tree().current_scene.add_child(effect)

	effect.global_position = block.global_position
	effect.setup(dress_texture, region)

func get_alive_pct() -> float:
	if _total_count <= 0:
		return 0.0
	return float(_alive_count) / float(_total_count)
	
# 已破壞比例（0.0 = 完整，1.0 = 全毀）。疲憊 state 用此算權重。
func get_destruction_pct() -> float:
	return 1.0 - get_alive_pct()
	
# 供 GhostTrail 取殘影所需的存活塊視覺資料（座標相對 Boss）。
# 不回傳 block 參照本身，只回傳重建純 Sprite2D 所需的 region / 位置 / 當前 alpha。
# position 相對 Boss = dress.position（相對 Boss）＋ block.position（相對 dress）。
func get_snapshot_data() -> Array:
	var data: Array = []
	for block in _block_regions:
		if not is_instance_valid(block):
			continue
		data.append({
			"region": _block_regions[block],
			"position": position + block.position,
			"alpha": block.modulate.a,
		})
	return data
