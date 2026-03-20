## 地图节点数据
## 表示地图上的一个节点（战斗、商店、休息等）
class_name MapNode extends RefCounted

## 节点类型枚举
enum NodeType {
	BATTLE,    # 普通战斗
	ELITE,     # 精英战斗
	SHOP,      # 商店
	REST,      # 休息点
	BOSS,      # Boss战
	UNKNOWN    # 未知（未探索）
}

## 节点类型
var node_type: NodeType = NodeType.BATTLE

## 所在行（0是起点，从下往上）
var row: int = 0

## 所在列
var column: int = 0

## 连接到下一行的节点
var connections_next: Array[MapNode] = []

## 连接到这一节点的上一行节点
var connections_prev: Array[MapNode] = []

## 是否可访问（当前行或相邻节点已完成）
var is_accessible: bool = false

## 是否已完成
var is_completed: bool = false


func _init(type: NodeType = NodeType.BATTLE, r: int = 0, c: int = 0) -> void:
	node_type = type
	row = r
	column = c


## 获取节点类型的中文名称
func get_type_name() -> String:
	match node_type:
		NodeType.BATTLE:
			return "战斗"
		NodeType.ELITE:
			return "精英"
		NodeType.SHOP:
			return "商店"
		NodeType.REST:
			return "休息"
		NodeType.BOSS:
			return "Boss"
		_:
			return "未知"


## 获取节点类型的颜色
func get_type_color() -> Color:
	match node_type:
		NodeType.BATTLE:
			return Color(0.7, 0.5, 0.3)
		NodeType.ELITE:
			return Color(0.8, 0.3, 0.3)
		NodeType.SHOP:
			return Color(0.3, 0.6, 0.8)
		NodeType.REST:
			return Color(0.3, 0.7, 0.4)
		NodeType.BOSS:
			return Color(0.6, 0.2, 0.6)
		_:
			return Color(0.5, 0.5, 0.5)
