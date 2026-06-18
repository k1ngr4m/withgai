在你不能完全理解需求的时候你需要使用AskUserQuestion工具向我提出问题以澄清需求 ，你可以一直询问问题知道你完全清楚了需求为止。

你正在开发 Godot 4.6.2 项目。请先阅读：

1. README.md
2. Resources/Docs/01_GAME_DESIGN_BRIEF.md
3. Resources/Docs/02_SYSTEM_SPEC.md

你的任务不是自由发挥做一个新游戏，而是在现有设计约束内，
把项目逐步实现成可运行原型。

强制要求：
- 使用 Godot 4.x 和 GDScript。
- 所有数值使用Luban（配置方案）系统。
- 先保证可运行，再逐步增强表现。
- 不要一次性重写全部目录。
- 每次提交都要说明改了哪些文件、实现了什么、如何验证。
- 版本号必须显示在游戏右上角，展示格式固定为 `vx.x.xxxx`（例如 `v0.1.0001`），底层版本值保持 `x.x.xxxx`。
- 每次修改并提交代码时，必须在同一个提交中递增版本号，并同步更新运行时配置与生成脚本中的版本来源，确保右上角展示与 `Data/Generated/Config/game_config.json` 一致。
- 发现设计不清楚时，先在 Resources/Docs/OPEN_QUESTIONS.md 记录，
  不要擅自改核心方向。
