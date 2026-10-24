# Localization 汉化补丁

这里不是完整插件，而是**汉化补丁**：覆盖到对应插件的同名文件即可。

| 目录 | 对应插件 | 覆盖方式 |
|---|---|---|
| `TurtleTweaks-zhCN/` | Turtle Twaks | 把里面所有文件覆盖到 `Interface\AddOns\TurtleTweaks\` |
| `MoveAnything-zhCN/` | MoveAnything | 覆盖 `MoveAnything.lua` 和 `MoveAnything.xml` |
| `pfQuest-zhCN/` | pfQuest | 把 `pfQuest-zhCN.lua` 的内容**追加**到 `pfQuest\locales.lua` 末尾 |

## 说明

### TurtleTweaks-zhCN
- 汉化了设置面板的分类、按钮、28 条功能说明、菜单按钮
- 加了中文字体适配（`Fonts\FZLBJW.TTF`），否则汉字显示成方块
- 设置面板分类顺序固定为：界面 → 实用工具 → 社交与聊天 → 自动化 → 专业

### MoveAnything-zhCN
- 面板标签：框架名称 / 移动 / 隐藏 / 角色独立设置 / 关闭 / 全部重置
- 框架列表加了中文显示名映射（玩家、目标、队友 1~4、宠物…）
- 只是显示层翻译，不影响框架匹配逻辑

### pfQuest-zhCN
- 补的是数据库菜单：宝箱与宝藏 / 草药与花 / 矿脉与矿石 / 鱼群 / 稀有怪物 …
- **关键坑**：`pfQuest_Loc` 带 `__index` 元表，读任何键都返回键名本身（永远不为 nil），
  所以覆盖翻译必须用 `rawset(pfQuest_Loc, k, v)`，不能判断 `== nil`

## 注意

汉化基于对应插件的某个版本，插件更新后文件结构可能变化，届时需要重新对照。