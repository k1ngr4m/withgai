# 04_ASSET_PROMPTS

## 文档定位
- 项目代号：`withgai`
- 文档类型：AI 资产生成手册
- 主要用途：为项目中所有需要 AI 生成的美术资源提供可直接复制使用的 Prompt
- 上游设计源：
  - `Resources/Docs/01_GAME_DESIGN_BRIEF.md`
  - `Resources/Docs/02_SYSTEM_SPEC.md`
  - `Resources/Docs/03_ASSETS_DESIGN_HELP.md`
- 适用工具链：
  - 通用图像模型
  - `$generate2dsprite`
  - `$generate2dmap`

本文件服务于当前项目的 AI 美术资产生产，不是最终外包美术规范定稿。资源风格、资产边界、职业与敌人范围以 `01_GAME_DESIGN_BRIEF.md` 为准，First Playable 优先级以 `02_SYSTEM_SPEC.md` 为准。

## 1. 全局视觉规范

### 1.1 整体视觉语言
- 现代写字楼奇幻异化题材
- 明亮冷白办公照明 + 冷灰蓝环境基底
- 荒诞喜剧、轻度怪诞变异，而非写实职场恐怖
- 商业 2D 卡牌游戏主视觉，读图优先于写实质感
- 保留办公用品、公司制度、流程表单、会议道具等职场符号

### 1.2 角色风格
- 半写实商业 2D 插画风
- 比例正常，允许局部夸张
- 五官、发型、工位道具、姿态必须能快速辨认职业
- 服装基调接近现代互联网公司员工，但加入夸张道具和战斗化细节
- 避免过于 Q 版、过于写实摄影、过于二次元偶像化

### 1.3 敌人与 Boss 风格
- 从普通同事逐步过渡到制度怪物
- 保留人形基础和办公楼物件语言
- 第一章更像“奇怪的人”
- 第二章更像“管理结构拟人化”
- 第三章更像“公司制度本身异化成怪物”
- 不做纯抽象怪兽，不做中世纪奇幻怪

### 1.4 地图与场景风格
- 干净、可读性强的商业 2D 游戏背景
- 办公楼空间布局明确：工位、走廊、会议室、茶水间、电梯、总裁区
- 避免过度杂乱的小装饰导致可读性下降
- First Playable 以战斗背景、菜单背景、树图背景为主

### 1.5 UI 图形语言
- 冷白、灰蓝、玻璃感、系统提示橙、警示红、荧光绿混合
- 像企业后台、办公软件和卡牌界面的混血产物
- 直线、圆角矩形、薄描边、状态条、数据框、浮层卡片感
- 不走古风卷轴、不走纯幻想木纹金边

### 1.6 卡牌与图标风格
- 卡牌插画：主体单一、动作明确、适合竖向裁切
- 遗物图标：高对比、居中单体、透明背景、小尺寸可读
- 节点图标：抽象明确，能一眼看懂战斗/商店/休息/事件/Boss
- 状态图标：图形语言统一，减少微小细节

## 2. 工具选择说明

### 2.1 通用图像模型
推荐用于：
- 角色主立绘
- 战斗半身像
- 敌人和 Boss 主视觉
- 主菜单背景
- 职业选择页背景
- 战斗背景
- 结算页背景
- 成长页主视觉
- 事件插图
- 卡牌插画
- 遗物图标
- UI 装饰面板概念图

### 2.2 `$generate2dsprite`
推荐用于：
- 角色 sprite sheet 建议
- 战斗头像裁切基底
- 遗物图标透明资产
- 节点图标透明资产
- 状态图标风格批量生成
- 小型办公道具、可复用地图 props

### 2.3 `$generate2dmap`
推荐用于：
- 三章战斗背景
- 树图/楼层导航主背景
- 茶水间 / 休息处背景
- 自动贩卖机商店背景
- 办公室事件通用背景
- 若后续要扩成可编辑地图：基础办公楼探索场景

## 3. 通用 Prompt 约束

### 3.1 通用正向约束句
适用于通用图像模型：

```text
清晰 2D 商业卡牌游戏插画风，high readability, polished 2D game art, semi-realistic stylized illustration, clean silhouette, controlled lighting, crisp shapes, workplace fantasy satire, absurd office mutation, modern office material language, no photorealism, no 3D render look, no anime idol look
```

### 3.2 通用反向约束句
适用于通用图像模型：

```text
avoid photorealistic photography, avoid low detail, avoid blurry composition, avoid crowded background, avoid medieval fantasy armor, avoid sci-fi spaceship aesthetics, avoid horror gore, avoid text, avoid watermark, avoid logo, avoid UI overlay, avoid extra limbs, avoid deformed hands, avoid chibi proportions
```

### 3.3 Sprite 通用约束句
适用于 `$generate2dsprite`：

```text
solid #FF00FF magenta background, exact grid only, same character identity across frames, same body scale across frames, full body contained inside each cell, no text, no labels, no borders, no visible guide marks, clean commercial 2D sprite look
```

### 3.4 Map 通用约束句
适用于 `$generate2dmap`：

```text
clean HD 2D game background, readable office layout, no characters, no UI, no text, strong composition, clear spatial hierarchy, foundation or scenery only when required, preserve gameplay readability
```

## 4. 输出要求与命名规范

### 4.1 命名规则
- `char_`：角色主资源
- `enemy_`：普通敌人
- `elite_`：精英敌人
- `boss_`：Boss
- `bg_`：背景
- `ui_`：UI 主视觉或界面装饰
- `card_illust_`：卡牌插画
- `relic_icon_`：遗物图标
- `event_illust_`：事件插图
- `node_icon_`：节点图标
- `status_icon_`：状态图标

### 4.2 优先级标记
- `P0`：First Playable 必做
- `P1`：近期开工资源
- `P2`：扩展资源

### 4.3 输出要求说明
- 角色主立绘：竖图，建议 `1024x1536`
- 半身像 / 头像基底：正方或竖向，建议 `1024x1024`
- 战斗背景：横图，建议 `1920x1080`
- UI 背景：横图，建议 `1920x1080`
- 图标：透明背景，建议 `1024x1024`
- 卡牌插画：竖图，建议 `1024x1536`
- Sprite 建议：按技能规则，优先 `2x2` / `2x3` / `3x3` 多行 grid

### 4.4 统一字段模板
每个资产条目默认包含：
- `资产ID`
- `优先级`
- `资源名称`
- `用途`
- `推荐工具`
- `输出类型`
- `推荐尺寸`
- `Prompt`
- `Negative Prompt / 避免项`
- `输出要求`
- `备注`

### 4.5 逐资产与系列模板边界
- 以下内容必须逐资产单独写 Prompt：
  - `First Playable` 五职业主立绘、半身像、头像
  - `HR` 主立绘、半身像、头像
  - `9` 个普通敌人、`4` 个精英、`3` 个 Boss
  - 三章战斗背景、商店、休息处、通用事件底图、楼层导航背景
  - 主菜单、职业选择、战斗框体、五职业资源面板、结算页、成长页、奖励页
  - `First Playable` 五职业代表卡、程序员系共享卡、`HR` 代表卡
  - 程序员系共享遗物 `6`
  - 通用与职业倾向遗物池 `18`
  - `8` 个事件插图
- 以下内容允许使用同系列变体 Prompt：
  - 节点图标、状态图标、敌人头像、卡牌稀有度边框
  - 同职业的 sprite bundle
  - 非代表卡的后续批量扩写
- 若同名遗物在“程序员系共享遗物”和“通用遗物池”中都被采用，图标可以复用，但产出文件仍按实际配置表中的资源 ID 落盘。

## 5. 角色资源 Prompt

### 5.1 `char_backend_keyart`
- 优先级：`P0`
- 资源名称：后端主立绘
- 用途：职业选择、宣传图、立绘裁切
- 推荐工具：通用图像模型
- 输出类型：立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
一名“后端工程师”职业战斗主立绘，现代互联网公司男或中性员工形象，半写实商业 2D 卡牌游戏插画风，站在冷白办公楼走廊与服务器机柜前，角色穿深灰蓝连帽外套或程序员夹克，内搭简洁工牌和 T 恤，手持发光的 API 网关面板、缓存模块与数据流线缆，脚边浮现微缩服务节点、队列图标和日志屏幕碎片，姿态稳健、防守型、沉着、可靠，视觉上体现“部署服务、积累缓存、稳态压制”，都市写字楼奇幻感，冷灰蓝主色，荧光青与冷绿作为技术光效，干净构图，主体清晰，完整全身，适合裁切为卡牌游戏角色立绘，polished 2D game illustration, clean silhouette, controlled lighting, crisp material definition
```

- Negative Prompt / 避免项：

```text
avoid fantasy knight armor, avoid sci-fi space soldier, avoid horror gore, avoid medieval robe, avoid anime idol pose, avoid messy server room clutter, avoid extra limbs, avoid blurry face, avoid text and watermark
```

- 输出要求：
  - 完整单体角色
  - 背景可有但不抢主体
  - 预留上方与下方裁切空间
- 备注：
  - 对应 `01` 中后端职业
  - 主视觉要强调“稳态系统管理员”而非“黑客”

### 5.2 `char_backend_bust`
- 优先级：`P0`
- 资源名称：后端战斗半身像
- 用途：战斗 UI / 职业头像裁切
- 推荐工具：通用图像模型
- 输出类型：半身像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
后端工程师战斗半身像，半写实商业 2D 卡牌游戏角色头像，胸像构图，冷静表情，双手正在操控半透明服务面板与缓存层，肩部和手臂附近漂浮 API 网关、消息队列、日志窗口的小型 holographic office-tech elements，冷白办公灯照明，灰蓝与冷绿配色，简洁背景，主体清晰，适合战斗界面职业头像，clean commercial 2D card game portrait
```

- Negative Prompt / 避免项：

```text
avoid full-body composition, avoid busy background, avoid sci-fi helmet, avoid text, avoid logo
```

- 输出要求：
  - 半身清晰
  - 适合圆形或方形裁切

