## 角色基类
## 玩家和敌人的共同基类，管理血量和护甲
class_name Character extends Control

#region 信号
## 血量变化信号
signal health_changed(current: int, maximum: int)

## 护甲变化信号
signal block_changed(block: int)

## 角色死亡信号
signal character_died(character: Character)

## 受到伤害信号
signal damage_taken(amount: int)
#endregion

#region 属性
## 最大血量
@export var max_hp: int = 80

## 当前血量
@export var current_hp: int = 80

## 当前护甲
@export var block: int = 0

## 角色名称
@export var char_name: String = "角色"
#endregion

## UI组件
var hp_bar: ProgressBar
var hp_label: Label
var block_label: Label
var name_label: Label
var character_rect: Panel


func _ready() -> void:
	# 直接设置 size，确保 get_global_rect() 返回正确值
	size = Vector2(100, 130)
	custom_minimum_size = Vector2(100, 130)
	_setup_ui()
	_update_display()


## 创建UI
func _setup_ui() -> void:
	# 角色背景 - 使用 Panel 支持样式
	character_rect = Panel.new()
	character_rect.size = Vector2(100, 130)
	character_rect.position = Vector2(0, 0)  # 确保从左上角开始
	character_rect.mouse_filter = Control.MOUSE_FILTER_PASS

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.25, 0.3)
	style.border_color = Color(0.5, 0.5, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	character_rect.add_theme_stylebox_override("panel", style)
	add_child(character_rect)

	# 角色名称
	name_label = Label.new()
	name_label.position = Vector2(5, 5)
	name_label.custom_minimum_size = Vector2(90, 20)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = char_name
	character_rect.add_child(name_label)

	# 护甲显示
	block_label = Label.new()
	block_label.position = Vector2(5, 28)
	block_label.custom_minimum_size = Vector2(90, 25)
	block_label.add_theme_font_size_override("font_size", 16)
	block_label.add_theme_color_override("font_color", Color.CYAN)
	block_label.add_theme_color_override("font_outline_color", Color.BLACK)
	block_label.add_theme_constant_override("outline_size", 2)
	block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block_label.text = ""
	character_rect.add_child(block_label)

	# 血量条背景
	var hp_bg := Panel.new()
	hp_bg.position = Vector2(5, 55)
	hp_bg.custom_minimum_size = Vector2(90, 20)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15)
	bg_style.set_corner_radius_all(4)
	hp_bg.add_theme_stylebox_override("panel", bg_style)
	character_rect.add_child(hp_bg)

	# 血量条
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(5, 55)
	hp_bar.custom_minimum_size = Vector2(90, 20)
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.show_percentage = false
	# 自定义进度条样式
	var fg_style := StyleBoxFlat.new()
	fg_style.bg_color = Color(0.8, 0.2, 0.2)
	fg_style.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", fg_style)
	hp_bar.add_theme_stylebox_override("background", StyleBoxFlat.new())  # 透明背景
	character_rect.add_child(hp_bar)

	# 血量文本
	hp_label = Label.new()
	hp_label.position = Vector2(5, 80)
	hp_label.custom_minimum_size = Vector2(90, 22)
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_label.add_theme_constant_override("outline_size", 2)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.text = "%d / %d" % [current_hp, max_hp]
	character_rect.add_child(hp_label)


## 更新显示
func _update_display() -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	if hp_label:
		hp_label.text = "%d / %d" % [current_hp, max_hp]
	if block_label:
		if block > 0:
			block_label.text = "护甲: %d" % block
			block_label.add_theme_color_override("font_color", Color.CYAN)
		else:
			block_label.text = ""
	if name_label:
		name_label.text = char_name


## 受到伤害
func take_damage(amount: int) -> void:
	# 护甲先抵挡伤害
	if block > 0:
		if block >= amount:
			block -= amount
			amount = 0
		else:
			amount -= block
			block = 0

	if amount > 0:
		current_hp -= max(0, amount)
		damage_taken.emit(amount)

	block_changed.emit(block)
	health_changed.emit(current_hp, max_hp)
	_update_display()

	if current_hp <= 0:
		current_hp = 0
		character_died.emit(self)


## 获得护甲
func gain_block(amount: int) -> void:
	block += amount
	block_changed.emit(block)
	_update_display()


## 重置护甲（回合开始时）
func reset_block() -> void:
	block = 0
	block_changed.emit(block)
	_update_display()


## 治疗
func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	health_changed.emit(current_hp, max_hp)
	_update_display()


## 获取全局位置（用于目标选择）
func get_target_position() -> Vector2:
	return global_position + Vector2(50, 65)


## 检查是否存活
func is_alive() -> bool:
	return current_hp > 0
