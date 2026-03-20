## 地图节点 - 简化版
## 纯数据类，不继承任何节点
class_name MapNode extends RefCounted

## 节点类型
enum Type { START, BATTLE, REST, BOSS, SHOP, ELITE, EVENT }

var type: int = Type.BATTLE
var row: int = 0
var col: int = 0
var next: Array = []  # 下一步可到达的节点
var is_done: bool = false
var is_open: bool = false