### 5.3 `char_backend_head_icon`
- 优先级：`P0`
- 资源名称：后端头像图标
- 用途：职业选择小图标
- 推荐工具：通用图像模型
- 输出类型：头像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
后端工程师头像图标，半写实商业 2D 游戏头像，正面或 3/4 正面，深灰蓝穿搭，冷静理性神情，身边有简化的服务节点与缓存环形发光元素，背景极简，图标可读性高，高对比，适合小尺寸 UI
```

- Negative Prompt / 避免项：

```text
avoid detailed background, avoid tiny props, avoid text, avoid watermark
```

- 输出要求：
  - 头部居中
  - 高对比

### 5.4 `char_backend_sprite_bundle`
- 优先级：`P1`
- 资源名称：后端角色 sprite 建议
- 用途：如后续做战斗内动态角色
- 推荐工具：`$generate2dsprite`
- 输出类型：hero_action_bundle
- 推荐尺寸：按工具默认
- Prompt：

```text
Use $generate2dsprite to create a side-view hero_action_bundle for a backend engineer battle character in clean_hd commercial 2D game style. Include separate action sheets for idle, run, skill-cast, and hurt. The character is a calm backend engineer with dark gray-blue office jacket, employee badge, compact tech gauntlet, floating service node accents, and controlled cache-like teal light effects kept close to the body. Keep body-only action sheets, no wide detached FX, no large slash arcs, no projectile in the body sheet, solid #FF00FF background, exact multi-row grids, consistent body scale across frames, stable feet line, clean silhouette, office fantasy technology style.
```

- Negative Prompt / 避免项：

```text
avoid pixel art, avoid long trails, avoid detached VFX, avoid oversized weapon, avoid row-mixed action atlas
```

- 输出要求：
  - 每个 action 独立 sheet
  - body-only

### 5.5 `char_frontend_keyart`
- 优先级：`P0`
- 资源名称：前端主立绘
- 用途：职业选择、宣传图
- 推荐工具：通用图像模型
- 输出类型：立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
一名“前端工程师”职业战斗主立绘，半写实商业 2D 卡牌游戏插画风，现代互联网公司员工造型，服装更有设计感和层次感，带有彩色组件、像素按钮、样式层叠的视觉元素，角色手持发光设计板、CSS 样式片段和组件卡片，动作轻快、灵活、回合内滚雪球感强，背景是明亮办公区和发光 UI 面板碎片，颜色以白、灰、亮青、亮蓝、柔和荧光橙为主，强调“连击、组件、样式层”，完整全身、主体清晰、适合卡牌游戏立绘
```

- Negative Prompt / 避免项：

```text
avoid cyberpunk neon overload, avoid anime magical girl, avoid abstract UI chaos, avoid photorealism, avoid text
```

- 输出要求：
  - 保留角色与组件元素层次
  - 适合竖图裁切

### 5.6 `char_frontend_bust`
- 优先级：`P0`
- 资源名称：前端战斗半身像
- 用途：战斗 UI
- 推荐工具：通用图像模型
- 输出类型：半身像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
前端工程师战斗半身像，半写实商业 2D 角色头像，胸像构图，灵活、自信、略带炫技感，周围漂浮组件卡片、样式层叠条带、按钮与动效碎片，明亮办公室光照，颜色更鲜活但仍是商业卡牌风，背景简洁，适合战斗界面职业头像
```

- Negative Prompt / 避免项：

```text
avoid full-body framing, avoid cluttered UI overlay, avoid childish cartoon look
```

- 输出要求：
  - 面部和组件都清晰可读

### 5.7 `char_frontend_head_icon`
- 优先级：`P0`
- 资源名称：前端头像图标
- 用途：职业选择小图标
- 推荐工具：通用图像模型
- 输出类型：头像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
前端工程师头像图标，半写实 2D 游戏头像，清爽有设计感的发型和服饰，周围有简化的组件方块和样式条带，图形感强，高对比，背景极简，适合小尺寸 UI
```

- Negative Prompt / 避免项：

```text
avoid tiny details, avoid long text, avoid messy neon background
```

- 输出要求：
  - 小尺寸可读

### 5.8 `char_frontend_sprite_bundle`
- 优先级：`P1`
- 资源名称：前端角色 sprite 建议
- 用途：后续动态表现
- 推荐工具：`$generate2dsprite`
- 输出类型：hero_action_bundle
- 推荐尺寸：按工具默认
- Prompt：

```text
Use $generate2dsprite to create a side-view hero_action_bundle for a frontend engineer battle character in clean_hd commercial 2D game sprite style. Include separate action sheets for idle, run, skill-cast, and attack. The character uses compact UI-card gestures, floating component blocks, and short attached style-layer effects kept close to the body. No detached wide VFX, no giant screen overlays, no long trails, solid #FF00FF background, exact multi-row action grids, stable body scale and clean office-tech silhouette.
```

- Negative Prompt / 避免项：

```text
avoid pixel art, avoid detached slash arc, avoid giant floating interface covering the body
```

- 输出要求：
  - action 分开
  - 紧凑 attached FX

### 5.9 `char_tester_keyart`
- 优先级：`P0`
- 资源名称：测试主立绘
- 用途：职业选择、宣传图
- 推荐工具：通用图像模型
- 输出类型：立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
一名“测试工程师”职业战斗主立绘，半写实商业 2D 卡牌游戏插画风，现代办公室员工造型，手持缺陷清单、日志平板、自动化测试框架模块，身边缠绕 Bug 警告、红色断言标识、绿色通过/失败提示和用例矩阵的图形碎片，角色表情敏锐、冷静、带一点审判感，姿态像在锁死敌人的系统漏洞，背景为冷白办公室与异常报警屏，主色为灰白、红、黄、荧光绿，强调“Bug、用例、校验、回归”，完整全身，主体清晰
```

- Negative Prompt / 避免项：

```text
avoid hacker stereotype, avoid lab scientist cliché, avoid horror glitch gore, avoid text-heavy screens, avoid photorealism
```

- 输出要求：
  - 让职业识别点清晰
  - 避免背景信息过多

### 5.10 `char_tester_bust`
- 优先级：`P0`
- 资源名称：测试战斗半身像
- 用途：战斗 UI
- 推荐工具：通用图像模型
- 输出类型：半身像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
测试工程师战斗半身像，半写实商业 2D 角色头像，胸像构图，角色正盯着敌方缺陷列表与报错提示，周围漂浮红色 bug 标记、绿色用例通过框、黄色警告标签，办公光照，背景简洁，商业卡牌游戏战斗头像风格
```

- Negative Prompt / 避免项：

```text
avoid messy monitor wall, avoid tiny unreadable symbols, avoid cartoon exaggeration
```

- 输出要求：
  - 可裁成头像

### 5.11 `char_tester_head_icon`
- 优先级：`P0`
- 资源名称：测试头像图标
- 用途：职业选择小图标
- 推荐工具：通用图像模型
- 输出类型：头像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
测试工程师头像图标，半写实 2D 游戏头像，冷静怀疑式表情，身边有简化 bug 符号、对勾和警告框，高对比，背景极简，小尺寸可读
```

- Negative Prompt / 避免项：

```text
avoid clutter, avoid unreadable micro details, avoid text
```

- 输出要求：
  - 简洁明确

### 5.12 `char_tester_sprite_bundle`
- 优先级：`P1`
- 资源名称：测试角色 sprite 建议
- 用途：后续动态表现
- 推荐工具：`$generate2dsprite`
- 输出类型：hero_action_bundle
- 推荐尺寸：按工具默认
- Prompt：

```text
Use $generate2dsprite to create a side-view hero_action_bundle for a tester engineer battle character in clean_hd commercial 2D game style. Include separate action sheets for idle, run, debuff-cast, and hurt. The character uses compact clipboard, tablet, and warning-tag motions, with attached bug marker effects kept close to the body. No detached large VFX, no giant glitch clouds, solid #FF00FF background, exact multi-row grids, consistent body scale, stable feet line, readable QA-office silhouette.
```

- Negative Prompt / 避免项：

```text
avoid pixel art, avoid giant floating symbols, avoid wide detached effects
```

- 输出要求：
  - 以 debuff-cast 为重点

### 5.13 `char_algorithm_keyart`
- 优先级：`P0`
- 资源名称：算法主立绘
- 用途：职业选择、宣传图
- 推荐工具：通用图像模型
- 输出类型：立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
一名“算法工程师”职业战斗主立绘，半写实商业 2D 卡牌游戏插画风，现代互联网公司员工造型但带有高强度算力与推理气场，角色周围漂浮矩阵、路径图、复杂度符号、算力核心与几何计算光轨，姿态冷峻专注，像在压缩战场并推导最优解，背景为总裁区或高层办公室中的抽象计算空间，主色为白、深灰、冷蓝、荧光紫蓝少量点缀，强调“算力、复杂度、终结”，完整全身、构图清晰
```

- Negative Prompt / 避免项：

```text
avoid wizard fantasy robe, avoid cyberpunk hacker room, avoid magical rune overload, avoid text
```

- 输出要求：
  - 保留现代办公室身份
  - 不要变成纯科幻法师

### 5.14 `char_algorithm_bust`
- 优先级：`P0`
- 资源名称：算法战斗半身像
- 用途：战斗 UI
- 推荐工具：通用图像模型
- 输出类型：半身像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
算法工程师战斗半身像，半写实商业 2D 角色头像，胸像构图，表情专注严谨，周围有简化矩阵、路径线、算力核心和复杂度层级图形，背景极简，冷蓝灰配色，商业卡牌战斗头像风格
```

- Negative Prompt / 避免项：

```text
avoid fantasy mage look, avoid chaotic equations everywhere, avoid messy background
```

- 输出要求：
  - 头像级清晰

### 5.15 `char_algorithm_head_icon`
- 优先级：`P0`
- 资源名称：算法头像图标
- 用途：职业选择小图标
- 推荐工具：通用图像模型
- 输出类型：头像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
算法工程师头像图标，半写实 2D 游戏头像，冷静高智感，周围有简化矩阵格、路径箭头和算力亮点，高对比，背景极简，适合小尺寸 UI
```

- Negative Prompt / 避免项：

```text
avoid tiny formulas, avoid text, avoid cluttered sci-fi interface
```

- 输出要求：
  - 小图标清晰

### 5.16 `char_algorithm_sprite_bundle`
- 优先级：`P1`
- 资源名称：算法角色 sprite 建议
- 用途：后续动态表现
- 推荐工具：`$generate2dsprite`
- 输出类型：hero_action_bundle
- 推荐尺寸：按工具默认
- Prompt：

```text
Use $generate2dsprite to create a side-view hero_action_bundle for an algorithm engineer battle character in clean_hd commercial 2D game style. Include separate action sheets for idle, run, charge, and cast. The character uses compact geometric compute effects, matrix core glow, and attached logic-wave accents kept close to the body. No giant magic circles, no detached long trails, solid #FF00FF background, exact multi-row grids, stable body scale, readable office-intellectual silhouette.
```

- Negative Prompt / 避免项：

```text
avoid pixel art, avoid giant fantasy spell circle, avoid detached VFX clouds
```

- 输出要求：
  - charge / cast 是重点

### 5.17 `char_product_manager_keyart`
- 优先级：`P0`
- 资源名称：产品经理主立绘
- 用途：职业选择、宣传图
- 推荐工具：通用图像模型
- 输出类型：立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
一名“产品经理”职业战斗主立绘，半写实商业 2D 卡牌游戏插画风，现代互联网公司中层员工造型，穿利落商务休闲装，手持 PRD 文档、优先级面板、路线图卡片和会议纪要，姿态像在重排整个战场秩序，周围漂浮需求变更箭头、优先级标签、会议日程和目标重定向线条，神情自信、说服力强、略带操控感，背景是会议室与办公楼高层玻璃空间，主色为灰白、商务蓝、警示橙、少量红色修订标记，强调“需求变更、优先级、控制”，完整全身，商业卡牌主视觉
```

- Negative Prompt / 避免项：

```text
avoid villain suit stereotype, avoid evil CEO look, avoid too much text on props, avoid anime office romance style, avoid photorealism
```

- 输出要求：
  - 职场权力感清晰
  - 但仍是玩家职业，不是反派

### 5.18 `char_product_manager_bust`
- 优先级：`P0`
- 资源名称：产品经理战斗半身像
- 用途：战斗 UI
- 推荐工具：通用图像模型
- 输出类型：半身像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
产品经理战斗半身像，半写实商业 2D 角色头像，胸像构图，角色一手拿会议纪要、一手重排优先级卡片，周围漂浮需求变更箭头、路线图、标签和会议指令，气质沉着、善于控制局势，背景简洁，适合卡牌战斗界面职业头像
```

