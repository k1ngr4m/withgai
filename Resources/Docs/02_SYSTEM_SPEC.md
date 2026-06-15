# 02_SYSTEM_SPEC

## 文档信息
- 项目代号：`withgai`
- 文档定位：首个可开发级技术规格文档
- 上游设计源：`Resources/Docs/01_GAME_DESIGN_BRIEF.md`
- 目标引擎：`Godot 4.x`
- 目标语言：`GDScript`
- 数据方案：`Luban`

## 1. 文档目标与实现边界

### 1.1 文档目标
本文件用于把 `01_GAME_DESIGN_BRIEF.md` 中的玩法设计转译成可直接执行的技术规格，供后续原型开发使用。本文档解决的问题不是“游戏玩法是什么”，而是：

- 工程模块怎么拆分
- 运行时状态怎么组织
- Luban 配置怎么建表
- 各场景之间怎么切换和传递状态
- 首个可玩版本必须实现哪些能力
- 哪些内容只做扩展预留

### 1.2 设计输入
- `01_GAME_DESIGN_BRIEF.md` 是玩法真源
- `README.md` 当前缺失，不作为本文件输入
- 本文档遵守主提示中的硬约束：
  - 使用 `Godot 4.x + GDScript`
  - 所有核心平衡数据进入 `Luban`
  - 先保证可运行，再逐步增强表现

### 1.3 范围分层

#### A. First Playable 必做
- 五职业可切换：`后端 / 前端 / 测试 / 算法 / 产品经理`
- 完整章节树图与楼层路径选择
- 基础战斗闭环
- 奖励、商店、休息处、事件、Boss
- 局外成长：工位升级 + 职业解锁树
- 单局中断续玩

#### B. 扩展预留
- `HR` 完整系统占位
- 更多敌人、事件、遗物与职业特化效果
- 更复杂的效果 DSL
- 更强的战斗日志、演出、动画与 UI 表现

#### C. 非目标
- 不在本版中实现联网、多线程战斗或复杂 mod 系统
- 不在本版中实现剧情分支与多结局系统
- 不在本版中定义最终平衡表

### 1.4 对旧 Brief 假设的工程覆盖
`01_GAME_DESIGN_BRIEF.md` 末尾仍保留“首发原型优先保证后端可玩”的默认假设。为避免实现范围歧义，本文件在工程层面明确重定义为：

- `First Playable` 以后端、前端、测试、算法、产品经理五职业可切换为准
- 该调整只影响工程优先级和原型目标
- 不重写 `01` 的玩法真源地位

## 2. 总体架构

### 2.1 分层结构
系统采用四层结构：

- `流程层`
  管理场景切换、主循环推进和页面导航
- `运行层`
  管理单局状态、战斗状态、地图状态、奖励状态和局外成长
- `表现层`
  Godot 场景与 UI 节点，仅消费和呈现状态，不持有单局真状态
- `配置层`
  Luban 导出的只读配置数据，驱动卡牌、敌人、地图、事件、遗物、职业与成长

### 2.2 核心模块

#### AppRoot
- 全局启动入口
- 初始化 `ConfigService`、`SaveService`、`MetaProgressionService`
- 创建 `FlowController`
- 挂载全局单例或服务容器

#### FlowController
- 管理所有主流程场景切换
- 维护当前场景标识
- 根据 `RunState` 决定进入地图、战斗、商店、事件、结算或局外成长页

#### RunSession
- 当前单局唯一运行上下文
- 持有 `RunState`
- 提供对外读写接口
- 不直接负责 UI，也不直接负责存档序列化

#### ConfigService
- 加载 Luban 导出内容
- 提供 ID 查询、职业过滤、章节过滤、权重池查询

#### SaveService
- 负责局外档和中断档读写
- 序列化 `MetaState`
- 序列化 `SuspendSaveState`

#### MetaProgressionService
- 维护局外成长状态
- 执行职业解锁
- 执行工位升级购买
- 结算窝囊费

#### MapService
- 构建章节树图
- 推进当前节点
- 判断节点类型
- 写入 `MapRunState`

#### BattleService
- 驱动战斗状态机
- 处理出牌、目标选择、效果执行、敌方意图、胜负判定
- 输出 `RewardState`

