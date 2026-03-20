## 地图生成器
## 生成随机爬塔地图
class_name MapGenerator extends RefCounted

## 地图总行数（不包括起点和Boss）
const MAP_ROWS: int = 15

## 每行节点数量范围
const NODES_PER_ROW_MIN: int = 3
const NODES_PER_ROW_MAX: int = 4

## 节点类型权重（用于随机生成）
const BATTLE_WEIGHT: float = 0.55
const ELITE_WEIGHT: float = 0.10
const SHOP_WEIGHT: float = 0.12
const REST_WEIGHT: float = 0.15
const UNKNOWN_WEIGHT: float = 0.08


## 生成一张完整的地图
## 返回：二维数组，每行是一个数组，包含该行的所有节点
static func generate_map() -> Array[Array]:
	var map: Array[Array] = []

	# 生成普通层（从下往上，row 0 是起点）
	for row in range(MAP_ROWS):
		var row_nodes: Array[MapNode] = []
		var num_nodes := randi_range(NODES_PER_ROW_MIN, NODES_PER_ROW_MAX)

		for col in range(num_nodes):
			var node_type := _random_node_type(row)
			var node := MapNode.new(node_type, row, col)
			row_nodes.append(node)

		map.append(row_nodes)

	# 生成Boss层（最后一行）
	var boss_row: Array[MapNode] = []
	var boss := MapNode.new(MapNode.NodeType.BOSS, MAP_ROWS, 0)
	boss_row.append(boss)
	map.append(boss_row)

	# 建立节点连接
	_create_connections(map)

	# 设置初始可访问节点（第一行全部可访问）
	for node in map[0]:
		node.is_accessible = true

	return map


## 随机生成节点类型
static func _random_node_type(row: int) -> MapNode.NodeType:
	# 根据层数调整权重
	var battle_w := BATTLE_WEIGHT
	var elite_w := ELITE_WEIGHT
	var shop_w := SHOP_WEIGHT
	var rest_w := REST_WEIGHT

	# 前3层不出现精英
	if row < 3:
		elite_w = 0.0
		battle_w += ELITE_WEIGHT

	# 确保每层至少有一个休息点或商店的概率增加
	if row > 10:
		rest_w += 0.1

	var rand := randf()
	if rand < battle_w:
		return MapNode.NodeType.BATTLE
	elif rand < battle_w + elite_w:
		return MapNode.NodeType.ELITE
	elif rand < battle_w + elite_w + shop_w:
		return MapNode.NodeType.SHOP
	elif rand < battle_w + elite_w + shop_w + rest_w:
		return MapNode.NodeType.REST
	else:
		return MapNode.NodeType.UNKNOWN


## 建立节点之间的连接
static func _create_connections(map: Array[Array]) -> void:
	for row_idx in range(map.size() - 1):
		var current_row: Array = map[row_idx]
		var next_row: Array = map[row_idx + 1]

		# 为当前行的每个节点建立到下一行的连接
		for node in current_row:
			var node_pos: float = _get_node_position(node, current_row.size())
			var closest_nodes: Array = _find_closest_nodes(node_pos, next_row)

			for next_node in closest_nodes:
				node.connections_next.append(next_node)
				next_node.connections_prev.append(node)


## 计算节点在行中的相对位置（0-1）
static func _get_node_position(node: MapNode, row_size: int) -> float:
	if row_size <= 1:
		return 0.5
	return float(node.column) / float(row_size - 1)


## 找到下一行中最接近的节点（1-2个）
static func _find_closest_nodes(pos: float, next_row: Array) -> Array:
	var result: Array = []
	var next_row_size: int = next_row.size()

	if next_row_size == 1:
		result.append(next_row[0])
		return result

	# 计算每个节点的位置
	var positions: Array[float] = []
	for i in range(next_row_size):
		positions.append(float(i) / float(next_row_size - 1))

	# 找到最近的1-2个节点
	var min_dist: float = 2.0
	var closest_idx: int = 0

	for i in range(next_row_size):
		var dist := absf(positions[i] - pos)
		if dist < min_dist:
			min_dist = dist
			closest_idx = i

	result.append(next_row[closest_idx])

	# 有一定概率添加第二个连接
	if next_row_size > 1 and randf() < 0.5:
		var second_idx: int
		if closest_idx > 0 and (closest_idx >= next_row_size - 1 or randf() < 0.5):
			second_idx = closest_idx - 1
		else:
			second_idx = closest_idx + 1

		if second_idx >= 0 and second_idx < next_row_size:
			var second_node: MapNode = next_row[second_idx]
			if not result.has(second_node):
				result.append(second_node)

	return result


## 更新地图可访问状态
## current_node: 当前所在的节点（刚完成的节点）
static func update_accessible_nodes(map: Array[Array], current_node: MapNode) -> void:
	# 先将所有节点设为不可访问
	for row in map:
		for node in row:
			node.is_accessible = false

	# 当前节点已完成
	current_node.is_completed = true

	# 从当前节点连接的下一行节点设为可访问
	for next_node in current_node.connections_next:
		next_node.is_accessible = true