- Negative Prompt / 避免项：

```text
avoid text-heavy notes, avoid messy whiteboard, avoid exaggerated villain grin
```

- 输出要求：
  - 脸部和控制道具清晰

### 5.19 `char_product_manager_head_icon`
- 优先级：`P0`
- 资源名称：产品经理头像图标
- 用途：职业选择小图标
- 推荐工具：通用图像模型
- 输出类型：头像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
产品经理头像图标，半写实 2D 游戏头像，商务休闲穿搭，精明自信表情，身边有简化优先级标签、箭头和路线图符号，高对比、背景极简，适合小尺寸 UI
```

- Negative Prompt / 避免项：

```text
avoid tiny text, avoid clutter, avoid overcomplicated charts
```

- 输出要求：
  - 高识别度

### 5.20 `char_product_manager_sprite_bundle`
- 优先级：`P1`
- 资源名称：产品经理角色 sprite 建议
- 用途：后续动态表现
- 推荐工具：`$generate2dsprite`
- 输出类型：hero_action_bundle
- 推荐尺寸：按工具默认
- Prompt：

```text
Use $generate2dsprite to create a side-view hero_action_bundle for a product manager battle character in clean_hd commercial 2D game style. Include separate action sheets for idle, run, command-cast, and hurt. The character uses clipboard, route-map cards, and compact priority-arrow effects kept close to the body. No giant detached charts, no wide UI panels, solid #FF00FF background, exact multi-row grids, consistent scale, stable feet line, sharp office-management silhouette.
```

- Negative Prompt / 避免项：

```text
avoid pixel art, avoid giant floating dashboard, avoid detached interface wall
```

- 输出要求：
  - command-cast 需要突出“重排战场”

### 5.21 `char_hr_keyart`
- 优先级：`P2`
- 资源名称：HR 主立绘
- 用途：扩展职业立绘
- 推荐工具：通用图像模型
- 输出类型：立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
一名“HR”职业战斗主立绘，半写实商业 2D 卡牌游戏插画风，现代企业 HR 造型，手持年度考评表、绩效档案、候选人黑名单与优化名单，姿态优雅但危险，周围有考核章、合规标签、绩效箭头和裁撤指示，主色为灰白、酒红、深蓝、警示红，强调“绩效、优化名单、收割、组织控制”，背景为人事会议室或合规审查空间，完整全身，主体清晰
```

- Negative Prompt / 避免项：

```text
avoid demon queen look, avoid gore, avoid photoreal corporate portrait, avoid excessive paperwork text
```

- 输出要求：
  - 明确是扩展职业

### 5.22 `char_hr_bust`
- 优先级：`P2`
- 资源名称：HR 战斗半身像
- 用途：扩展职业 UI 头像
- 推荐工具：通用图像模型
- 输出类型：半身像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
HR 战斗半身像，半写实商业 2D 角色头像，胸像构图，冷静审视表情，周围有绩效印章、优化名单标记和合规边框，背景极简，适合卡牌战斗头像
```

- Negative Prompt / 避免项：

```text
avoid horror monster face, avoid text blocks, avoid cluttered office wall
```

- 输出要求：
  - 可扩展使用

### 5.23 `char_hr_head_icon`
- 优先级：`P2`
- 资源名称：HR 头像图标
- 用途：扩展职业选择小图标
- 推荐工具：通用图像模型
- 输出类型：头像
- 推荐尺寸：`1024x1024`
- Prompt：

```text
HR 头像图标，半写实 2D 游戏头像，冷静审视、克制但危险的表情，商务人事风穿搭，身边有简化的绩效印章、档案夹和优化名单符号，背景极简，高对比，小尺寸 UI 可读
```

- Negative Prompt / 避免项：

```text
avoid horror monster face, avoid tiny text blocks, avoid cluttered office background
```

- 输出要求：
  - 头部居中
  - 小图标清晰

### 5.24 `char_hr_sprite_bundle`
- 优先级：`P2`
- 资源名称：HR 角色 sprite 建议
- 用途：扩展职业后续动态表现
- 推荐工具：`$generate2dsprite`
- 输出类型：hero_action_bundle
- 推荐尺寸：按工具默认
- Prompt：

```text
Use $generate2dsprite to create a side-view hero_action_bundle for an HR battle character in clean_hd commercial 2D game style. Include separate action sheets for idle, run, execute-cast, and hurt. The character uses compact folder, stamp, and performance-review effects kept close to the body. No giant paper storm, no detached wide VFX, solid #FF00FF background, exact multi-row grids, consistent body scale, stable feet line, sharp corporate-control silhouette.
```

- Negative Prompt / 避免项：

```text
avoid pixel art, avoid giant paperwork wall, avoid detached red effect clouds
```

- 输出要求：
  - execute-cast 要体现“收割”与“审查”

## 6. 敌人与 Boss Prompt

### 6.1 普通敌人 `enemy_slacker_coworker`
- 优先级：`P0`
- 资源名称：摸鱼同事
- 用途：普通敌人战斗立绘 / 头像
- 推荐工具：通用图像模型
- 输出类型：角色立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“摸鱼同事”敌人立绘，半写实商业 2D 卡牌敌人插画，现代办公室员工，坐姿或斜靠工位，表情懒散但狡猾，手边有刷手机、零食、工位隔板和临时堆起的防线杂物，视觉上体现“偶尔不攻击却拖慢节奏”，荒诞职场喜剧风，明亮办公区背景简化，主体清晰
```

- Negative Prompt / 避免项：

```text
avoid zombie look, avoid exaggerated monster claws, avoid horror tone
```

- 输出要求：
  - 可裁头像

### 6.2 `enemy_workaholic_coworker`
- 优先级：`P0`
- 资源名称：卷王同事
- 用途：普通敌人
- 推荐工具：通用图像模型
- 输出类型：敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“卷王同事”敌人立绘，半写实商业 2D 卡牌敌人插画，现代互联网公司员工，眼神亢奋、动作很快，背着电脑包和多台设备，双手狂敲键盘或同时处理多个工单，办公用品像连击武器一样飞舞，视觉上体现高速多段攻击，明亮办公区，荒诞但可读
```

- Negative Prompt / 避免项：

```text
avoid superhero costume, avoid cyber ninja, avoid horror mutation overload
```

- 输出要求：
  - 动势强

### 6.3 `enemy_angry_cleaner`
- 优先级：`P0`
- 资源名称：暴躁保洁阿姨
- 用途：普通敌人
- 推荐工具：通用图像模型
- 输出类型：敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“暴躁保洁阿姨”敌人立绘，半写实商业 2D 卡牌敌人插画，保洁制服，手持拖把、水桶、清洁喷壶像重型武器，表情强势凶悍但不是恐怖怪物，地面水痕和清洁用品形成高压单次打击感，办公楼走廊背景，主体清晰
```

- Negative Prompt / 避免项：

```text
avoid demon janitor, avoid gore, avoid slapstick cartoon proportions
```

- 输出要求：
  - 人物气势明显

### 6.4 `enemy_salesman`
- 优先级：`P0`
- 资源名称：西装推销员
- 用途：普通敌人
- 推荐工具：通用图像模型
- 输出类型：敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“西装推销员”敌人立绘，半写实商业 2D 卡牌敌人插画，穿夸张合身西装，双手递出套餐方案、合同和销售话术卡片，周围漂浮低价值污染卡牌感的纸张与合同，姿态热情到压迫，现代写字楼大厅或办公区背景
```

- Negative Prompt / 避免项：

```text
avoid mafia look, avoid gun, avoid horror salesman grin
```

- 输出要求：
  - 污染感来自合同和提案，不是魔法

### 6.5 `enemy_process_specialist`
- 优先级：`P1`
- 资源名称：流程专员
- 用途：普通敌人
- 推荐工具：通用图像模型
- 输出类型：敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“流程专员”敌人立绘，半写实商业 2D 卡牌敌人插画，现代流程管理人员造型，手持审批流面板、流程图、印章和层层叠叠的制度边框，视觉上体现不断加盾和拖长战斗，办公流程空间背景，主体清晰
```

- Negative Prompt / 避免项：

```text
avoid fantasy priest, avoid abstract flowchart-only image, avoid unreadable paperwork clutter
```

- 输出要求：
  - 体现“流程就是护甲”

### 6.6 `enemy_performance_inspector`
- 优先级：`P1`
- 资源名称：绩效监察
- 用途：普通敌人
- 推荐工具：通用图像模型
- 输出类型：敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“绩效监察”敌人立绘，半写实商业 2D 卡牌敌人插画，手持考核表、红笔和统计面板，眼神审视，姿态像在盯着玩家每一张牌的效率，背景是中层管理区办公环境，冷白光，带考核压迫感
```

- Negative Prompt / 避免项：

```text
avoid police uniform, avoid judge wig, avoid horror office torture
```

- 输出要求：
  - 审视感强

### 6.7 `enemy_meeting_maniac`
- 优先级：`P1`
- 资源名称：开会狂人
- 用途：普通敌人
- 推荐工具：通用图像模型
- 输出类型：敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“开会狂人”敌人立绘，半写实商业 2D 卡牌敌人插画，现代办公室员工，周围环绕会议纪要、投影页、议程卡和发言气泡形状的怪诞纸片，像在召唤会议衍生物，会议室背景，主体明确
```

- Negative Prompt / 避免项：

```text
avoid giant speech bubble with text, avoid horror cult leader look
```

- 输出要求：
  - 召唤感可读

### 6.8 `enemy_airdrop_director`
- 优先级：`P1`
- 资源名称：空降总监
- 用途：普通敌人 / 准精英感
- 推荐工具：通用图像模型
- 输出类型：敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“空降总监”敌人立绘，半写实商业 2D 卡牌敌人插画，高层管理者姿态，穿更精致的商务外套，手中拿着调整组织结构的命令板和训话文件，视觉上兼具攻击姿态与说教压迫，背景是更高层办公区，气场强
```

- Negative Prompt / 避免项：

```text
avoid CEO final boss scale, avoid villain throne scene
```

- 输出要求：
  - 高层管理压迫感

### 6.9 `enemy_compliance_judge`
- 优先级：`P1`
- 资源名称：合规审判官
- 用途：普通敌人 / 顶层区域
- 推荐工具：通用图像模型
- 输出类型：敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“合规审判官”敌人立绘，半写实商业 2D 卡牌敌人插画，制度执行者形象，手持合规清单、边框印章、审批封条与高压条款，视觉上像会清除玩家增益并塞入污染，背景是冰冷高层审查空间
```