#### RewardService
- 生成卡牌奖励、遗物奖励、绩效点奖励和特殊掉落
- 按职业与章节过滤掉落池

#### ContentResolver
- 基于职业、章节、标签和 First Playable 范围过滤内容
- 为商店、事件、奖励、地图、战斗提供候选集合

### 2.3 技术原则
- 表现层不持有真状态
- 配置优先于脚本硬编码
- 脚本优先写通用执行器，不为每张卡写独立脚本
- 职业特殊机制只在通用执行器无法承载时使用少量特化逻辑

## 3. Godot 场景组织

### 3.1 场景列表
固定采用多场景模块化：

- `MainMenuScene`
- `ClassSelectScene`
- `MapScene`
- `BattleScene`
- `RewardScene`
- `ShopScene`
- `EventScene`
- `RestScene`
- `RunResultScene`
- `MetaProgressionScene`

### 3.2 场景职责约束
- 所有场景只读写 `RunSession/MetaProgressionService`
- 不允许场景私自保存业务状态副本作为真源
- 页面临时 UI 状态可以本地持有，但切场即失效

### 3.3 建议节点结构

#### MainMenuScene
- `Root`
- `TitlePanel`
- `PrimaryActions`
- `ContinueButton`
- `NewGameButton`
- `MetaButton`
- `ExitButton`

#### ClassSelectScene
- `Root`
- `ClassListPanel`
- `ClassDetailPanel`
- `UnlockConditionLabel`
- `DifficultyLabel`
- `ConfirmButton`

#### MapScene
- `Root`
- `ChapterHeader`
- `MapGraphPanel`
- `FloorInfoPanel`
- `NodeDetailPanel`
- `ResumeButton`

#### BattleScene
- `Root`
- `EnemyArea`
- `IntentArea`
- `PlayerArea`
- `HandArea`
- `BattleLogPanel`
- `ResourcePanel`
- `EndTurnButton`

#### RewardScene
- `Root`
- `RewardHeader`
- `CardChoicePanel`
- `RelicChoicePanel`
- `CurrencyPanel`

#### ShopScene
- `Root`
- `ShopStockPanel`
- `PlayerCurrencyPanel`
- `DeckOperationPanel`
- `RefreshButton`

#### EventScene
- `Root`
- `EventTextPanel`
- `OptionListPanel`
- `ResultPanel`

#### RestScene
- `Root`
- `RecoverButton`
- `UpgradeButton`

#### RunResultScene
- `Root`
- `ResultSummaryPanel`
- `MetaRewardPanel`
- `ReturnButton`

#### MetaProgressionScene
- `Root`
- `UpgradeTreePanel`
- `CareerUnlockPanel`
- `CurrencySummaryPanel`

## 4. 核心运行时状态模型

### 4.1 RunState
当前单局的唯一业务真状态。建议字段：

- `run_id`
- `selected_class_id`
- `current_chapter`
- `current_floor`
- `current_node_id`
- `rng_seed`
- `map_state: MapRunState`
- `deck_state: DeckState`
- `player_state: PlayerRunState`
- `owned_relic_ids`
- `currency_perf_points`
- `visited_node_ids`
- `event_history_ids`
- `defeated_boss_ids`
- `pending_reward_state`
- `current_scene_tag`
- `run_flags`

### 4.2 PlayerRunState
战斗外持久化的玩家单局状态：

- `max_spirit`
- `current_spirit`
- `base_energy`
- `deck_card_ids`
- `removed_card_ids`
- `upgraded_card_instance_ids`
- `class_resource_persistent_state`

### 4.3 DeckState
用于单局跨战斗维度维护牌组：

- `master_deck`
- `temporary_added_cards`
- `removed_cards`
- `upgraded_cards`

### 4.4 PlayerBattleState
战斗内临时状态：

- `max_spirit`
- `current_spirit`
- `current_energy`
- `current_block`
- `draw_pile`
- `hand`
- `discard_pile`
- `exhaust_pile`
- `status_list`
- `relic_runtime_flags`
- `class_resource_state`
- `cards_played_this_turn`
- `damage_taken_this_turn`

### 4.5 EnemyBattleState
- `enemy_def_id`
- `current_hp`
- `current_block`
- `phase_index`
- `intent_queue`
- `status_list`
- `summoned_entities`
- `runtime_flags`

