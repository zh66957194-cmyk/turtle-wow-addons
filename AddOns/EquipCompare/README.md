# EquipCompare —— 1.12 装备自动对比

## 来源

335 客户端里的 **EquipmentCompare**（作者 stillwater，2 个文件共 2KB）。
原版实现只有十几行，核心是给 `GameTooltip` 挂 `OnTooltipSetItem` 再调
`GameTooltip_ShowCompareItem`。

## 1.12 的两个硬限制

| 原版依赖 | 1.12 情况 | 替代做法 |
|---|---|---|
| `OnTooltipSetItem` 脚本 | 不存在 | 包装 `GameTooltip:SetBagItem` / `SetInventoryItem` |
| `GameTooltip_ShowCompareItem` | 不存在 | 复用客户端的 `ShoppingTooltip1/2`（商人对比用的现成提示框） |
| `GetItemInfo` 提供部位 | **只返回 3 个字段，4~9 全是 nil** | 从提示框文本里找部位关键字（主手/胸部/手指…） |

实测证据：

```
II1 磨损之训练用剑
II2 |Hitem:...|h[磨损之训练用剑]|h|r
II3 2
II4 nil
II5 nil
II6 nil
II7 nil
II8 nil
II9 nil
```

## 实现

```lua
-- 包装取物方法
local orig = GameTooltip["SetBagItem"]
GameTooltip["SetBagItem"] = function(self, bag, slot)
    orig(self, bag, slot)
    local link = GetContainerItemLink(bag, slot)
    local slots = FindSlots(self)          -- 读提示框文本里的部位关键字
    ShowCompare(slots, GetItemID(link))    -- 用 ShoppingTooltip 显示已装备的
end
```

- 部位关键字表覆盖：头/颈/肩/衬衣/胸/腰/腿/脚/腕/手（含手套、双手）/手指/饰品/背/主手/副手/盾牌/远程/投掷/魔杖/圣物
- 手指、饰品会同时对比左右两个槽位（两个提示框）
- 对比框锚定在主提示框右侧：`SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 6, 0)`
- 主提示框隐藏时自动收起对比框

## 实测

悬停背包里的「磨损之训练用剑」：

```
┌─ 磨损之训练用剑 ─┐  ┌─ 铜质钉锤 ─┐
│ 装备后绑定       │  │ 主手        │
│ 20-30 伤害       │  │ 6-11 伤害   │
│ 速度 3.50        │  │ 速度 2.20   │
│ ...              │  │ ...         │
│ 单价/一组/当前   │  └────────────┘
└──────────────────┘
```

左边是悬停物品（带我们的价格行），右边是身上已装备的同部位物品。

## 已知限制

1. **部位靠提示框文本识别**：如果某个物品的提示框没有部位关键字（比如饰品、戒指的特殊写法），
   就不会弹出对比。要扩充关键字，改 `SLOT_KEYWORDS` 表即可。
2. 只处理背包和自身装备槽；商人/拍卖行/拾取框暂未接入（可后续加 `SetMerchantItem` 等）。
3. 与 TipPrice 共存：价格行在左提示框，对比框在右侧，互不影响。

## 文件

- 插件：`Interface\AddOns\EquipCompare\`（`EquipCompare.toc` + `EquipCompare.lua`，150 行）
- 备份：`deploy\EquipCompare插件\`

## 标题条（v2）

对比框最上方加了一条红色、字号 13 的「当前装备」标题（正文是 11 号）。
实现方式：标题是独立的小框架，带同样的提示框背景与边框，
纵向叠在 ShoppingTooltip 上方，看起来像同一个框的标题栏。

```
┌────────────────┐
│ 当前装备       │  ← 红色 13 号
├────────────────┤
│ 铜质钉锤       │
│ 主手           │
│ 6-11 伤害      │  ← 11 号，颜色沿用物品品质
└────────────────┘
```

调试命令：`/ec test` 在屏幕左上角预览对比框（不需要真的有可对比装备）。

## v3 修正（重要）

1. **「当前装备」标题条加高**：20 → 26，红字 13 号不再显局促。
2. **不再包装 `GameTooltip:SetInventoryItem`**。
   1.12 的人物装备面板（纸娃娃）走的就是这个函数，包装后会导致面板上的
   提示框异常（只剩部位名/内容错位）。装备栏本身不需要对比，所以只保留
   背包的 `SetBagItem`。
3. 对比逻辑整体套了 `pcall`，任何内部异常都不会影响原版提示框。

实测：打开角色面板悬停装备，提示框正常显示（含价格行）：

```
宽松链甲外衣
胸部
锁甲
59 / 65 耐久度
需要等级 5
单价： 58铜
当前(16)： 9银28铜
```

## v4：覆盖更多界面 + 显示售价

### 新增覆盖

| 场景 | 客户端方法 |
|---|---|
| 任务奖励 / 任务选择 | `SetQuestItem` |
| 任务日志奖励 | `SetQuestLogItem` |
| 制造技能产物 | `SetTradeSkillItem` |
| 制造界面产物 | `SetCraftSpell` |
| 制造界面材料 | `SetCraftItem` |

### 对比框显示售价

对比框底部追加一行「售价：X」，数据来自 Cleanup 的 `TIP_ITEMS`（服务器 DB 导出），
金额格式化复用 TipPrice 暴露的 `TipPriceMoney()`。

```
当前装备
┌──────────────┐
│ 铜质钉锤     │
│ 主手         │
│ ...          │
│ 售价： 1银6铜 │
└──────────────┘
```