- Negative Prompt / 避免项：

```text
avoid fantasy judge fantasy costume, avoid chains and torture imagery, avoid religious imagery
```

- 输出要求：
  - 合规高压感

### 6.10 `elite_airdrop_project_lead`
- 优先级：`P0`
- 资源名称：空降项目组长
- 用途：精英敌人
- 推荐工具：通用图像模型
- 输出类型：精英敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“空降项目组长”精英敌人立绘，半写实商业 2D 卡牌精英插画，现代中层管理者与项目统筹者形象，身边漂浮 deadline 倒计时、工期进度条、紧急项目红框和任务瀑布图，动作压迫感强，像在逼近巨额爆发，办公楼项目战情室背景，精英敌人体量感更强
```

- Negative Prompt / 避免项：

```text
avoid generic office worker, avoid final boss scale, avoid sci-fi commander
```

- 输出要求：
  - 精英感明显

### 6.11 `elite_outsource_manager`
- 优先级：`P1`
- 资源名称：外包统筹经理
- 用途：精英敌人
- 推荐工具：通用图像模型
- 输出类型：精英敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“外包统筹经理”精英敌人立绘，半写实商业 2D 卡牌精英插画，西装与项目夹板并存，身边有多个被调度的小型任务分身和协同指令卡，视觉上体现召唤杂兵和强化协同，现代办公空间背景
```

- Negative Prompt / 避免项：

```text
avoid mafia boss look, avoid chaotic swarm mess
```

- 输出要求：
  - 有召唤感

### 6.12 `elite_budget_gatekeeper`
- 优先级：`P1`
- 资源名称：预算守门人
- 用途：精英敌人
- 推荐工具：通用图像模型
- 输出类型：精英敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“预算守门人”精英敌人立绘，半写实商业 2D 卡牌精英插画，手握预算表、财务封条、成本红线和审批锁链，视觉上体现压缩绩效点收益与资源卡死，背景为冷白财务审批空间
```

- Negative Prompt / 避免项：

```text
avoid bank robber theme, avoid fantasy treasure keeper
```

- 输出要求：
  - 资源压迫感强

### 6.13 `elite_approval_eye`
- 优先级：`P1`
- 资源名称：审批流之眼
- 用途：精英敌人
- 推荐工具：通用图像模型
- 输出类型：精英敌人立绘
- 推荐尺寸：`1024x1536`
- Prompt：

```text
“审批流之眼”精英敌人立绘，半写实商业 2D 卡牌精英插画，制度怪物化程度更高，一个由审批框、勾选框、章印、流程箭头构成的巨大监视之眼，仍保留写字楼制度感而非纯奇幻魔眼，背景为顶层冷白审查空间，压迫感强
```

- Negative Prompt / 避免项：

```text
avoid Lovecraft horror, avoid gore eyeball monster, avoid medieval demon eye
```

- 输出要求：
  - 怪物化但仍有职场符号

### 6.14 `boss_pitch_supervisor`
- 优先级：`P0`
- 资源名称：画饼主管
- 用途：第一章 Boss
- 推荐工具：通用图像模型
- 输出类型：Boss 主立绘
- 推荐尺寸：`1280x1600`
- Prompt：

```text
“画饼主管”Boss 主立绘，半写实商业 2D 卡牌 Boss 插画，现代中层主管形象但已异化，手持巨大的路线图、期权饼图、承诺卷轴和话术扩音器，周围漂浮“明年提拔你”“长期激励”感的空洞承诺纸片与漂亮饼状图，体量比普通敌人大，姿态夸张、自信、操控感强，办公区被其话术和项目规划扭曲成夸张舞台，明亮但压迫，适合作为第一章 Boss 战斗主视觉
```

- Negative Prompt / 避免项：

```text
avoid final cosmic boss scale, avoid text-heavy chart, avoid horror flesh mutation
```

- 输出要求：
  - 可裁为头像
  - 可后续拆阶段变体

### 6.15 `boss_mutant_hr`
- 优先级：`P1`
- 资源名称：变异HR
- 用途：第二章 Boss
- 推荐工具：通用图像模型
- 输出类型：Boss 主立绘
- 推荐尺寸：`1280x1600`
- Prompt：

```text
“变异HR”Boss 主立绘，半写实商业 2D 卡牌 Boss 插画，人事与制度的怪物化身，身后展开巨大绩效考核树、优化名单卷轴、合规边框与资源抽取装置，角色兼具优雅与危险，像会审视、削减、筛选一切，背景是冷白审查会议室与高层管理空间，体量强，制度恐怖但仍保持商业美术可读性
```

- Negative Prompt / 避免项：

```text
avoid gore horror monster, avoid demon queen cliché, avoid medieval fantasy judge
```

- 输出要求：
  - 中章 Boss 强压迫感

### 6.16 `boss_mutant_ceo`
- 优先级：`P1`
- 资源名称：变异总裁
- 用途：终章 Boss
- 推荐工具：通用图像模型
- 输出类型：Boss 主立绘
- 推荐尺寸：`1280x1600`
- Prompt：

```text
“变异总裁”Boss 主立绘，半写实商业 2D 卡牌终极 Boss 插画，公司资本意志与制度怪物的化身，巨大的总裁人形轮廓结合会议纪要、流程附件、组织结构图、审批封印、全员大会投影与冷白玻璃高层空间，体量最强，气场压倒性，既像人又像整栋写字楼的控制中枢，商业卡牌终局 Boss 质感，清晰主体，适合战斗立绘
```

- Negative Prompt / 避免项：

```text
avoid sci-fi mech overlord, avoid gore apocalypse monster, avoid abstract incomprehensible shape
```

- 输出要求：
  - 必须保留人形与公司制度感
  - 允许后续拆成阶段变体

## 7. 地图与场景 Prompt

### 7.1 `bg_battle_ch1_open_office`
- 优先级：`P0`
- 资源名称：第一章基层办公区战斗背景
- 用途：战斗背景
- 推荐工具：`$generate2dmap`
- 输出类型：baked battle background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
Use $generate2dmap to create a baked_scene_mode battle background for chapter 1 of a workplace roguelike card game. Create a clean HD 2D commercial card-game battle background of a bright open-plan office floor, with workstations, low partitions, office chairs, fluorescent white lighting, copier corners, glass meeting pods in the distance, and subtle surreal pressure in the space. This is a flat battle background only, no characters, no UI, no text, no readable signage, no gameplay props that must be edited separately, high readability, wide cinematic composition, absurd office satire atmosphere, polished 2D game background.
```

- Negative Prompt / 避免项：

```text
avoid pixel art, avoid crowded desks everywhere, avoid horror blood, avoid empty white void, avoid perspective confusion
```

- 输出要求：
  - 仅背景
  - 中景可读
  - 留出卡牌战斗 UI 空间

### 7.2 `bg_battle_ch2_management_zone`
- 优先级：`P0`
- 资源名称：第二章中层管理区战斗背景
- 用途：战斗背景
- 推荐工具：`$generate2dmap`
- 输出类型：baked battle background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
Use $generate2dmap to create a baked_scene_mode battle background for chapter 2 of a workplace roguelike card game. Create a clean HD 2D commercial battle background of a middle-management office zone with glass meeting rooms, approval desks, KPI screens, performance dashboards, long corridor sightlines, and controlled cold white lighting. The atmosphere should feel more pressurized and bureaucratic than chapter 1, but still readable and polished. No characters, no UI, no text, no baked gameplay props, strong office hierarchy feel, absurd corporate satire.
```

- Negative Prompt / 避免项：

```text
avoid pixel art, avoid cyberpunk control room, avoid horror lab, avoid cluttered unreadable monitors
```

- 输出要求：
  - 比第一章更冷、更压迫

### 7.3 `bg_battle_ch3_ceo_floor`
- 优先级：`P0`
- 资源名称：第三章总裁区战斗背景
- 用途：战斗背景
- 推荐工具：`$generate2dmap`
- 输出类型：baked battle background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
Use $generate2dmap to create a baked_scene_mode battle background for chapter 3 of a workplace roguelike card game. Create a clean HD 2D commercial boss-floor battle background of a top corporate executive zone: glass, steel, marble-like office luxury, giant meeting screen walls, cold white architectural lighting, panoramic city skyline, central confrontation area, and subtle surreal distortion that makes the space feel like the headquarters of a living company machine. No characters, no UI, no readable text, no edited runtime props, polished 2D card-game background.
```

- Negative Prompt / 避免项：

```text
avoid sci-fi spaceship bridge, avoid fantasy throne room, avoid horror flesh mutation architecture
```

- 输出要求：
  - 终章压迫感
  - 中心战斗区明确

### 7.4 `bg_rest_break_room`
- 优先级：`P0`
- 资源名称：茶水间 / 休息处背景
- 用途：休息节点
- 推荐工具：`$generate2dmap`
- 输出类型：baked scene background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
Use $generate2dmap to create a baked_scene_mode rest-area background for a workplace roguelike card game. Create a clean HD 2D office break room scene with coffee machine, water dispenser, fridge, snacks, disposable cups, casual chairs, and a small sense of temporary safety inside a pressured office building. Bright but slightly weary atmosphere, no characters, no UI, no text, polished 2D game scene, readable composition.
```

- Negative Prompt / 避免项：

```text
avoid empty sterile room, avoid cozy home kitchen, avoid horror restroom, avoid text labels
```

- 输出要求：
  - 轻松但仍属办公楼

### 7.5 `bg_shop_vending_machine`
- 优先级：`P0`
- 资源名称：自动贩卖机商店背景
- 用途：商店节点
- 推荐工具：`$generate2dmap`
- 输出类型：baked scene background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
Use $generate2dmap to create a baked_scene_mode shop background for a workplace roguelike card game. Create a clean HD 2D office vending-machine corridor scene with bright vending machines, convenience shelves, dim corporate hallway depth, product glow, and a slightly illicit late-night purchase feeling. No characters, no UI, no text, polished 2D commercial game background, readable shop staging.
```

- Negative Prompt / 避免项：

```text
avoid convenience store street scene, avoid cyberpunk neon alley, avoid horror darkness
```

- 输出要求：
  - 适合作为商店页底图