### 4.6 MapRunState
- `chapter_index`
- `floors`
- `node_graph`
- `visited_nodes`
- `available_next_nodes`
- `boss_node_id`

### 4.7 RewardState
- `reward_type`
- `candidate_card_ids`
- `candidate_relic_ids`
- `currency_amount`
- `special_rewards`
- `source_encounter_id`

### 4.8 MetaState
- `owned_discomfort_currency`
- `unlocked_class_ids`
- `meta_upgrade_levels`
- `career_milestones`
- `highest_floor_reached`
- `defeated_boss_records`

### 4.9 SuspendSaveState
- `save_version`
- `scene_tag`
- `serialized_run_state`
- `serialized_meta_state_snapshot`
- `timestamp`

### 4.10 First Playable 职业资源状态

#### BackendResourceState
- `services`
- `cache`

#### FrontendResourceState
- `components`
- `style_layers`

#### TesterResourceState
- `bugs`
- `cases`
- `diff_tags`

#### AlgorithmResourceState
- `compute`
- `complexity`

#### ProductManagerResourceState
- `priority_targets`
- `requirement_change_marks`

### 4.11 扩展预留资源状态

#### HRResourceState
- `performance_marks`
- `optimization_targets`

## 5. 主流程状态图

### 5.1 高层流程
`MainMenu -> ClassSelect -> Map -> NodeScene -> Map -> ... -> RunResult -> MainMenu / MetaProgression`

### 5.2 节点进入规则
- `normal_battle` -> `BattleScene`
- `elite_battle` -> `BattleScene`
- `rest` -> `RestScene`
- `shop` -> `ShopScene`
- `event` -> `EventScene`
- `boss` -> `BattleScene`

### 5.3 节点完成规则
- 战斗胜利 -> `RewardScene` -> `MapScene`
- 战斗失败 -> `RunResultScene`
- 休息完成 -> `MapScene`
- 商店离开 -> `MapScene`
- 事件结算完成 -> `MapScene`
- 章节 Boss 击败 -> 若非终章则推进章节并回 `MapScene`，终章则进入 `RunResultScene`

## 6. 战斗系统执行模型

### 6.1 战斗状态机
`BattleStart -> RoundStart -> PlayerTurn -> RoundEnd -> EnemyTurn -> Victory/Defeat`

### 6.2 BattleStart
- 生成 `PlayerBattleState`
- 从 `RunState.deck_state` 构建抽牌堆
- 加载敌人
- 初始化遗物与战斗起始效果
- 显示敌方意图

### 6.3 RoundStart
- 结算 `OnRoundStart`
- 重置本回合计数器
- 补充基础精力
- 抽牌
- 计算职业资源的回合开始触发

### 6.4 PlayerTurn
- 检查是否可出牌
- 目标选择
- 费用检查
- 效果解析
- 牌移动
- 触发器结算
- UI 刷新
- 胜负检查

### 6.5 RoundEnd
- 丢弃未保留手牌
- 结算 `OnRoundEnd`
- 清理回合性标记

### 6.6 EnemyTurn
- 按意图队列执行敌人动作
- 结算 `OnBeforeAction / OnAfterAction`
- 处理召唤与阶段切换
- 再次检查胜负

### 6.7 出牌完整流程
1. 玩家选择手牌
2. 系统校验当前回合是否允许出牌
3. 系统校验费用
4. 若牌需要目标则进入目标选择
5. 根据 `CardDef.effect_group_id` 解析效果组
6. 顺序执行 `EffectEntry`
7. 处理状态触发与遗物触发
8. 将卡牌移动到弃牌堆或消耗区
9. 刷新 UI
10. 判断战斗是否结束

### 6.8 目标系统
至少支持：
- `self`
- `single_enemy`
- `all_enemies`
- `random_enemy`
- `lowest_hp_enemy`
- `highest_priority_enemy`

### 6.9 触发时机
首个原型最小触发集合：
- `battle_start`
- `round_start`
- `card_played`
- `attack_played`
- `skill_played`
- `damage_taken`
- `enemy_defeated`
- `round_end`

### 6.10 状态系统接口约定
所有状态逻辑统一遵循：
- `OnApply`
- `OnStack`
- `OnRoundStart`
- `OnBeforeAction`
- `OnAfterAction`
- `OnRoundEnd`
- `OnExpire`

