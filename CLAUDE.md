# 水槍大爆射 — Claude Code 說明書

## 命名規則
- Nodes: PascalCase（Player, Weapon, DressBlock）
- Autoloads: snake_case（event_bus, game_manager）
- 私有變數加 `_` 前綴
- signal 用過去式動詞（dress_damaged, player_died）

## 物理層（2D Physics Layers）
Layer 1=player, 2=bullet, 3=enemy, 4=projectile, 5=dress, 6=environment, 7=boss
Bit 值 = 2^(layer-1)，例如 bullet=2, dress=16

## 重要原則
- 父子節點直接連 signal，跨場景走 event_bus
- 不使用 TileMapLayer 的內建 physics（無法識別單一 tile）
- _process 不用到 delta 時命名為 _delta

## 目前進度
Stage 1-4（Dress DressBlock 系統）已完成。
下一步：1-5 Boss 靜態 Sprite、1-6 GameManager 勝敗條件。