### 7.6 `bg_event_generic_office`
- 优先级：`P1`
- 资源名称：事件页通用办公室背景
- 用途：事件节点底图
- 推荐工具：`$generate2dmap`
- 输出类型：baked scene background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
Use $generate2dmap to create a baked_scene_mode generic event background for a workplace roguelike card game. Create a clean HD 2D corporate office scene that can support multiple event texts: a semi-empty office corridor with doors, meeting room glass, printer corner, and suspicious quiet atmosphere. No characters, no UI, no text, enough neutral negative space for dialogue panels, polished 2D game background.
```

- Negative Prompt / 避免项：

```text
avoid heavy story-specific props, avoid horror scene, avoid crowded desks
```

- 输出要求：
  - 通用性高

### 7.7 `bg_map_floor_navigation`
- 优先级：`P0`
- 资源名称：楼层导航 / 树图主背景
- 用途：MapScene 背景
- 推荐工具：通用图像模型
- 输出类型：UI background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
写字楼肉鸽卡牌游戏的楼层导航主背景，清晰 2D 商业 UI 背景，俯视或半俯视的高层办公楼纵向结构示意感，但不是技术蓝图，像一张被转化成卡牌 roguelike 树图底板的企业楼层导览海报。画面包含楼层、走廊、会议室、工位、玻璃电梯井和路径感，但不直接画节点图标，不要文字，不要 UI 元素。冷白、灰蓝、微量警示橙点缀，现代办公楼、晋升路径、公司系统感，留出中央和左右侧给节点与路径 UI 使用。
```

- Negative Prompt / 避免项：

```text
avoid blueprint-only look, avoid unreadable architecture complexity, avoid text labels, avoid fantasy castle tower
```

- 输出要求：
  - 适合叠加树图节点
  - 中央留白

## 8. UI 与界面部件 Prompt

### 8.1 `ui_main_menu_bg`
- 优先级：`P0`
- 资源名称：主菜单主视觉背景
- 用途：主菜单
- 推荐工具：通用图像模型
- 输出类型：UI background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
写字楼肉鸽卡牌游戏主菜单背景，清晰 2D 商业游戏主视觉，现代高层办公楼夜间仍灯火通明，整栋楼像有生命一样被 KPI、会议日程、审批流和数据光带轻度异化，荒诞职场喜剧气质，不做恐怖片。画面要有主视觉冲击，但保留中央标题和菜单按钮的留白区域，冷白、灰蓝、荧光绿、警示红少量点缀，polished 2D card game menu art
```

- Negative Prompt / 避免项：

```text
avoid full horror tower, avoid cyberpunk city overload, avoid text logo, avoid characters occupying center UI space
```

- 输出要求：
  - 中央和下方留菜单空间

### 8.2 `ui_class_select_bg`
- 优先级：`P0`
- 资源名称：职业选择页背景
- 用途：ClassSelectScene
- 推荐工具：通用图像模型
- 输出类型：UI background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
职业选择页背景，清晰 2D 商业卡牌游戏 UI 场景，像公司内部晋升与岗位展示大厅，被包装成一个荒诞职场战斗准备空间。背景包含玻璃展示墙、职业站位平台、冷白灯光、岗位图形元素和轻微数据流，现代办公楼高级感，留出左右展示角色与中央说明区域，不要文字，不要 UI 组件本体。
```

- Negative Prompt / 避免项：

```text
avoid stage show glamor, avoid fantasy guild hall, avoid crowded objects
```

- 输出要求：
  - 左右角色位明确

### 8.3 `ui_battle_frame_style`
- 优先级：`P0`
- 资源名称：战斗页框体风格图
- 用途：BattleScene 装饰参考
- 推荐工具：通用图像模型
- 输出类型：UI panel concept
- 推荐尺寸：`1920x1080`
- Prompt：

```text
一张写字楼主题 roguelike 卡牌战斗界面装饰风格图，清晰 2D 商业游戏 UI concept，展示冷白办公系统风、灰蓝玻璃面板、薄描边信息框、卡牌槽位、敌方意图区、职业资源区、日志区、按钮区的统一图形语言。不要完整 UI 截图，不要文字，不要角色，只展示高质量界面框体、分区和装饰质感参考，现代企业系统与卡牌 RPG 融合风格。
```

- Negative Prompt / 避免项：

```text
avoid fantasy parchment UI, avoid mobile casual candy UI, avoid cyberpunk overload, avoid text
```

- 输出要求：
  - 用于提炼 UI 图形语言

### 8.4 `ui_resource_panel_backend`
- 优先级：`P0`
- 资源名称：后端资源面板装饰
- 用途：战斗职业资源区
- 推荐工具：通用图像模型
- 输出类型：UI element concept
- 推荐尺寸：`1024x1024`
- Prompt：

```text
后端职业资源面板装饰设计，清晰 2D 商业游戏 UI element，表现“服务 / 缓存”主题，像企业技术监控面板与卡牌战斗资源条的混合，灰蓝框体、冷绿缓存环、服务节点插槽、简洁高可读，不要文字，不要角色，透明背景友好构图
```

- Negative Prompt / 避免项：

```text
avoid full-screen dashboard, avoid tiny charts, avoid text labels
```

- 输出要求：
  - 可拆成装饰元素

### 8.5 `ui_resource_panel_frontend`
- 优先级：`P0`
- 资源名称：前端资源面板装饰
- 用途：战斗职业资源区
- 推荐工具：通用图像模型
- 输出类型：UI element concept
- 推荐尺寸：`1024x1024`
- Prompt：

```text
前端职业资源面板装饰设计，清晰 2D 商业游戏 UI element，表现“组件 / 样式层”主题，像设计系统和样式堆叠模块的视觉化资源条，亮蓝、白、柔和青色、少量橙色点缀，模块感强，简洁可读，不要文字，不要角色
```

- Negative Prompt / 避免项：

```text
avoid full website screenshot, avoid cluttered buttons everywhere
```

- 输出要求：
  - 强模块感

### 8.6 `ui_resource_panel_tester`
- 优先级：`P0`
- 资源名称：测试资源面板装饰
- 用途：战斗职业资源区
- 推荐工具：通用图像模型
- 输出类型：UI element concept
- 推荐尺寸：`1024x1024`
- Prompt：

```text
测试职业资源面板装饰设计，清晰 2D 商业游戏 UI element，表现“Bug / 用例 / Diff”主题，像 QA 面板、警告框、勾选框和异常日志的视觉化资源条，高对比红黄绿与灰白配色，整洁、可读、战斗 UI 友好，不要文字
```

- Negative Prompt / 避免项：

```text
avoid too many tiny icons, avoid unreadable chart wall
```

- 输出要求：
  - 资源层级清楚

### 8.7 `ui_resource_panel_algorithm`
- 优先级：`P0`
- 资源名称：算法资源面板装饰
- 用途：战斗职业资源区
- 推荐工具：通用图像模型
- 输出类型：UI element concept
- 推荐尺寸：`1024x1024`
- Prompt：

```text
算法职业资源面板装饰设计，清晰 2D 商业游戏 UI element，表现“算力 / 复杂度”主题，像运算核心、矩阵层和复杂度刻度的可视化战斗资源面板，冷蓝、深灰、少量荧光紫蓝，简洁、理性、高可读，不要文字，不要角色
```

- Negative Prompt / 避免项：

```text
avoid sci-fi spaceship HUD, avoid tiny formulas everywhere
```

- 输出要求：
  - 理性高智感

### 8.8 `ui_resource_panel_product_manager`
- 优先级：`P0`
- 资源名称：产品经理资源面板装饰
- 用途：战斗职业资源区
- 推荐工具：通用图像模型
- 输出类型：UI element concept
- 推荐尺寸：`1024x1024`
- Prompt：

```text
产品经理职业资源面板装饰设计，清晰 2D 商业游戏 UI element，表现“需求变更 / 优先级”主题，像路线图、优先级标签、重排箭头与会议纪要框体组成的战斗资源面板，商务蓝、灰白、警示橙、少量红色修订标记，简洁可读，不要文字
```

- Negative Prompt / 避免项：

```text
avoid text-heavy whiteboard, avoid cluttered sticky notes
```

- 输出要求：
  - 重排感清晰

### 8.9 `ui_run_result_bg`
- 优先级：`P1`
- 资源名称：结算页背景
- 用途：RunResultScene
- 推荐工具：通用图像模型
- 输出类型：UI background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
写字楼肉鸽卡牌游戏结算页背景，清晰 2D 商业游戏 UI 背景，像一份巨大的企业周报/季度总结被转化成战斗结算画面，办公楼高层视野、数据面板感、疲惫但有成就的氛围，留出中央结果面板空间，不要文字
```

- Negative Prompt / 避免项：

```text
avoid too much chart detail, avoid depressing realism, avoid text
```

- 输出要求：
  - 中央留白

### 8.10 `ui_meta_progression_bg`
- 优先级：`P1`
- 资源名称：成长页背景
- 用途：MetaProgressionScene
- 推荐工具：通用图像模型
- 输出类型：UI background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
写字楼肉鸽卡牌游戏局外成长页背景，清晰 2D 商业游戏 UI 背景，像一个被可视化的工位升级室和职业晋升树大厅，办公室升级道具、人体工学椅、咖啡豆、显示器、职业徽记以高级展示方式排列，现代办公楼科技感，留出左右树状 UI 区域，不要文字
```

- Negative Prompt / 避免项：

```text
avoid fantasy altar, avoid cluttered storage room, avoid text
```

- 输出要求：
  - 两侧和中央有 UI 留白

### 8.11 `ui_reward_bg`
- 优先级：`P0`
- 资源名称：奖励页背景
- 用途：RewardScene
- 推荐工具：通用图像模型
- 输出类型：UI background
- 推荐尺寸：`1920x1080`
- Prompt：

```text
写字楼肉鸽卡牌游戏奖励页背景，清晰 2D 商业游戏 UI 背景，像一次项目阶段性结算台面，桌面上整齐摆放卡牌候选、遗物陈列托盘、绩效点光片和办公楼冷白环境反光，整体氛围是“打完一场仗后的理性奖励选择”，中央留出三选一卡和奖励面板空间，不要文字，不要角色，modern office card roguelike reward screen background
```

- Negative Prompt / 避免项：

```text
avoid treasure chest fantasy room, avoid casino reward vibe, avoid cluttered desktop mess, avoid text
```

- 输出要求：
  - 中央与下半区留奖励卡位
  - 背景不能抢奖励 UI 主体

## 9. 节点图标、状态图标与边框 Prompt

### 9.1 `node_icon_combat_set`
- 优先级：`P0`
- 资源名称：节点图标系列
- 用途：MapScene 节点
- 推荐工具：`$generate2dsprite`
- 输出类型：prop pack / icon pack
- 推荐尺寸：`3x3` 或逐个 `1024x1024`
- Prompt：

```text
Use $generate2dsprite to create a clean_hd 3x3 icon-style prop sheet for a workplace roguelike card game node icon set. Include compact symbolic icons for normal battle, elite battle, shop vending machine, rest break room, random event envelope, boss office seal, reward card, and locked path marker, plus one empty magenta cell. Keep every icon centered, single-object silhouette, high contrast, no text, no labels, exact 3x3 grid, solid #FF00FF background, clean commercial 2D game UI icon style.
```

- Negative Prompt / 避免项：

```text
avoid characters, avoid tiny text, avoid busy scenes, avoid realistic backgrounds
```

- 输出要求：
  - 图标单体
  - 高对比