### 6.11 最小效果枚举集
- `gain_block`
- `deal_damage`
- `draw_cards`
- `gain_energy`
- `apply_status`
- `remove_status`
- `create_card`
- `move_card`
- `add_relic`
- `modify_intent`
- `spawn_enemy`
- `gain_currency`
- `upgrade_card`
- `deploy_service`
- `add_cache`
- `add_component`
- `add_style_layer`
- `inject_bug`
- `add_case`
- `add_diff`
- `add_compute`
- `modify_complexity`

### 6.12 强数据驱动原则
- 卡牌、遗物、事件、状态效果通过 `EffectGroupDef + EffectEntryDef` 描述
- GDScript 实现统一执行器
- 只有跨多步骤且难以参数化的职业超大效果才允许注册少量脚本钩子

## 7. 职业系统设计落地

### 7.1 First Playable 职业范围
首个可玩原型接通：
- `后端`
- `前端`
- `测试`
- `算法`
- `产品经理`

### 7.2 扩展预留职业
保留完整数据与 UI 展示位：
- `HR`

约束：
- 可以出现在职业树和解锁树中
- 不进入实际战斗流程
- 不进入奖励、商店、战斗可选池

### 7.3 职业选择流程
- `ClassSelectScene` 读取 `MetaState.unlocked_class_ids`
- 对已解锁职业启用选择按钮
- 对锁定职业显示解锁条件
- 确认选择后生成 `RunSession`

## 8. 地图系统设计

### 8.1 地图目标
实现完整 `STS` 式树状路线图，不退回线性节点链。

### 8.2 地图生成流程
1. 读取章节规则
2. 按章节生成固定层数
3. 为每层分配节点类型权重
4. 构建合法连线
5. 标记起点、Boss 节点和关键节点
6. 写入 `MapRunState`

### 8.3 地图规则
- 每章单独生成
- 起点唯一
- Boss 节点唯一
- 中途至少出现一次休息或商店
- 精英节点数量受章节配置限制

### 8.4 节点数据流
- 点击可选节点
- `FlowController` 更新 `RunState.current_node_id`
- 根据 `node_type` 切换到目标场景

## 9. 奖励、商店、事件与休息处

### 9.1 奖励流程
- `BattleService` 生成 `RewardState`
- `RewardScene` 展示候选项
- 玩家选择后修改 `RunState.deck_state / owned_relic_ids / currency_perf_points`
- 返回 `MapScene`

### 9.2 商店流程
- 根据职业、章节和 `ShopPoolDef` 生成候选商品
- 允许购买卡牌、遗物、一次性道具、移除牌
- 购买后直接修改 `RunState`

### 9.3 事件流程
- `EventDef` 按章节与职业过滤
- 页面展示文本和选项
- 结果通过效果组直接修改 `RunState`

### 9.4 休息处流程
- 冥想：回复精神状态
- 复盘：升级指定卡牌实例

## 10. UI 页面结构与交互责任

### 10.1 MainMenu
- 输入：`MetaState`、`SuspendSaveState`
- 责任：开始新局、继续中断档、进入局外成长
- 交互：新游戏、继续、成长、退出

### 10.2 ClassSelect
- 输入：`MetaState`、`ClassDef`
- 责任：展示职业、解锁条件、难度、摘要
- 交互：查看职业详情、确认选择

### 10.3 Map
- 输入：`RunState.map_state`
- 责任：展示章节树图与可前进节点
- 交互：选择下一节点、查看节点详情

### 10.4 Battle
- 输入：`PlayerBattleState`、`EnemyBattleState`
- 责任：完成战斗操作与信息展示
- 交互：选择手牌、选择目标、结束回合

#### 五职业资源面板差异
- 后端：显示 `服务 / 缓存`
- 前端：显示 `组件 / 样式层`
- 测试：显示 `Bug / 用例 / Diff`
- 算法：显示 `算力 / 复杂度`
- 产品经理：显示 `需求变更 / 优先级`

### 10.5 Reward
- 输入：`RewardState`
- 责任：处理战斗后选择
- 交互：选卡、选遗物、确认跳过

### 10.6 Shop
- 输入：`RunState`、`ShopPoolDef`
- 责任：购买、移除、刷新
- 交互：购买、确认、离开

