## 卡牌数据类
## 使用Resource存储卡牌的静态数据，方便复用和扩展
class_name CardData extends Resource

## 卡牌类型枚举
enum CardType { ATTACK, SKILL, CURSE }

## 卡牌目标类型枚举
enum CardTarget { SELF, SINGLE_ENEMY, ALL_ENEMIES, NONE }

## 卡牌名称
@export var card_name: String = "未命名"

## 卡牌描述（支持动态文本，如"造成{damage}点伤害"）
@export_multiline var description: String = ""

## 能量消耗
@export var cost: int = 1

## 卡牌类型
@export var card_type: CardType = CardType.ATTACK

## 目标类型
@export var target_type: CardTarget = CardTarget.SINGLE_ENEMY

## 攻击伤害值（用于攻击卡）
@export var attack_damage: int = 0

## 格挡值（用于防御卡）
@export var block_amount: int = 0

## 卡牌背景颜色（用于简单占位符美术）
@export var card_color: Color = Color.WHITE


## 获取格式化后的描述文本
func get_formatted_description() -> String:
	var formatted = description
	# 替换伤害和格挡占位符
	formatted = formatted.replace("{damage}", str(attack_damage))
	formatted = formatted.replace("{block}", str(block_amount))
	return formatted
