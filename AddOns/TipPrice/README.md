# TipPrice — 鼠标提示增强（1.12 原生）

## 为什么不是移植现成的

- **335 客户端里只有 TinyTip**（能跟随鼠标，但没有价格功能），而且它是 3.3.5 代码
  （Ace3 + `hooksecurefunc` + 大量后续 API），移植到 1.12 等于重写。
- GitHub 上 1.12 的提示增强（TipBuddy / TinyTip 1.12 分支）同样要处理 Lua 5.0 与
  Ace2 依赖，改造成本高于直接写一个只做两件事的插件。

所以这里是一个 **150 行左右的原生实现**，只做你要求的两点。

## 功能

| 功能 | 实现 |
|---|---|
| 提示框跟随鼠标 | 替换 `GameTooltip_SetDefaultAnchor`，锚点改为 `ANCHOR_CURSOR` |
| 显示单价 | 取 `GetItemInfo(link)` 的 `sellPrice`（商人收购单价） |
| 显示整组价 | 单价 × `maxStack`（该物品的堆叠上限） |

显示效果（示例）：

```
石头
...
单价：1铜
一组(16)：16铜
```

## 覆盖范围

轮询 `GameTooltip:GetItem()`（0.1 秒）补行，所以下列来源都会带价格：

- 背包 / 银行格位
- 商人购买界面
- 聊天里的物品链接
- 拾取框、拍卖行、邮件附件

## 命令

```
/tipprice on     开启跟随鼠标（默认开）
/tipprice off    恢复默认位置（屏幕右下角）
/tipprice        查看帮助
/tp              同上（简写）
```

## 技术要点（1.12 / Lua 5.0）

- 没有 `HookScript`，靠 `OnUpdate` 轮询 + 记录 `lastLink` 防重复追加
- `OnUpdate` 签名是 `function(self, delta)`，**不能用全局 `arg1`**
  （1.12 的 `arg1` 只对事件回调有效，这是本次踩到的坑）
- 金额格式化优先用 `GetCoinTextureString`，缺失时退回“金/银/铜”手写
- 单价为 0（任务物品、无售价物品）不追加任何行

## 已做的验证

- 插件文件与 ToC 结构已按 1.12 要求（LF 行尾、纯 ASCII 头、`Interface: 11200`）
- 客户端可正常启动，无 Lua 报错弹窗
- 登录时会在聊天框打印一次自检：`TipPrice 已加载` 以及背包第一格的单价/整组价

> 说明：本次用脚本驱动客户端时，聊天与悬停的截图窗口区域不稳定，**价格行是否显示
> 需要你在游戏里悬停一件物品确认一次**。如果没出现，用 `/tipprice` 看命令是否注册，
> 并把现象告诉我，我按具体情况调整。

## 安装位置

```
Interface\AddOns\TipPrice\
    TipPrice.toc
    TipPrice.lua
```

备份：`deploy\TipPrice插件\`

## 卸载

删除 `Interface\AddOns\TipPrice` 文件夹即可。

---

## 2026-10-23 深入排查结论（重要）

在客户端里逐项验证后，发现三个硬约束：

| 发现 | 说明 |
|---|---|
| `GameTooltip:GetItem()` 不存在 | 本客户端返回 nil，不能从提示框反查物品链接 |
| `GetItemInfo` 只有 9 个字段 | 返回 name/link/品质/等级/类型/堆叠/图标…，**没有售价** |
| 提示框不是 `GameTooltip` | 在物品上悬停时 `GameTooltip:IsShown()` 为真，但画面上的提示框是另一个框架；对它 AddLine / SetPoint 都不生效 |

### 已解决

**售价数据**：改为从本地服务器数据库导出，生成
`Interface\AddOns\Cleanup\TipPrice_Data.lua`（15,579 条）：

```lua
TIP_ITEMS = { [2835] = {2, 20}, ... }   -- [物品ID] = {售价, 堆叠上限}
```

物品 ID 从提示框第一行的物品名反查背包/银行/商人链接得到。

### 最终方案（已生效）

提示框增强不该自己 Hook 方法，而应该用现成的库：**LibItemTooltip-1.0**
（`MasterTradeSkills`、`ItemTooltipIcons`、`MissingCrafts` 都自带这个库）。

它的机制：

1. 包装 `GameTooltip:SetBagItem / SetMerchantItem / SetHyperlink / SetInventoryItem …`
   记录当前物品链接
2. 在 `GameTooltip` 上挂一个子框架，靠它的 `OnShow` 触发回调
3. 回调参数直接给出 `(tooltip, item_link, item_id)`

所以 TipPrice 只做两件事：

```lua
LibStub("LibItemTooltip-1.0"):RegisterEvent("OnShow", function(tooltip, link, id)
    -- 查 TIP_ITEMS[id]，tooltip:AddLine("单价：…") / AddLine("一组(n)：…")
end)
```

多个插件各自注册自己的回调，行按注册顺序追加，**互不覆盖**，这正是兼容的做法。

实测结果（劣质的石头）：

```
单价： 2铜
一组(20)： 40铜
```

与 MasterTradeSkills 的“配方/训练师/商人”内容同时显示，无冲突。

## 价格行（最终形态）

物品提示框末尾追加三行：

```
单价： 2铜              ← 数字白色，单位铜色
一组(20)： 40铜          ← 堆叠上限 × 单价
当前(16)： 32铜          ← 当前格子里的实际数量 × 单价，整行黄色
```

- 第三行的数量取自 `GetContainerItemInfo(bag, slot)`，即鼠标悬停那一格的实际堆叠数
- 聊天链接、商人等处拿不到数量时按 1 处理
- 黄色用 `AddLine(..., 1, 0.82, 0)`，单位字仍保留金/银/铜各自的颜色