### 10.7 Event
- 输入：`EventDef`
- 责任：展示事件文本和结果
- 交互：选择选项、确认结果

### 10.8 Rest
- 输入：`RunState`
- 责任：执行恢复或升级
- 交互：冥想、复盘、返回地图

### 10.9 RunResult
- 输入：本局结算结果
- 责任：展示失败/胜利结果、窝囊费结算、解锁推进

### 10.10 MetaProgression
- 输入：`MetaState`、`MetaUpgradeDef`
- 责任：升级工位、查看职业树
- 交互：购买升级、查看职业解锁条件

## 11. Luban 配置设计

### 11.1 ClassDef
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 职业主键 |
| `name` | string | 职业显示名 |
| `family` | string | 所属家族，如 `programmer` / `office_other` |
| `unlock_order` | int | 解锁顺序 |
| `unlock_type` | string | 解锁条件类型 |
| `unlock_param` | string | 解锁参数 |
| `starter_relic_id` | string | 初始遗物 |
| `starter_deck` | string[] | 初始牌组卡牌 ID 列表 |
| `shared_pool_refs` | string[] | 共享池引用 |
| `recommended_difficulty` | int | 推荐难度 |
| `enabled_in_first_playable` | bool | 是否纳入首个原型 |

### 11.2 CardDef
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 卡牌主键 |
| `name` | string | 显示名 |
| `class_tags` | string[] | 所属职业或共享池标签 |
| `rarity` | string | 稀有度 |
| `type` | string | 攻击/技能/能力/状态/诅咒 |
| `cost` | int | 基础费用 |
| `target_type` | string | 目标类型 |
| `keywords` | string[] | 关键词 |
| `effect_group_id` | string | 效果组引用 |
| `upgrade_to` | string | 升级后卡牌 ID |
| `enabled_in_first_playable` | bool | 是否纳入首个原型 |

### 11.3 RelicDef
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 遗物主键 |
| `name` | string | 显示名 |
| `allowed_classes` | string[] | 可出现职业 |
| `rarity` | string | 稀有度 |
| `trigger_list` | string[] | 触发时机列表 |
| `effect_group_id` | string | 效果组 |
| `shop_weight` | int | 商店权重 |

### 11.4 EnemyDef
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 敌人主键 |
| `name` | string | 显示名 |
| `chapter_tags` | string[] | 所属章节 |
| `base_hp` | int | 基础生命 |
| `intent_group_id` | string | 意图组引用 |
| `phase_group_id` | string | 阶段组引用 |
| `reward_profile_id` | string | 奖励配置引用 |

### 11.5 EncounterDef
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 遭遇主键 |
| `chapter` | int | 章节 |
| `node_type` | string | 普通/精英/Boss |
| `enemy_ids` | string[] | 敌人列表 |
| `weight` | int | 抽取权重 |
| `min_floor` | int | 最低层 |
| `max_floor` | int | 最高层 |

### 11.6 MapNodeDef
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 节点模板主键 |
| `chapter` | int | 章节 |
| `node_type` | string | 节点类型 |
| `weight` | int | 权重 |
| `can_repeat` | bool | 是否允许重复 |
| `reward_profile_id` | string | 节点默认奖励配置 |

### 11.7 EventDef
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 事件主键 |
| `name` | string | 名称 |
| `chapter_tags` | string[] | 所属章节 |
| `allowed_classes` | string[] | 可出现职业 |
| `options` | string[] | 选项 ID 列表 |
| `result_effect_group_ids` | string[] | 结果效果组 |
| `weight` | int | 权重 |

### 11.8 StatusDef
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 状态主键 |
| `name` | string | 显示名 |
| `stack_rule` | string | 叠加规则 |
| `timing_hooks` | string[] | 触发钩子 |
| `effect_group_id` | string | 效果组 |
| `max_stack` | int | 最大层数 |
| `is_hidden` | bool | 是否隐藏 |

### 11.9 MetaUpgradeDef
| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | 升级主键 |
| `type` | string | `global_upgrade` / `career_unlock` |
| `name` | string | 名称 |
| `cost_curve` | int[] | 成本曲线 |
| `max_level` | int | 最大等级 |
| `effect_group_id` | string | 效果组 |
| `prerequisite_ids` | string[] | 前置条件 |

### 11.10 文档层附表关系
以下作为子表或附表存在，不视为新的高层业务对象：

