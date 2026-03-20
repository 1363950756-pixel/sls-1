## 地图UI - 美化版
## 使用 _draw() 绘制背景和连线，带噪声偏移
extends Control

const NODE_W := 80
const NODE_H := 60
const GAP_X := 130
const GAP_Y := 100
const COLS := 3

# 噪声偏移范围（像素）
const JITTER_X := 25
const JITTER_Y := 15

var map: Array = []
var cur: MapNode = null
var btns: Array = []
var scroll: ScrollContainer
var holder: Control
var canvas: MapCanvas

# 噪声种子（每张地图固定）
var noise_seed: int = 0


func _ready() -> void:
	_build_ui()
	_load_map()


func _build_ui() -> void:
	var sz := get_viewport_rect().size

	# 标题
	var title := Label.new()
	title.position = Vector2(20, 15)
	title.text = "地图 - 第 %d 层" % (GameState.current_floor + 1)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.GOLD)
	add_child(title)

	# 状态
	var info := Label.new()
	info.position = Vector2(20, 50)
	info.text = "HP: %d/%d   金币: %d" % [GameState.current_hp, GameState.max_hp, GameState.gold]
	info.add_theme_font_size_override("font_size", 16)
	add_child(info)

	# 滚动区
	scroll = ScrollContainer.new()
	scroll.position = Vector2(0, 80)
	scroll.size = Vector2(sz.x, sz.y - 80)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	holder = Control.new()
	scroll.add_child(holder)

	# 画布（绘制背景和连线）
	canvas = MapCanvas.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(canvas)


func _load_map() -> void:
	# 优先使用已存在的地图
	if GameState.current_map and GameState.current_map.size() > 0:
		map = GameState.current_map
		cur = GameState.current_node
		noise_seed = GameState.map_noise_seed if GameState.map_noise_seed else 0
		print("[MapUI] 加载已有地图，当前节点: row=%d col=%d" % [cur.row if cur else -1, cur.col if cur else -1])
	else:
		# 首次进入，生成新地图
		map = MapGenerator.create()
		GameState.current_map = map
		cur = MapGenerator.get_start(map)
		GameState.current_node = cur
		# 生成噪声种子
		noise_seed = randi() % 10000
		GameState.map_noise_seed = noise_seed
		print("[MapUI] 生成新地图，噪声种子: %d" % noise_seed)

	call_deferred("_render")
	call_deferred("_go_bottom")


func _go_bottom() -> void:
	await get_tree().process_frame
	var bar := scroll.get_v_scroll_bar()
	if bar:
		scroll.scroll_vertical = int(bar.max_value)


## 噪声函数：返回 -1 到 1 的伪随机值
func _noise(row: int, col: int) -> float:
	var n := sin(noise_seed * 12.9898 + row * 78.233 + col * 43.758) * 43758.5453
	return (n - floor(n)) * 2.0 - 1.0


func _render() -> void:
	# 清理按钮
	for b in btns:
		b.queue_free()
	btns.clear()

	# 调试
	print("=== 地图节点 ===")
	for layer in map:
		for n in layer:
			print("节点 row=%d col=%d type=%d done=%s open=%s" % [n.row, n.col, n.type, n.is_done, n.is_open])
	print("================")

	# 内容尺寸
	var h := float(map.size() + 1) * GAP_Y
	var w := get_viewport_rect().size.x
	holder.custom_minimum_size = Vector2(w, h)

	# 设置画布尺寸
	canvas.custom_minimum_size = Vector2(w, h)
	canvas.map = map
	canvas.noise_seed = noise_seed
	canvas.jitter_x = JITTER_X
	canvas.jitter_y = JITTER_Y
	canvas.queue_redraw()

	var cx := w / 2.0
	var bottom := h - 60.0

	# 创建节点按钮
	for layer in map:
		for n in layer:
			var pos := _node_pos_with_jitter(n, cx, bottom)
			_make_btn(n, pos)


## 节点位置（带噪声偏移）
func _node_pos_with_jitter(n: MapNode, cx: float, bottom: float) -> Vector2:
	var layer_size: int = map[n.row].size()
	var offset_x: float = (float(layer_size) - 1.0) / 2.0 * GAP_X
	var x := cx - offset_x + float(n.col) * GAP_X
	var y := bottom - float(n.row) * GAP_Y

	# 添加噪声偏移
	x += _noise(n.row, n.col) * JITTER_X
	y += _noise(n.row + 1000, n.col + 1000) * JITTER_Y

	return Vector2(x, y)