### 9.2 `status_icon_style_sheet`
- 优先级：`P1`
- 资源名称：状态图标风格模板
- 用途：状态系统图标风格统一
- 推荐工具：`$generate2dsprite`
- 输出类型：icon pack
- 推荐尺寸：`3x3`
- Prompt：

```text
Use $generate2dsprite to create a clean_hd 3x3 icon-style sheet for workplace roguelike status effects. Include compact symbolic icons for anxiety, overtime, vulnerable, weak, bug, case, diff, compute, and requirement-change. Solid #FF00FF background, exact 3x3 grid, single centered icon per cell, high readability, strong silhouette, no text, no borders, modern corporate-fantasy card game icon style.
```

- Negative Prompt / 避免项：

```text
avoid crowded composition, avoid tiny text, avoid realistic scene fragments
```

- 输出要求：
  - 可作图标风格基准

### 9.3 `ui_card_rarity_frame_style`
- 优先级：`P1`
- 资源名称：卡牌稀有度边框风格
- 用途：卡牌框体视觉
- 推荐工具：通用图像模型
- 输出类型：UI frame concept
- 推荐尺寸：`1024x1536`
- Prompt：

```text
写字楼主题 roguelike 卡牌稀有度边框设计图，清晰 2D 商业游戏 UI concept，展示普通、罕见、稀有三种卡牌边框装饰风格，灵感来自企业系统面板、办公卡套、数据框与警示标签，不要完整卡牌插画，不要文字，强调可读性、层级差异和商业卡牌 UI 质感。
```

- Negative Prompt / 避免项：

```text
avoid fantasy gold filigree overload, avoid parchment, avoid text labels
```

- 输出要求：
  - 用于后续框体拆分

### 9.4 `enemy_portrait_icon_set`
- 优先级：`P0`
- 资源名称：敌人头像风格包
- 用途：战斗头像、意图条、图鉴小头像
- 推荐工具：`$generate2dsprite`
- 输出类型：icon pack
- 推荐尺寸：`4x4`
- Prompt：

```text
Use $generate2dsprite to create a clean_hd 4x4 portrait-icon pack for a workplace roguelike card game enemy roster. Include centered head-and-shoulder portraits for slacker coworker, workaholic coworker, angry cleaner, salesman, process specialist, performance inspector, meeting maniac, airdrop director, compliance judge, airdrop project lead, outsource manager, budget gatekeeper, approval eye, pitch supervisor, mutant HR, and mutant CEO. Solid #FF00FF background, exact 4x4 grid, one portrait per cell, high contrast, readable at small size, absurd office satire style, no text, no labels.
```

- Negative Prompt / 避免项：

```text
avoid full-body figures, avoid busy backgrounds, avoid tiny props covering faces, avoid horror gore
```

- 输出要求：
  - 每格仅头像或胸像
  - 便于裁切为战斗小头像

### 9.5 `ui_status_badge_variants`
- 优先级：`P1`
- 资源名称：状态徽记系列
- 用途：状态层数底徽、buff/debuff 背板、职业资源小章
- 推荐工具：通用图像模型
- 输出类型：UI icon concept
- 推荐尺寸：`1024x1024`
- Prompt：

```text
写字楼主题 roguelike 状态徽记系列设计图，清晰 2D 商业游戏 UI concept，展示一组可拆分的小型状态底徽、数字承载徽章、buff 与 debuff 背板、职业资源小章。风格基于企业系统标签、审批章、警示框、冷白玻璃片与彩色状态条，要求高对比、边界干净、不含文字、适合缩小显示。
```

- Negative Prompt / 避免项：

```text
avoid fantasy crest overload, avoid medieval emblem, avoid unreadable tiny details, avoid text
```

- 输出要求：
  - 作为状态 UI 二次拆件参考

## 10. 卡牌插画 Prompt

说明：
- First Playable 五职业每个至少列 `10` 张代表卡
- 程序员系共享卡列 `12` 张
- HR 作为扩展职业列 `10` 张代表卡
- 其余未列卡牌可按系列模板继续扩写

### 10.1 后端代表卡

#### `card_illust_backend_publish_script`
- 优先级：`P0`
- 资源名称：发布脚本
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《发布脚本》，后端职业卡牌插画，半写实商业 2D 卡牌游戏风格，后端工程师正在执行部署脚本，身前展开服务节点和自动化发布窗口，按钮被按下的一刻数据流开始稳定扩散，动作清晰，单主体，背景简化为办公技术空间，适合竖版卡牌裁切
```

- Negative Prompt / 避免项：

```text
avoid text-heavy terminal screen, avoid crowded server room, avoid photorealism
```

- 输出要求：
  - 单动作明确

#### `card_illust_backend_api_gateway`
- 优先级：`P0`
- 资源名称：API网关
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《API网关》，后端职业卡牌插画，半写实商业 2D 卡牌游戏风格，一个巨大而稳定的接口网关像护盾和门一样立在角色前方，数据流被有序筛过，视觉上体现防守与流量管理，简洁背景，强主体
```

- Negative Prompt / 避免项：

```text
avoid sci-fi portal overload, avoid unreadable tiny code
```

- 输出要求：
  - 体现护盾与入口感

#### `card_illust_backend_redis_warmup`
- 优先级：`P0`
- 资源名称：Redis预热
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《Redis预热》，后端职业卡牌插画，半写实商业 2D 游戏风格，角色正在激活一组缓存核心，多个红橙色缓存模块点亮并准备爆发后续资源，动作凝聚、背景简洁、强调资源蓄积
```

- Negative Prompt / 避免项：

```text
avoid fantasy crystal cave, avoid fire mage look
```

- 输出要求：
  - 强调缓存点亮

#### `card_illust_backend_message_queue`
- 优先级：`P0`
- 资源名称：消息队列堆积
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《消息队列堆积》，后端职业卡牌插画，半写实商业 2D 游戏风格，大量请求消息在角色控制下有序堆积成一条发光的队列洪流，视觉上既有压力也有可控秩序，简洁背景，单主体明确
```

- Negative Prompt / 避免项：

```text
avoid chaotic random particles, avoid sci-fi laser cannon
```

- 输出要求：
  - 表达“堆积待爆发”

#### `card_illust_backend_circuit_breaker`
- 优先级：`P0`
- 资源名称：熔断保护
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《熔断保护》，后端职业卡牌插画，角色启动一层冷白与冷绿组成的技术护盾，错误请求被挡在外面，构图简洁，明确体现防守和风险隔离
```

- Negative Prompt / 避免项：

```text
avoid fantasy holy shield, avoid giant sci-fi armor
```

- 输出要求：
  - 护盾清晰

#### `card_illust_backend_service_degrade`
- 优先级：`P0`
- 资源名称：服务降级
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《服务降级》，后端职业卡牌插画，角色主动关闭部分非关键模块来保住核心系统，视觉上体现从复杂流量中抽离出一条稳定主线，简洁背景，强控制感
```

- Negative Prompt / 避免项：

```text
avoid too many screens, avoid cluttered collapse scene
```

- 输出要求：
  - “牺牲部分保住整体”可读

#### `card_illust_backend_sharding`
- 优先级：`P0`
- 资源名称：分库分表
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《分库分表》，后端职业卡牌插画，数据洪流在角色手势下被拆分成多个整齐稳定的模块单元，视觉上体现扩展与资源增长，简洁办公技术背景
```

- Negative Prompt / 避免项：

```text
avoid abstract incomprehensible cubes, avoid sci-fi spaceship server core
```

- 输出要求：
  - 数据拆分感强

#### `card_illust_backend_traffic_shaping`
- 优先级：`P0`
- 资源名称：流量削峰
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《流量削峰》，后端职业卡牌插画，角色正把一股危险的请求洪峰压低并整形成平稳流线，画面带明显对比：高压浪潮被稳稳抚平，适合竖版卡牌
```

- Negative Prompt / 避免项：

```text
avoid ocean literal wave fantasy, avoid environmental disaster feel
```

- 输出要求：
  - 压低峰值动作要明确

#### `card_illust_backend_flush_all`
- 优先级：`P0`
- 资源名称：全量回写
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《全量回写》，后端职业卡牌插画，之前积累的缓存与服务资源在一瞬间被回写为强烈冲击，角色处于稳定但强势的终结姿态，数据流形成整齐而压倒性的前冲视觉
```

- Negative Prompt / 避免项：

```text
avoid explosion chaos, avoid beam cannon sci-fi
```

- 输出要求：
  - 强终结感

#### `card_illust_backend_prod_inspection`
- 优先级：`P0`
- 资源名称：生产环境巡检
- 用途：后端代表卡插画
- 推荐工具：通用图像模型
- 输出类型：card illustration
- 推荐尺寸：`1024x1536`
- Prompt：

```text
卡牌插画《生产环境巡检》，后端职业卡牌插画，角色站在生产系统前快速定位关键服务和异常路径，画面体现检索、抽取关键牌、排查核心节点，背景简洁，光效克制
```

- Negative Prompt / 避免项：

```text
avoid detective noir theme, avoid massive monitor clutter
```

- 输出要求：
  - 检索感

### 10.2 前端代表卡
以下条目沿用相同字段，统一省略重复说明中的固定字段，仅保留完整可复制 Prompt。

#### `card_illust_frontend_component_reuse`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《组件复用》，前端职业卡牌插画，半写实商业 2D 游戏风格，角色把已有 UI 组件一分为二重新组合，画面里模块被复制并无缝拼接，体现高效连段与复用，竖版构图，主体清晰
```

#### `card_illust_frontend_state_boost`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《状态提升》，前端职业卡牌插画，角色为界面层叠加高亮状态，按钮、卡片和组件被逐层点亮，画面有明显的节奏递进感，商业 2D 卡牌风
```

#### `card_illust_frontend_motion_overload`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《动效超载》，前端职业卡牌插画，连续动作和界面动效在角色手中爆发成高频冲击，但依然保持清晰单主体和可读轮廓
```

#### `card_illust_frontend_hotfix_style`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《热更新样式》，前端职业卡牌插画，角色正在实时改写界面样式，下一张攻击被光亮边框和样式层重构，动作干脆，竖版构图
```

#### `card_illust_frontend_pixel_alignment`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《像素级对齐》，前端职业卡牌插画，角色专注修正界面与结构误差，画面强调精修、稳定、防守与精确感
```

#### `card_illust_frontend_compat_patch`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《兼容性补丁》，前端职业卡牌插画，角色快速修补多个终端之间的显示错误，样式层保持稳定，视觉上体现补丁与保护
```

#### `card_illust_frontend_vue_suite`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《Vue三件套》，前端职业卡牌插画，多个组件自动生成并围绕角色展开，模块感和框架感强，背景简洁
```

#### `card_illust_frontend_css_override`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《CSS覆盖》，前端职业卡牌插画，角色用一条强势样式覆盖线直接重写敌方增益外观与结构，控制感强
```

#### `card_illust_frontend_first_screen_opt`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《首屏优化》，前端职业卡牌插画，角色快速压缩加载链路，让前两次动作瞬间加速，画面强调轻快与效率
```