#### EffectGroupDef
- `id`
- `entries`

#### EffectEntryDef
- `id`
- `effect_type`
- `target_type`
- `params`
- `condition_tags`

#### EnemyIntentGroupDef
- `id`
- `intent_entries`

#### RewardProfileDef
- `id`
- `card_pool_ref`
- `relic_pool_ref`
- `currency_range`

#### ShopPoolDef
- `id`
- `card_pool_refs`
- `relic_pool_refs`
- `refresh_cost`

## 12. 数据流设计

### 12.1 新开一局
1. `MainMenuScene` 进入新游戏
2. `ClassSelectScene` 选择职业
3. `FlowController` 创建 `RunSession`
4. `MapService` 生成第一章树图
5. 写入 `RunState`
6. 切到 `MapScene`

### 12.2 节点推进
1. 玩家选中节点
2. `FlowController` 根据 `node_type` 切场景
3. 对应服务读取 `RunState`
4. 节点完成后写回 `RunState`
5. 回到 `MapScene`

### 12.3 战斗结算
1. `BattleService` 产生结果
2. 若失败 -> `RunResultScene`
3. 若胜利 -> `RewardState`
4. `RewardScene` 处理奖励
5. 奖励写回 `RunState`
6. 返回地图

### 12.4 局外成长
1. `RunResultScene` 读取本局里程碑
2. 计算窝囊费与职业解锁推进
3. 写入 `MetaState`
4. 可进入 `MetaProgressionScene`

### 12.5 中断续玩
1. 离开应用或主动保存时生成 `SuspendSaveState`
2. 记录 `scene_tag + RunState`
3. 主菜单点击继续
4. `SaveService` 恢复 `RunSession`
5. `FlowController` 直接跳回对应场景

## 13. 存档策略

### 13.1 局外档
持久化：
- `MetaState`
- 设置项
- 已完成成就与里程碑

### 13.2 中断档
持久化：
- `SuspendSaveState`
- 当前场景
- 当前单局 `RunState`

### 13.3 不持久化内容
- 纯 UI 动画状态
- 临时 hover / selection 状态
- 不影响继续游戏的瞬时表现数据

## 14. First Playable 范围对照

### 14.1 必做
- 五职业切换：`后端 / 前端 / 测试 / 算法 / 产品经理`
- 完整树图
- 战斗闭环
- 奖励 / 商店 / 事件 / 休息处 / Boss
- 职业解锁树展示
- 工位升级
- 中断续玩

### 14.2 扩展位
- HR 战斗接通
- 更复杂状态脚本
- 特殊事件链
- 更强演出

## 15. 验收场景

### 15.1 新开一局
从主菜单进入职业选择，选中后端/前端/测试/算法/产品经理任意一个，成功生成章节树图并进入首战。

### 15.2 五职业切换
五职业进入战斗时，起始牌组、初始遗物、职业资源面板与可用职业池过滤正确。

### 15.3 战斗结算
一场精英战胜利后进入奖励页，玩家选卡后回到地图，`RunState` 中的牌组、货币与访问节点均正确更新。

### 15.4 中断恢复
玩家在地图页或战斗页退出后，通过继续游戏回到对应场景并恢复当前单局状态。

## 16. 自检标准
- 工程师不需要额外口头说明，也能列出场景切换结构、核心服务和 `RunState` 组成
- Luban 章节足以直接建表与建立引用关系
- 战斗章节足以直接实现统一效果执行器、状态钩子和敌人意图系统
- 地图、奖励、商店、事件、局外成长的数据流完整闭环
- 文档明确区分 `First Playable` 与 `扩展预留`
- 文档与 `01_GAME_DESIGN_BRIEF.md` 的关系清楚：玩法真源在 `01`，工程优先级在 `02`

## 17. 默认假设
- `README.md` 缺失，因此本文件仅基于 `01_GAME_DESIGN_BRIEF.md` 与主提示约束
- 本次只设计 `02_SYSTEM_SPEC.md`，不落地代码
- 首个原型以 `后端 / 前端 / 测试 / 算法 / 产品经理` 五职业为准
- `HR` 只保留扩展位，不接入首个原型战斗流程
- 若后续要把 `HR` 纳入 First Playable，应作为本文件下一版扩展
