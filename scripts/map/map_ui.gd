## 地图UI - 简化版
extends Control

const NODE_W := 80
const NODE_H := 60
const GAP_X := 130
const GAP_Y := 100
const COLS := 3

var map: Array = []
var cur: MapNode = null
var btns: Array = []
var line_holder: Control
var scroll: ScrollContainer
var holder: Control


func _ready() -> void:
	_build_ui()
	_load_map()


func _build_ui() -> void:
	var sz := get_viewport_rect().size

	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.1)
	bg.anchors_preset = PRESET_FULL_RECT
	add_child(bg)

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


func _load_map() -> void:
	# 优先使用已存在的地图
	if GameState.current_map and GameState.current_map.size() > 0:
		map = GameState.current_map
		cur = GameState.current_node
		print("[MapUI] 加载已有地图，当前节点: row=%d col=%d" % [cur.row if cur else -1, cur.col if cur else -1])
	else:
		# 首次进入，生成新地图
		map = MapGenerator.create()
		GameState.current_map = map
		cur = MapGenerator.get_start(map)
		GameState.current_node = cur
		print("[MapUI] 生成新地图")

	call_deferred("_render")
	call_deferred("_go_bottom")


func _go_bottom() -> void:
	await get_tree().process_frame
	var bar := scroll.get_v_scroll_bar()
	if bar:
		scroll.scroll_vertical = int(bar.max_value)


func _render() -> void:
	# 清理
	if line_holder:
		line_holder.queue_free()
	for b in btns:
		b.queue_free()
	btns.clear()

	# 调试：打印节点信息
	print("=== 地图节点 ===")
	for layer in map:
		for n in layer:
			print("节点 row=%d col=%d type=%d done=%s open=%s" % [n.row, n.col, n.type, n.is_done, n.is_open])
	print("================")

	# 内容尺寸
	var h := float(map.size() + 1) * GAP_Y
	var w := get_viewport_rect().size.x
	holder.custom_minimum_size = Vector2(w, h)

	var cx := w / 2.0
	var bottom := h - 60.0

	# 先画线
	_draw_lines(cx, bottom)

	# 再画节点
	for layer in map:
		for n in layer:
			var pos := _node_pos(n, cx, bottom)
			_make_btn(n, pos)


func _node_pos(n: MapNode, cx: float, bottom: float) -> Vector2:
	var layer_size: int = map[n.row].size()
	var offset_x: float = (float(layer_size) - 1.0) / 2.0 * GAP_X
	var x := cx - offset_x + float(n.col) * GAP_X
	var y := bottom - float(n.row) * GAP_Y
	return Vector2(x, y)


func _draw_lines(cx: float, bottom: float) -> void:
	line_holder = Control.new()
	line_holder.mouse_filter = MOUSE_FILTER_IGNORE
	holder.add_child(line_holder)

	for layer in map:
		for n in layer:
			var p1 := _node_pos(n, cx, bottom)
			for nxt in n.next:
				var p2 := _node_pos(nxt, cx, bottom)
				var ln := Line2D.new()
				ln.width = 3.0
				ln.add_point(p1)
				ln.add_point(p2)

				# 根据状态设置颜色
				if n.is_done:
					ln.default_color = Color(0.3, 0.55, 0.35)  # 已完成：绿色
				elif nxt.is_open:
					ln.default_color = Color(0.85, 0.7, 0.25)  # 可选择：金色
				else:
					ln.default_color = Color(0.4, 0.4, 0.45)  # 普通连接：灰色

				line_holder.add_child(ln)


func _make_btn(n: MapNode, pos: Vector2) -> void:
	var btn := Button.new()
	btn.position = Vector2(pos.x - NODE_W / 2, pos.y - NODE_H / 2)
	btn.custom_minimum_size = Vector2(NODE_W, NODE_H)
	btn.text = _type_name(n.type)
	btn.add_theme_font_size_override("font_size", 12)

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


func _type_name(t: int) -> String:
	match t:
		MapNode.Type.START: return "起点"
		MapNode.Type.BATTLE: return "战斗"
		MapNode.Type.REST: return "休息"
		MapNode.Type.BOSS: return "Boss"
		MapNode.Type.SHOP: return "商店"
		MapNode.Type.ELITE: return "精英"
		_: return "未知"


func _type_color(t: int) -> Color:
	match t:
		MapNode.Type.START: return Color(0.9, 0.8, 0.3)
		MapNode.Type.BATTLE: return Color(0.7, 0.45, 0.3)
		MapNode.Type.REST: return Color(0.3, 0.6, 0.4)
		MapNode.Type.BOSS: return Color(0.6, 0.25, 0.5)
		MapNode.Type.SHOP: return Color(0.3, 0.55, 0.7)
		MapNode.Type.ELITE: return Color(0.75, 0.35, 0.3)
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
		MapNode.Type.REST:
			var heal := int(GameState.max_hp * 0.3)
			GameState.player_heal(heal)
			MapGenerator.finish(map, n)
			_render()
		MapNode.Type.SHOP:
			print("商店功能待实现")
			MapGenerator.finish(map, n)
			_render()
		_:
			get_tree().change_scene_to_file("res://scenes/battle.tscn")
