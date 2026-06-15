# res://autoloads/event_bus.gd
# EventBus — 純信號廣播中樞，無任何邏輯。
# 原則：只定義信號，不寫任何函式或變數。
# 跨場景、跨系統的溝通才走這裡；父子節點直接呼叫。
extends Node

# ── 階段 1 ──────────────────────────────────────────────────
signal dress_progress_changed(alive_pct: float)
signal dress_phase_cleared
signal player_died
signal boss_defeated

# ── 階段 2 ──────────────────────────────────────────────────
signal player_health_changed(current: int, maximum: int)
signal screen_shake_requested(duration: float, strength: float)
