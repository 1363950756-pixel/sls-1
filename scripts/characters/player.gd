## 玩家类
## 继承自Character，添加玩家特有的功能
class_name Player extends Character


func _ready() -> void:
	super._ready()
	char_name = "玩家"
	max_hp = 80
	current_hp = 80
	# 更新UI颜色
	if character_rect:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.3, 0.5)
		style.border_color = Color(0.4, 0.6, 0.8)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		character_rect.add_theme_stylebox_override("panel", style)
	_update_display()