#### `card_illust_frontend_crash_animation`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《崩溃动画》，前端职业卡牌插画，所有样式层在一瞬间被引爆成极具节奏感的视觉冲击，但仍保持单主体清晰和商业卡牌可读性
```

### 10.3 测试代表卡
#### `card_illust_tester_repro_steps`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《复现步骤》，测试职业卡牌插画，角色拿着明确的复现流程一步步锁定敌方 Bug，画面体现注入缺陷与精确定位，商业 2D 卡牌风
```

#### `card_illust_tester_auto_regression`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《自动化回归》，测试职业卡牌插画，多个自动化检查流程围绕敌人轮转并不断触发已挂 Bug，秩序感与压制感并存
```

#### `card_illust_tester_bug_upgrade`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《缺陷升级》，测试职业卡牌插画，原本轻微的异常被角色升级成致命缺陷，警告标识层层放大，画面压迫感强
```

#### `card_illust_tester_boundary_check`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《边界值校验》，测试职业卡牌插画，角色正在逼近系统边缘参数，危险阈值被精准触发，画面强调临界点
```

#### `card_illust_tester_smoke_test`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《冒烟测试》，测试职业卡牌插画，角色快速做首轮验证并观察下回合风险，轻防守感与预判感明确
```

#### `card_illust_tester_case_matrix`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《用例矩阵》，测试职业卡牌插画，多个用例格子像战斗阵列一样展开并叠加到目标身上，秩序感强
```

#### `card_illust_tester_defect_log`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《缺陷登记》，测试职业卡牌插画，角色用红色和黄色警告单快速给敌人打上缺陷记录，动作清晰
```

#### `card_illust_tester_regression_confirm`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《回归确认》，测试职业卡牌插画，角色在已有用例目标上确认回归结果并追加 Diff 标记，节奏短促明确
```

#### `card_illust_tester_92_bugs`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《提交92个致命Bug》，测试职业卡牌插画，角色一口气向敌方系统抛出大量致命缺陷，成片警告框与 Bug 标记像有秩序的洪流压向对手，商业卡牌终极技能风格
```

#### `card_illust_tester_report_lock`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《测试报告封板》，测试职业卡牌插画，角色把所有 Bug、用例和 Diff 结算为最终报告一击，像一份结案文件压垮目标
```

### 10.4 算法代表卡
#### `card_illust_algo_heuristic_search`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《启发式搜索》，算法职业卡牌插画，角色沿着多条路径快速试探并抽出最优方向，画面强调搜索与算力积累
```

#### `card_illust_algo_dynamic_programming`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《动态规划》，算法职业卡牌插画，多个阶段结果被有序缓存并重复利用，画面体现递推和高阶构筑感
```

#### `card_illust_algo_complexity_burst`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《复杂度爆炸》，算法职业卡牌插画，复杂度层级突然飙升并转化为高强伤害，画面有失控边缘但仍理性可读
```

#### `card_illust_algo_pruning`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《剪枝优化》，算法职业卡牌插画，角色迅速剪掉无效分支，让剩余路径更锐利更高效，动作利落
```

#### `card_illust_algo_local_opt`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《局部最优》，算法职业卡牌插画，角色抓住局部最优机会压缩当前回合成本，画面聚焦单点突破
```

#### `card_illust_algo_big_o_compress`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《大O压缩》，算法职业卡牌插画，庞杂复杂度被折叠压缩成更精炼的资源核心，理性视觉强
```

#### `card_illust_algo_monte_carlo`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《蒙特卡洛试投》，算法职业卡牌插画，大量随机试投结果围绕角色旋转并筛出高价值分支，动态清晰
```

#### `card_illust_algo_matrix_mul`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《矩阵乘法》，算法职业卡牌插画，多个矩阵块高速相乘后形成高强单体冲击，画面利落、几何感强
```

#### `card_illust_algo_astar`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《A星寻路》，算法职业卡牌插画，角色在复杂路径图中精准锁定最优路线，检索感与方向感明确
```

#### `card_illust_algo_global_optimum`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《全局最优解》，算法职业卡牌插画，所有算力和路径在一瞬间收束为终极求解，形成最强终结一击，商业卡牌高稀有技能风格
```

### 10.5 产品经理代表卡
#### `card_illust_pm_change_request`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《改版通知》，产品经理职业卡牌插画，角色把一张改版通知甩向敌人，敌方原定动作被强行改写，画面体现意图改变与控制
```

#### `card_illust_pm_review`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《需求评审》，产品经理职业卡牌插画，角色站在会议评审桌前重排信息流，第一次需求变更带来抽牌与防线收益
```

#### `card_illust_pm_delay_meeting`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《会议延期》，产品经理职业卡牌插画，角色挥手把敌方大招强行推迟到下一个时间块，时间调度感清晰
```

#### `card_illust_pm_priority_top`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《优先级置顶》，产品经理职业卡牌插画，一个目标被高亮置顶，后续所有资源都围绕它重排，单点控制感强
```

#### `card_illust_pm_milestone_split`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《里程碑拆分》，产品经理职业卡牌插画，敌方强动作被拆解成多个弱步骤，路线图被角色重新切段
```

#### `card_illust_pm_scope_spread`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《范围蔓延》，产品经理职业卡牌插画，一次需求变更扩散到另一个敌人，多个目标被卷入重排洪流
```

#### `card_illust_pm_message_align`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《口径统一》，产品经理职业卡牌插画，角色把混乱意见重新统一为稳定口径，清理自身负面并稳定手牌
```

#### `card_illust_pm_extra_requirement`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《临时加需求》，产品经理职业卡牌插画，角色突然向敌人追加任务，使其本回合动作降级成低收益回应
```

#### `card_illust_pm_align_all`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《全员对齐》，产品经理职业卡牌插画，角色站在会议中心重置所有敌人的行动顺序，画面有强烈全场控制感
```

#### `card_illust_pm_roadmap`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《版本路线图》，产品经理职业卡牌插画，经过多次变更的目标最终被完整路线图压垮，画面像一次战略收束与清算
```

### 10.6 程序员系共享卡 `12`
每条都按共享办公道具和通用职场动作来写。

#### `card_illust_shared_keyboard_smash`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《键盘重击》，写字楼肉鸽共享卡牌插画，办公键盘被当作近战武器砸向敌人，动作夸张但商业 2D 卡牌风清晰可读
```

#### `card_illust_shared_stapler_burst`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《订书机连射》，办公订书机像连续射击装置一样快速打出多段攻击，主体清晰，单动作明确
```

#### `card_illust_shared_noise_cancel`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《戴上降噪耳机》，角色戴上厚重降噪耳机形成临时防线，周围噪音和精神攻击被压制
```

#### `card_illust_shared_coffee_boost`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《咖啡续命》，角色猛灌一口黑咖啡，短时间恢复精力，画面有明显提神冲击感
```

#### `card_illust_shared_toilet_break`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《带薪拉屎》，角色迅速躲进办公室卫生间获得短暂安全窗口，荒诞喜剧感强但构图干净
```

#### `card_illust_shared_desk_inspection`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《工位巡检》，角色在工位前快速整理和检查资源，预示后续抽牌质量提升
```

#### `card_illust_shared_rollback`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《回滚版本》，角色一把撤回错误改动，敌我状态被短暂重置，动作明确
```

#### `card_illust_shared_standup`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《晨会同步》，一群简化的晨会状态与任务卡在角色周围同步，带来节奏加速与抽牌感
```

#### `card_illust_shared_clock_out`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《下班打卡》，角色拍下打卡机的一刻获得短暂稳定和防线，构图简洁
```

#### `card_illust_shared_hotfix_patch`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《临时补丁》，角色用一张快速补丁稳住局势，体现小修补、小防守和短资源回转
```

#### `card_illust_shared_badge_throw`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《工牌甩脸》，员工工牌像飞刃一样甩向敌人，动作短促有喜剧感
```

#### `card_illust_shared_meeting_mute`
- 优先级：`P0`
- Prompt：

```text
卡牌插画《会议静音》，角色按下静音键或合上会议麦克风，让敌方下一步动作瞬间失真
```

### 10.7 HR 扩展职业代表卡 `10`
这些为扩展资源，优先级均为 `P2`。

#### `card_illust_hr_optimization_warning`
```text
卡牌插画《优化预警》，HR 职业卡牌插画，角色把优化名单挂到低生命目标头上，收割前兆清晰
```

#### `card_illust_hr_performance_archive`
```text
卡牌插画《绩效归档》，HR 职业卡牌插画，每次获得绩效都被写入冷酷的资源档案中，伴随额外收益
```

#### `card_illust_hr_last_place_cut`
```text
卡牌插画《末位淘汰》，HR 职业卡牌插画，被挂名单的目标遭到高压裁决，斩杀感强
```

#### `card_illust_hr_compliance_review`
```text
卡牌插画《合规审查》，HR 职业卡牌插画，角色清除敌方增益并压下其收益空间
```

#### `card_illust_hr_attendance_check`
```text
卡牌插画《考勤抽查》，HR 职业卡牌插画，短动作、快节奏、获得绩效并锁定后续目标
```

#### `card_illust_hr_annual_award`
```text
卡牌插画《年度评优》，HR 职业卡牌插画，本回合击败目标后的额外奖励被华丽结算
```

#### `card_illust_hr_org_optimization`
```text
卡牌插画《组织优化》，HR 职业卡牌插画，多个低血目标被同时纳入优化名单，范围感强
```

#### `card_illust_hr_layoff_list`
```text
卡牌插画《裁员名单》，HR 职业卡牌插画，一张危险的名单压低敌方防线并强化下一次斩杀
```

#### `card_illust_hr_headhunter_offer`
```text
卡牌插画《猎头报价》，HR 职业卡牌插画，用绩效交换额外资源与抽牌，表现资源转换
```

#### `card_illust_hr_nplusone`
```text
卡牌插画《N+1结算》，HR 职业卡牌插画，所有优化名单目标被统一收割，终结气质明确
```

### 10.8 非代表卡系列扩展模板
以下模板用于把未逐条展开的剩余职业牌继续批量补齐，保持与本手册同一项目风格。

#### `card_template_backend`
```text
为“后端”职业生成一张新的卡牌插画，清晰 2D 商业卡牌游戏插画风，现代办公室技术语境，主题围绕服务部署、缓存累积、流量治理、系统稳态、防守反制或队列爆发。单主体清晰，动作明确，适合竖版卡牌裁切，办公室技术背景简化，不要文字，不要复杂代码墙。
```

#### `card_template_frontend`
```text
为“前端”职业生成一张新的卡牌插画，清晰 2D 商业卡牌游戏插画风，主题围绕组件复制、样式叠层、前端连击、动效爆发、兼容性修补。保持界面感但不要真的画成完整屏幕截图，主体明确，动作轻快，适合竖版卡牌裁切。
```

