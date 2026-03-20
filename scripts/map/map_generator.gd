## 地图生成器 - 简化版
class_name MapGenerator extends RefCounted

# 层数和每层节点数
const ROWS := 13
const COLS := 3


static func create() -> Array:
	var map: Array = []

	# 第0层：起点
	var start := MapNode.new()
	start.type = MapNode.Type.START
	start.row = 0
	start.col = 1
	start.is_open = true
	map.append([start])

	print("[MapGenerator] 创建地图，起点: row=0, col=1")

	# 第1-9层：普通层
	for r in range(1, 10):
		var layer: Array = []
		for c in range(COLS):
			var n := MapNode.new()
			n.type = _pick_type(r)
			n.row = r
			n.col = c
			layer.append(n)
		map.append(layer)

	# 第10层：休息
	var rest: Array = []
	for c in range(COLS):
		var n := MapNode.new()
		n.type = MapNode.Type.REST
		n.row = 10
		n.col = c
		rest.append(n)
	map.append(rest)

	# 第11层：Boss
	var boss := MapNode.new()
	boss.type = MapNode.Type.BOSS
	boss.row = 11
	boss.col = 1
	map.append([boss])

	# 连接
	_link(map)

	return map


static func _pick_type(r: int) -> int:
	if r <= 2:
		return MapNode.Type.BATTLE

	var roll := randf()
	var result: int
	if roll < 0.45:
		result = MapNode.Type.BATTLE
	elif roll < 0.60:
		result = MapNode.Type.EVENT
	elif roll < 0.75:
		result = MapNode.Type.ELITE
	elif roll < 0.90:
		result = MapNode.Type.SHOP
	else:
		result = MapNode.Type.REST

	return result


static func _link(map: Array) -> void:
	# 起点连接第1层所有节点
	var start: MapNode = map[0][0]
	for n in map[1]:
		start.next.append(n)

	# 第1-9层连接下一层
	for r in range(1, 10):
		var cur: Array = map[r]
		var nxt: Array = map[r + 1]

		for n in cur:
			# 同列连接
			n.next.append(nxt[n.col])

			# 30%概率加横向连接
			if randf() < 0.3:
				var offset: int = 1 if randf() < 0.5 else -1
				var nc: int = n.col + offset
				if nc >= 0 and nc < COLS:
					var target: MapNode = nxt[nc]
					if not n.next.has(target):
						n.next.append(target)

	# 休息层连接Boss
	for n in map[10]:
		n.next.append(map[11][0])


static func finish(map: Array, node: MapNode) -> void:
	node.is_done = true
	node.is_open = false

	# 更新当前层数
	GameState.current_floor = node.row

	# 清除所有开放状态
	for layer in map:
		for n in layer:
			n.is_open = false

	# 开放下一步
	for n in node.next:
		if not n.is_done:
			n.is_open = true


static func get_start(map: Array) -> MapNode:
	if map.size() > 0 and map[0].size() > 0:
		return map[0][0]
	return null
