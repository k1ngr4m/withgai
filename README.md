# withgai

《withgai》是一款使用 Godot 4.x 开发的单人肉鸽卡牌原型。项目以现代写字楼为舞台，玩家扮演职场人从基层办公区一路爬楼到顶层，通过卡牌构筑、路线选择、事件、商店、休息与局外成长，对抗被 KPI、流程和会议异化的同事与上司。

当前工程目标是 First Playable：以后端职业为唯一公开可玩的完整闭环，其他职业保留为可见的锁定占位，并为后续扩展预留数据、UI 和部分机制测试覆盖。

## 当前范围

- 可玩职业：后端
- 占位职业：前端、测试、算法、产品经理、HR
- 已接入流程：主菜单、职业选择、地图、战斗、奖励、商店、随机事件、休息、结算、局外成长
- 已接入系统：中断续玩、局外存档、配置加载、奖励池、商店池、敌方意图、Boss 推进、基础 UI 动效和敌人帧动画
- 数据方案：`DataTables` CSV 源数据生成到 `Data/Generated/Config`，Godot 运行时通过 `ConfigService` 读取

## 技术栈

- 引擎：Godot 4.x（当前工程配置为 4.6）
- 语言：GDScript
- 配置：Luban 风格数据表 + 生成 JSON
- 生成脚本：Node.js ESM
- 可选工具：Luban 4.x、.NET 8、ImageMagick

## 目录结构

```text
.
├── Data/Generated/Config/      # Godot 运行时读取的生成配置
├── DataTables/                 # Luban/CSV 源数据与生成入口
├── Resources/
│   ├── Art/Generated/          # 生成美术资源、角色、敌人、图标、动画帧
│   ├── Codex/                  # 开发提示与阶段任务文档
│   └── Docs/                   # 设计文档、系统规格、资产与动效说明
├── Scenes/                     # Godot 场景文件
├── Scripts/
│   ├── Autoload/               # AppRoot 全局入口
│   ├── Generated/Config/       # Luban 生成的 GDScript schema
│   ├── Services/               # 配置、流程、战斗、地图、奖励、存档等服务
│   ├── Tests/                  # 轻量自动化测试入口
│   └── UI/                     # 各页面 UI 脚本
├── Tools/                      # 数据与动画资源生成脚本
└── project.godot               # Godot 工程配置
```

## 运行项目

1. 安装 Godot 4.x。
2. 用 Godot 打开本目录。
3. 运行主场景：

```text
res://Scenes/Main.tscn
```

工程的默认主场景已经配置为 `Scenes/Main.tscn`，全局入口为 `Scripts/Autoload/AppRoot.gd`。

## 命令行测试

如果本机 Godot 可执行文件在 `PATH` 中，可以运行：

```bash
godot --headless --path . -s Scripts/Tests/TestRunner.gd
```

测试入口会加载配置、验证关键场景资源、检查后端可玩流程、职业锁定规则、地图推进、战斗机制、奖励/商店/事件/休息、存档续玩、局外成长和 Boss 章节推进。

如果你的命令是 `godot4`，把上面的 `godot` 替换为 `godot4` 即可。

## 生成配置

刷新原型配置：

```bash
DataTables/gen_client.sh
```

该脚本会先执行：

```bash
node Tools/build_config.mjs
```

在没有 Luban 的情况下，它仍会刷新当前原型使用的 JSON 配置；如果设置了 `LUBAN_DLL` 或项目内存在 `Tools/Luban/Luban.dll`，脚本会继续生成 GDScript schema 和 per-table JSON，再由 `Tools/pack_luban_config.mjs` 打包到运行时配置。

可选环境变量：

- `LUBAN_DLL=/path/to/Luban.dll`
- `DOTNET_BIN=/path/to/dotnet`

## 生成敌人动画资源

敌人动画资源可由已有敌人立绘派生：

```bash
node Tools/build_enemy_animation_assets.mjs
```

该脚本会读取 `Data/Generated/Config/EnemyDef.json` 中的敌人美术路径，并为每个敌人生成 `idle`、`attack`、`hurt` 三组 2x2 帧表、透明帧表、GIF 预览和管线元数据。运行该脚本需要安装 ImageMagick，并确保 `magick` 命令可用。

## 重要文档

- `Resources/Docs/01_GAME_DESIGN_BRIEF.md`：玩法设计真源
- `Resources/Docs/02_SYSTEM_SPEC.md`：工程与系统规格
- `Resources/Docs/03_ASSETS_DESIGN_HELP.md`：资产设计辅助说明
- `Resources/Docs/04_ASSET_PROMPTS.md`：资产生成提示词
- `Resources/Docs/05_MOTION_DESIGN_MVP.md`：动效与动画 MVP 说明
- `Resources/Docs/IMPLEMENTATION_STATUS.md`：当前实现状态
- `DataTables/README.md`：数据表工作区说明

## 开发约定

- 核心玩法数据优先进入 `DataTables/Datas/*.csv`，再生成到 `Data/Generated/Config`。
- 场景脚本只负责表现和交互，运行时真状态由 `RunSession`、`BattleService`、`MapService`、`RewardService`、`MetaProgressionService` 等服务维护。
- First Playable 公开入口只允许后端职业进入完整单局；锁定职业可以保留 UI 展示、配置占位和内部机制测试。
- 修改数据表后，提交前建议重新运行 `DataTables/gen_client.sh`。
- 修改战斗、流程、存档、奖励或地图逻辑后，提交前建议运行 `Scripts/Tests/TestRunner.gd`。

## 当前开发重点

当前阶段主要围绕后端职业 First Playable 打磨：

- 完整爬楼流程的稳定性
- 战斗状态和中断续玩的正确恢复
- 奖励、商店、事件和休息页面的交互清晰度
- 后端服务/缓存机制的可读性和构筑空间
- 敌人动画、UI 动效和基础美术表现

长期目标是逐步开放前端、测试、算法、产品经理和 HR 的完整职业机制，并扩展更多敌人、事件、遗物、Boss 与平衡内容。
