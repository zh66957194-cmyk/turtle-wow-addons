# MinimapBag 插件说明

小地图按钮收纳：把小地图周围的插件按钮收进小地图下方的一个袋子里。

## 为什么自己写

先试了 GitHub 上的 [ImmersiveButtonTray](https://github.com/max-bruhn/ImmersiveButtonTray)，
采集逻辑生效了（实测 `IBTButton_XXX shown=nil`，按钮确实被隐藏），
但它的托盘框架在 1.12 上没能正常显示，结果是**按钮消失且找不到入口**。
所以改成自己实现，显示层完全可控。

## 实现

| 环节 | 做法 |
|---|---|
| 采集 | 遍历 `EnumerateFrames()`，挑出 `GetPoint()` 的父框架是 `Minimap` 的 Button |
| 排除 | 缩放 +/-、追踪、日历、邮件、战场等原生按钮 |
| 收纳 | 记录原父框架与锚点后 `SetParent` 到袋子，按 4 列网格排列 |
| 入口 | 小地图左下角常驻一个包袱按钮，点击开合 |
| 还原 | `/mmb restore` 把按钮放回原位 |

## 命令

```
/mmb open      打开袋子
/mmb close     收起
/mmb rescan    重新扫描（新装插件后按钮没被收进来时用）
/mmb restore   还原所有按钮到小地图周围
```

## 实测

重启客户端后自动采集，小地图周围干净，袋子在小地图下方显示为 4 列网格
（截图见 `预览.png`），左下角有包袱按钮作为开合入口。

## 已知限制

- 只采集「锚点父框架是 Minimap」的按钮；有些插件把按钮锚在 `MinimapCluster` 或自建框架上，就收不进来
- 遇到这种按钮，告诉我是哪个插件，我把父框架判断放宽，或加名字白名单

## 还原

复制回 `client\twmoa_1171_cn\Interface\AddOns\MinimapBag\`，然后完整重启客户端。
## 修复记录：任务标记被误收

**现象**：点收纳后，pfQuest 在小地图上的任务标记（?/! 图标）一起消失。

**原因**：pfQuest 的任务标记也是「锚定在 Minimap 上的 Button」，
被收集逻辑当成插件按钮收进袋子了。

**修复**：加名称排除表，含以下片段的框架不采集：

```lua
local EXCLUDE = { "pfquest", "pfmap", "node", "marker", "pin", "note", "questicon" }
```

修复后小地图上的任务标记正常显示，袋子里只保留真正的插件按钮。
## 补充修复：pfQuest 启动按钮收纳

第一次修复把 `pfquest` 整个词加进了排除表，结果 pfQuest 的**启动按钮**（`pfQuestIcon`）也被排除，只能留在小地图外。

改为只排除「标记类」名称：

```lua
-- 只排除任务标记/地图节点这一类；pfQuest 的启动按钮（pfQuestIcon）要能被收纳
local EXCLUDE = { "node", "marker", "pin", "pfmap" }
```

现在：pfQuest 启动按钮进袋子，任务标记（`?`/`!`）仍留在小地图上。