func _make_btn(n: MapNode, pos: Vector2) -> void:
	var btn := Button.new()
	btn.position = Vector2(pos.x - NODE_W / 2, pos.y - NODE_H / 2)
	btn.custom_minimum_size = Vector2(NODE_W, NODE_H)
	btn.text = _type_icon(n.type)
	btn.add_theme_font_size_override("font_size", 24)

	var st := StyleBoxFlat.new()
	st.bg_color = _type_color(n.type)
	st.set_corner_radius_all(8)
	st.set_border_width_all(2)

	if n.is_done:
		st.bg_color = Color(0.2, 0.2, 0.2)
		st.border_color = Color(0.4, 0.4, 0.4)
		btn.disabled = true
	elif n.is_open:
		st.border_color = Color(1, 0.85, 0.3)
		st.set_border_width_all(3)
	else:
		st.bg_color = Color(0.15, 0.15, 0.15)
		st.border_color = Color(0.35, 0.35, 0.35)
		btn.disabled = true

	if n == cur:
		st.border_color = Color(0.3, 1, 0.4)
		st.set_border_width_all(4)

	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("disabled", st)
	btn.add_theme_stylebox_override("hover", st)
	btn.add_theme_stylebox_override("pressed", st)

	if n.is_open and not n.is_done:
		btn.pressed.connect(_click.bind(n))

	holder.add_child(btn)
	btns.append(btn)


## 节点图标（Unicode符号）
func _type_icon(t: int) -> String:
	match t:
		MapNode.Type.START: return "🚩"
		MapNode.Type.BATTLE: return "⚔"
		MapNode.Type.ELITE: return "☠"
		MapNode.Type.EVENT: return "❓"
		MapNode.Type.REST: return "🔥"
		MapNode.Type.SHOP: return "💰"
		MapNode.Type.BOSS: return "👹"
		_: return "?"


## 节点颜色
func _type_color(t: int) -> Color:
	match t:
		MapNode.Type.START: return Color(0.9, 0.8, 0.3)
		MapNode.Type.BATTLE: return Color(0.7, 0.45, 0.3)
		MapNode.Type.REST: return Color(0.3, 0.6, 0.4)
		MapNode.Type.BOSS: return Color(0.6, 0.25, 0.5)
		MapNode.Type.SHOP: return Color(0.3, 0.55, 0.7)
		MapNode.Type.ELITE: return Color(0.75, 0.35, 0.3)
		MapNode.Type.EVENT: return Color(0.6, 0.5, 0.7)
		_: return Color(0.5, 0.5, 0.5)


func _click(n: MapNode) -> void:
	cur = n
	GameState.current_node = n

	match n.type:
		MapNode.Type.START:
			MapGenerator.finish(map, n)
			_render()
		MapNode.Type.BATTLE, MapNode.Type.ELITE, MapNode.Type.BOSS:
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
		MapNode.Type.EVENT:
			print("[MapUI] 随机事件待实现")
			MapGenerator.finish(map, n)
			_render()
		MapNode.Type.REST:
			var heal := int(GameState.max_hp * 0.3)
			GameState.player_heal(heal)
			MapGenerator.finish(map, n)
			_render()
		MapNode.Type.SHOP:
			print("[MapUI] 商店功能待实现")
			MapGenerator.finish(map, n)
			_render()
		_:
			get_tree().change_scene_to_file("res://scenes/battle.tscn")


## 地图画布 - 绘制背景和连线
class MapCanvas extends Control:
	var map: Array = []
	var noise_seed: int = 0
	var jitter_x: float = 25.0
	var jitter_y: float = 15.0

	func _draw() -> void:
		if map.is_empty():
			return

		var rect_size := custom_minimum_size if custom_minimum_size.x > 0 else get_rect().size

		# 羊皮纸背景
		draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.93, 0.85, 0.68))

		# 点阵质感（深色点在浅色背景上）
		for x in range(0, int(rect_size.x), 20):
			for y in range(0, int(rect_size.y), 20):
				draw_circle(Vector2(x, y), 1, Color(0.4, 0.35, 0.25, 0.1))

		var cx := rect_size.x / 2.0
		var bottom := rect_size.y - 60.0

		# 绘制连线（先画阴影，再画主线）
		for layer in map:
			for n in layer:
				var p1 := _node_pos_with_jitter(n, cx, bottom)
				for nxt in n.next:
					var p2 := _node_pos_with_jitter(nxt, cx, bottom)
					# 阴影
					draw_line(p1 + Vector2(2, 2), p2 + Vector2(2, 2), Color(0.2, 0.15, 0.1, 0.3), 4)
					# 主线
					draw_line(p1, p2, _get_line_color(n, nxt), 3)

	func _node_pos_with_jitter(n: MapNode, cx: float, bottom: float) -> Vector2:
		var layer_size: int = map[n.row].size()
		var offset_x: float = (float(layer_size) - 1.0) / 2.0 * GAP_X
		var x := cx - offset_x + float(n.col) * GAP_X
		var y := bottom - float(n.row) * GAP_Y

		# 添加噪声偏移
		x += _noise(n.row, n.col) * jitter_x
		y += _noise(n.row + 1000, n.col + 1000) * jitter_y

		return Vector2(x, y)

	func _noise(row: int, col: int) -> float:
		var n := sin(noise_seed * 12.9898 + row * 78.233 + col * 43.758) * 43758.5453
		return (n - floor(n)) * 2.0 - 1.0

	func _get_line_color(from: MapNode, to: MapNode) -> Color:
		if from.is_done:
			return Color(0.3, 0.55, 0.35)  # 已完成：绿色
		elif to.is_open:
			return Color(0.85, 0.7, 0.25)  # 可选择：金色
		else:
			return Color(0.4, 0.4, 0.45)  # 普通：灰色