#### `card_template_tester`
```text
为“测试”职业生成一张新的卡牌插画，清晰 2D 商业卡牌游戏插画风，主题围绕 Bug 注入、用例铺设、回归锁定、Diff 标记、校验清算。警告色可以更强，但不做恐怖 glitch 风，单主体清晰，适合竖版卡牌裁切。
```

#### `card_template_algorithm`
```text
为“算法”职业生成一张新的卡牌插画，清晰 2D 商业卡牌游戏插画风，主题围绕算力蓄能、复杂度管理、路径求解、矩阵运算、终局爆发。保持理性几何感与现代办公室身份，不要法师化，不要纯科幻实验室。
```

#### `card_template_product_manager`
```text
为“产品经理”职业生成一张新的卡牌插画，清晰 2D 商业卡牌游戏插画风，主题围绕需求变更、优先级重排、会议控制、路线图收束、借敌人行动取胜。保留会议、文档、标签、箭头等职场道具，但不出现可读文字。
```

#### `card_template_hr`
```text
为“HR”职业生成一张新的卡牌插画，清晰 2D 商业卡牌游戏插画风，主题围绕绩效压制、优化名单、合规审查、斩杀收割、资源滚雪球。保持冷静制度感和组织控制感，不做恐怖怪物插画。
```

## 11. 遗物图标 Prompt

说明：所有遗物图标统一要求透明背景、单体居中、高对比、适合小尺寸。

### 11.1 程序员系共享遗物 `6`

#### `relic_icon_blue_light_glasses`
- 优先级：`P0`
- Prompt：

```text
一个“蓝光眼镜”遗物图标，清晰 2D 商业游戏 icon，现代办公防蓝光眼镜，透明背景，单体居中，灰蓝镜框，冷白反光，高对比，小尺寸可读
```

#### `relic_icon_cold_brew_bucket`
- 优先级：`P0`
- Prompt：

```text
一个“冷萃咖啡桶”遗物图标，商业 2D 游戏 icon，透明背景，单体居中，深色咖啡桶与冷凝质感，办公咖啡系统感，高对比
```

#### `relic_icon_hair_shampoo`
- 优先级：`P0`
- Prompt：

```text
一个“防脱洗发水”遗物图标，商业 2D 游戏 icon，透明背景，单体居中，现代洗发水瓶，办公社畜黑色幽默感，高对比
```

#### `relic_icon_lumbar_cushion`
- 优先级：`P0`
- Prompt：

```text
一个“护腰靠垫”遗物图标，商业 2D 游戏 icon，透明背景，单体居中，人体工学靠垫，柔和灰蓝配色，可读性高
```

#### `relic_icon_standing_desk`
- 优先级：`P0`
- Prompt：

```text
一个“升降桌”遗物图标，商业 2D 游戏 icon，透明背景，单体居中，简化的现代办公升降桌，高对比，线条清晰
```

#### `relic_icon_parking_pass`
- 优先级：`P0`
- Prompt：

```text
一个“园区停车月卡”遗物图标，商业 2D 游戏 icon，透明背景，单体居中，带办公园区感的停车卡，高可读
```

### 11.2 通用与职业倾向遗物池 `18`

说明：
- 本节对应 `01_GAME_DESIGN_BRIEF.md` 中“偏通用遗物 `6` + 职业倾向遗物 `12`”。
- 若某个偏通用遗物与程序员系共享遗物同名，可以复用同一张图标，但资源条目仍建议按不同 `id` 输出。

#### 偏通用遗物 `6`

#### `relic_icon_generic_blue_light_glasses`
```text
一个“蓝光眼镜”通用遗物图标，清晰 2D 商业游戏 icon，透明背景，单体居中，现代办公防蓝光眼镜，镜片有冷白反光，高对比，小尺寸可读
```

#### `relic_icon_generic_cold_brew_bucket`
```text
一个“冷萃咖啡桶”通用遗物图标，清晰 2D 商业游戏 icon，透明背景，单体居中，深色冷萃桶与冷凝质感明显，办公咖啡系统风格
```

#### `relic_icon_generic_hair_shampoo`
```text
一个“防脱洗发水”通用遗物图标，清晰 2D 商业游戏 icon，透明背景，单体居中，现代瓶身设计，黑色幽默但仍商业可读
```

#### `relic_icon_generic_lumbar_cushion`
```text
一个“护腰靠垫”通用遗物图标，清晰 2D 商业游戏 icon，透明背景，单体居中，人体工学靠垫造型明确，灰蓝配色，高可读
```

#### `relic_icon_employee_discount_coupon`
```text
一个“员工内购券”通用遗物图标，清晰 2D 商业游戏 icon，透明背景，单体居中，带企业内购印章和折扣券轮廓的办公福利卡，小尺寸可读
```

#### `relic_icon_generic_parking_pass`
```text
一个“园区停车月卡”通用遗物图标，清晰 2D 商业游戏 icon，透明背景，单体居中，带公司园区感的停车通行证，高对比，适合小尺寸显示
```

#### `relic_icon_unit_test_template`
```text
一个“单元测试模板”遗物图标，透明背景，单体居中，测试模板文档与勾选标记结合，商业 2D 游戏 icon
```

#### `relic_icon_error_log_repo`
```text
一个“报错日志仓库”遗物图标，透明背景，单体居中，日志文件夹与红色错误标记结合，商业 2D 游戏 icon
```

#### `relic_icon_figma_library`
```text
一个“Figma组件库”遗物图标，透明背景，单体居中，组件格与设计模块结合，商业 2D 游戏 icon
```

#### `relic_icon_design_review`
```text
一个“设计走查清单”遗物图标，透明背景，单体居中，清单板夹与高亮标记结合，商业 2D 游戏 icon
```

#### `relic_icon_traffic_valve`
```text
一个“灰度流量阀门”遗物图标，透明背景，单体居中，工业阀门与数据流结合，商业 2D 游戏 icon
```

#### `relic_icon_read_replica`
```text
一个“只读从库快照”遗物图标，透明背景，单体居中，小型数据库快照模块，商业 2D 游戏 icon
```

#### `relic_icon_gantt_roadmap`
```text
一个“路线图甘特图”遗物图标，透明背景，单体居中，简化项目甘特图板，商业 2D 游戏 icon
```

#### `relic_icon_meeting_room_claim`
```text
一个“会议室占用权”遗物图标，透明背景，单体居中，会议室门牌与优先标签结合，商业 2D 游戏 icon
```

#### `relic_icon_candidate_blacklist`
```text
一个“候选人黑名单”遗物图标，透明背景，单体居中，档案卡和黑名单印章结合，商业 2D 游戏 icon
```

#### `relic_icon_performance_table`
```text
一个“绩效校准表”遗物图标，透明背景，单体居中，绩效表格与审查印章结合，商业 2D 游戏 icon
```

#### `relic_icon_gpu_card`
```text
一个“GPU训练卡”遗物图标，透明背景，单体居中，高性能计算卡，带冷蓝算力光效，商业 2D 游戏 icon
```

#### `relic_icon_paper_citation`
```text
一个“论文引用榜”遗物图标，透明背景，单体居中，论文页与引用上升箭头结合，商业 2D 游戏 icon
```

## 12. 事件插图 Prompt

### 12.1 `event_illust_boss_office_unlocked`
- 优先级：`P1`
- Prompt：

```text
事件插图《老板办公室门没锁》，清晰 2D 商业游戏事件插图，现代高层办公室门半掩着，里面可见现金抽屉、待签文件、老板桌与危险诱惑感，画面无角色正脸，留出文本 UI 空间，荒诞职场感强
```

### 12.2 `event_illust_email_cc`
- 优先级：`P1`
- Prompt：

```text
事件插图《内网邮件误抄送》，办公桌上亮着一封敏感邮件链，抄送名单失控扩散，屏幕光照和办公室紧张感明确，留出文本 UI 空间
```

### 12.3 `event_illust_breakroom_gossip`
- 优先级：`P1`
- Prompt：

```text
事件插图《茶水间八卦》，茶水间里同事身影模糊地围在一起，黑料和小道消息的气氛弥漫，咖啡机和零食区明确，留出文本 UI 空间
```

### 12.4 `event_illust_vending_machine_bug`
- 优先级：`P1`
- Prompt：

```text
事件插图《深夜自动贩卖机故障》，办公楼深夜走廊里的自动贩卖机疯狂吐出饮料和零食，诡异但好笑，留出文本 UI 空间
```

### 12.5 `event_illust_take_blame`
- 优先级：`P1`
- Prompt：

```text
事件插图《帮实习生背锅》，一份明显要出事的文件和紧张的工位氛围，实习生影子在一旁，主角面临抉择，留出文本 UI 空间
```

### 12.6 `event_illust_annual_lottery`
- 优先级：`P1`
- Prompt：

```text
事件插图《年会抽奖预演》，公司年会奖箱、抽奖券和夸张奖品在会议厅或活动区里陈列，喜剧与风险并存，留出文本 UI 空间
```

### 12.7 `event_illust_private_talk`
- 优先级：`P1`
- Prompt：

```text
事件插图《领导单独谈话》，玻璃会议室内昏亮的单独谈话场景，一把椅子、一份文件、一种令人紧张的安静，留出文本 UI 空间
```

### 12.8 `event_illust_layoff_rumor`
- 优先级：`P1`
- Prompt：

```text
事件插图《裁员传闻》，整层办公区里人心惶惶，工位之间充满低声讨论和不安，空调冷光与紧张感明显，留出文本 UI 空间
```

## 13. 使用建议

### 13.1 推荐生成顺序
1. `P0` 角色主立绘与头像
2. `P0` 第一章到第三章战斗背景
3. `P0` 普通敌人与第一章 Boss
4. `P0` 节点图标与职业资源面板装饰
5. `P0` First Playable 代表卡插画
6. `P0` 程序员系共享遗物与核心职业倾向遗物
7. `P1` 事件插图、UI 背景、精英敌人与中后期 Boss
8. `P2` HR 扩展资源

### 13.2 批量生成建议
- 角色主立绘和 Boss 建议逐条生成、人工筛选
- 节点图标、状态图标、遗物图标可按 pack 生成
- 卡牌插画建议先做代表卡，再做批量扩展
- 地图与场景背景建议统一章节风格后再补事件图

### 13.3 质量控制建议
- 同职业的主立绘、半身像、头像尽量同批次生成
- 敌人和 Boss 先锁色彩层级，再扩到精英和普通敌人
- UI 背景必须留足文本和按钮空间
- 图标必须以小尺寸清晰可读为第一优先

## 14. 自检标准
- 读者只看本文件，就能列出当前所有需要 AI 生成的主要美术资源
- 每个 First Playable 职业都有主立绘、半身像、头像和 sprite 建议
- 所有普通敌人、精英敌人和 Boss 都有单独 Prompt
- 关键战斗背景、主菜单、职业选择、Map、战斗 UI、结算和成长页都有对应 Prompt
- First Playable 代表卡、程序员系共享卡、核心遗物与 8 个事件插图都已覆盖
- 产品经理资源已作为 `P0` 处理，HR 资源已作为 `P2` 处理
