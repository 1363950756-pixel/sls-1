# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

杀戮尖塔(Slay the Spire)复刻项目，使用 Godot 4.6 + GDScript 开发的卡牌战斗游戏。

## Development Commands

```bash
# 运行游戏（需要Godot编辑器）
godot --path . scenes/main.tscn

# 运行项目
godot --path .
```

## Architecture

### Global State (Autoload)
- **GameState** (`scripts/autoload/game_state.gd`): 全局单例，管理牌组、牌堆（抽牌堆/弃牌堆/消耗牌堆）、能量、回合状态

### Character System
- **Character** (`scripts/characters/character.gd`): 角色基类，管理血量、护甲、死亡信号
- **Player** (`scripts/characters/player.gd`): 玩家类，继承Character
- **Enemy** (`scripts/characters/enemy.gd`): 敌人类，有意图系统(IntentType: ATTACK/DEFEND/BUFF)和简单AI

### Card System
- **CardData** (`scripts/cards/card_data.gd`): Resource类，定义卡牌静态数据（名称、消耗、类型、目标类型、伤害/护甲值）
- **CardBase** (`scripts/cards/card_base.gd`): 卡牌UI组件，处理拖拽交互
- **CardHand** (`scripts/cards/card_hand.gd`): 手牌管理器，监听GameState信号刷新手牌

### UI Components
- **TargetSelector** (`scripts/ui/target_selector.gd`): 拖拽卡牌时的目标选择，绘制箭头
- **EnergyDisplay** (`scripts/ui/energy_display.gd`): 能量显示
- **PileDisplay** (`scripts/ui/pile_display.gd`): 牌堆显示（抽牌堆/弃牌堆）

### Data Flow
1. `GameState` 管理所有牌堆数据和能量
2. `CardHand` 监听 `GameState.hand_changed` 信号刷新UI
3. 拖拽卡牌 → `CardBase` 发出信号 → `CardHand` 转发给 `TargetSelector`
4. 目标选中 → `CardHand.card_played_on_target` → `main.gd` 执行卡牌效果

### Card Target Types
- `SELF`: 自身，拖到屏幕上半区域打出
- `SINGLE_ENEMY`: 单个敌人
- `ALL_ENEMIES`: 所有敌人
- `NONE`: 无需目标

## File Structure

```
scripts/
├── autoload/      # 全局单例
├── cards/         # 卡牌系统
├── characters/    # 角色系统
└── ui/            # UI组件

scenes/
├── main.tscn      # 主战斗场景
└── cards/         # 卡牌场景

resources/cards/   # CardData资源文件(.tres)
```

## Adding New Cards

1. 在 `resources/cards/` 创建新的 `.tres` 文件
2. 继承 `CardData`，设置属性（card_name, cost, card_type, target_type, attack_damage, block_amount）
3. 在 `GameState._init_starter_deck()` 中添加到初始牌组
4. 如需特殊效果，在 `main.gd._execute_card_effect()` 中处理
