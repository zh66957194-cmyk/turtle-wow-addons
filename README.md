# 乌龟服插件（Turtle WoW 1.12 插件合集）

一批为 **Turtle WoW 1.17.x / 原版 1.12.1（Interface 11200）** 编写或汉化的插件。
全部在本地单机私服（MaNGOS）实测可用。

## 目录

```
AddOns/                 可直接放进 Interface\AddOns\ 使用
├─ TipPrice             物品提示显示单价 / 一组价 / 当前数量价
├─ EquipCompare         装备对比（背包/商人/回购/任务/制造/训练师）
├─ UnitEnhance          头像增强（血量法力数值、经验条可选）
├─ ToTPlus              目标链显示（目标的目标 / 再一级，可点击）
├─ MinimapBag           小地图按钮收纳
└─ CDTimers             超出射程的技能图标变红

Localization/           第三方插件的汉化补丁（覆盖对应文件）
├─ TurtleTweaks-zhCN
├─ MoveAnything-zhCN
└─ pfQuest-zhCN         （仅补丁片段，需追加到 locales.lua）
```

## 安装

1. 把 `AddOns\` 下需要的插件文件夹整个复制到
   `World of Warcraft\Interface\AddOns\`
2. **完整重启客户端**（新增插件目录后 `/reload` 不会加载）
3. 进游戏后输入 `/reload` 或直接使用

## 各插件说明

### TipPrice
- 悬停物品时在提示框追加三行
- `单价： 2铜`、`一组(20)： 40铜`、`当前(16)： 32铜`（黄色）
- 价格数据来自 `TipPrice_Data.lua`（由服务器 `item_template.sell_price` 导出，15,579 条）
- 提示框跟随鼠标，靠边自动翻转

### EquipCompare
- 悬停装备时，右侧弹出「当前装备」对比框（红色标题条 + 售价）
- 支持：背包、商人、回购、任务奖励、任务日志、制造、训练师
- 部位识别基于提示框文本关键字（单手/双手/主手/副手/盾牌/远程/弩/枪械/弓/圣物/圣契/图腾/神像…）
- 同款装备也会对比（附魔/耐久差异需要）

### UnitEnhance
- 玩家 / 目标血量法力条右侧显示 `当前/上限`
- 经验条默认关闭（`/ue` 面板可开关）
- `/ue` 打开设置

### ToTPlus
- 目标框下方两行：目标的目标、目标的目标的目标
- 显示名字 + 当前血量，点击可切换目标
- `/tot` 在聊天栏打印当前目标链

### MinimapBag
- 小地图周围插件按钮收进下方袋子，左下角包袱按钮开合
- 任务标记（pfQuest 的 ?/!）不会被误收
- `/mmb open|close|rescan|restore`

### CDTimers
- 超出射程的动作条技能图标变红
- `/rc on|off`

## 已知限制（1.12 客户端）

| 项 | 说明 |
|---|---|
| 自动拾取 | 引擎层校验，纯 Lua 无法实现 |
| 单位提示框淡入淡出 | 客户端 C 层控制，Lua 只能压制物品提示框 |
| 物品提示框专业图标 | 尝试 5 种方案失败，已放弃 |

## 汉化补丁用法

- **TurtleTweaks-zhCN**：把文件夹内文件覆盖到 `Interface\AddOns\TurtleTweaks\` 同名文件
- **MoveAnything-zhCN**：覆盖 `MoveAnything.lua` 与 `MoveAnything.xml`
- **pfQuest-zhCN**：把 `pfQuest-zhCN.lua` 的内容追加到 `pfQuest\locales.lua` 末尾

## 许可

自写插件（TipPrice / EquipCompare / UnitEnhance / ToTPlus / MinimapBag / CDTimers）可自由使用、修改、分发。
`Localization/` 内是基于他人插件的汉化补丁，遵循原插件各自的许可。