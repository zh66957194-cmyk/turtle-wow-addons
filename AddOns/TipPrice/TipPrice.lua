--[[
    TipPrice — 物品价格显示（1.12 / Lua 5.0）

    接入方式与 MasterTradeSkills 相同：使用 LibItemTooltip-1.0（已随
    MasterTradeSkills / ItemTooltipIcons 加载）。该库包装了
    GameTooltip:SetBagItem / SetMerchantItem / SetHyperlink 等函数，
    在提示框显示时回调 (tooltip, item_link, item_id)，
    所以既不用轮询取链接，也不会和别的方法级 Hook 冲突。

    价格数据来自本地服务器导出的 TIP_ITEMS（TipPrice_Data.lua）：
        TIP_ITEMS[物品ID] = {售价, 堆叠上限}
--]]

local OFFSET_X = 16
local OFFSET_Y = 16

-- 金币/银币/铜币单位的颜色（数字保持默认白色）
local COLOR_GOLD   = "|cffffd700"
local COLOR_SILVER = "|cffc7c7cf"
local COLOR_COPPER = "|cffeda55f"

local function Copper(copper)
    local g = math.floor(copper / 10000)
    copper = copper - g * 10000
    local s = math.floor(copper / 100)
    local c = copper - s * 100
    local out = ""
    if g > 0 then out = out .. g .. COLOR_GOLD .. "金|r " end
    if s > 0 then out = out .. s .. COLOR_SILVER .. "银|r " end
    if c > 0 or out == "" then out = out .. c .. COLOR_COPPER .. "铜|r" end
    return out
end

-- 鼠标悬停格子的实际堆叠数量（背包 / 银行）
local function HoveredCount()
    local f = GetMouseFocus()
    if not f or not f.GetID then return nil end
    local slot = f:GetID()
    local parent = f:GetParent()
    if not slot or not parent or not parent.GetID then return nil end
    local bag = parent:GetID()
    if bag and bag >= 0 and bag <= 10 then
        local _, count = GetContainerItemInfo(bag, slot)
        return count
    end
    return nil
end

-- 在提示框里追加价格行
local function OnItemTooltipShow(tooltip, itemLink, itemID)
    if not itemID then return end
    local item = TIP_ITEMS and TIP_ITEMS[itemID]
    if not item then return end

    local sell = item[1]
    local stack = item[2] or 1
    if type(sell) ~= "number" or sell <= 0 then return end

    local count = HoveredCount() or 1
    if type(count) ~= "number" or count < 1 then count = 1 end

    tooltip:AddLine(" ")
    tooltip:AddLine("单价：" .. Copper(sell), 1, 1, 1)
    if stack > 1 then
        tooltip:AddLine("一组(" .. stack .. ")：" .. Copper(sell * stack), 1, 1, 1)
    end
    -- 当前数量总价：整行黄色
    tooltip:AddLine("当前(" .. count .. ")：" .. Copper(sell * count), 1, 0.82, 0)
    tooltip:Show()
end

-- LibItemTooltip 由 MasterTradeSkills / ItemTooltipIcons 提供，
-- 加载顺序不确定，所以延迟到能用时再注册一次。
local tpRegistered = false
local function TryRegister()
    if tpRegistered then return end
    local LS = getglobal("LibStub")
    if not LS then return end
    local l = LS("LibItemTooltip-1.0", true)
    if not l then return end
    l:RegisterEvent("OnShow", OnItemTooltipShow)
    tpRegistered = true
end
TryRegister()

-- 跟随鼠标：提示框显示期间每帧按光标位置重新锚定（右上方，边缘翻转）
local function Place(tooltip)
    local scale = UIParent:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx = cx / scale
    cy = cy / scale

    local w = tooltip:GetWidth() or 200
    local h = tooltip:GetHeight() or 100
    local sw = GetScreenWidth() / scale
    local sh = GetScreenHeight() / scale

    local x, y
    -- 默认放在鼠标右上方：左边界在光标右侧，下边界在光标上方
    if cx + OFFSET_X + w > sw then
        x = cx - OFFSET_X - w          -- 右边放不下：翻到左侧
    else
        x = cx + OFFSET_X
    end
    if cy + OFFSET_Y + h > sh then
        y = cy - OFFSET_Y - h          -- 上面放不下：翻到下方
    else
        y = cy + OFFSET_Y
    end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end

    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
end

local followFrame = CreateFrame("Frame", nil, UIParent)
followFrame:SetWidth(1)
followFrame:SetHeight(1)
followFrame:Show()

-- ---------------------------------------------------------------- 全量兜底：所有名字带 tip 的框架强制不透明
-- 单位（人物/敌对生物）的提示框在本客户端可能不是 GameTooltip，
-- 所以扫描所有名字含 "tip" 的框架，显示时把 alpha 拉回 1。
local tipFrames = {}
local collected = false

local function CollectTipFrames()
    tipFrames = {}
    local ok = pcall(function()
        local f = EnumerateFrames()
        while f do
            local n = f.GetName and f:GetName()
            if n and string.find(string.lower(n), "tip") then
                table.insert(tipFrames, f)
            end
            f = EnumerateFrames(f)
        end
    end)
    return ok
end

local function ForceTipAlpha()
    local i, f
    for i = 1, table.getn(tipFrames) do
        f = tipFrames[i]
        if f and f.IsShown and f:IsShown() and f.GetAlpha then
            if f:GetAlpha() ~= 1 then
                -- 把这个框架从 UIFrameFade 的动画列表里摘掉，再拉回不透明
                if UIFrameFadeRemoveFrame then
                    UIFrameFadeRemoveFrame(f)
                end
                f:SetAlpha(1)
            end
        end
    end
end

local scanTick = 0

-- 动作条按钮：客户端每帧都会把提示框摆回自己的位置，
-- 我们再去挪就会和它互相抢，表现为提示框来回闪。这类按钮不接管定位。
local function IsActionBarFocus()
    local f = GetMouseFocus()
    if not f or not f.GetName then return false end
    local n = f:GetName()
    if not n then return false end
    return string.find(n, "ActionButton")
        or string.find(n, "StanceButton")
        or string.find(n, "PetActionButton")
        or string.find(n, "MultiBar")
        or string.find(n, "ShapeshiftButton")
end


-- ---------------------------------------------------------------- 修复：单位提示框误显示专业图标
-- LibItemTooltip 只在 SetBagItem/SetMerchantItem 等里记录物品链接，
-- 显示单位提示框时旧链接没有清空，于是 ItemTooltipIcons 把上一次的物品
-- 当成当前内容，往「狗头人矿工」这类单位提示框里塞了专业图标。
-- 这里在 SetUnit 时把库里的缓存清掉。
do
    local LibStub = getglobal("LibStub")
    local lib = LibStub and LibStub("LibItemTooltip-1.0", true)
    if lib and GameTooltip.SetUnit then
        local origSetUnit = GameTooltip.SetUnit
        GameTooltip.SetUnit = function(self, unit)
            lib.game_tooltip_item_link = nil
            return origSetUnit(self, unit)
        end
    end
end

followFrame:SetScript("OnUpdate", function()
    scanTick = scanTick + 1
    if not collected and scanTick > 60 then
        collected = CollectTipFrames()
        scanTick = 0
    end
    ForceTipAlpha()
    TryRegister()
    local actionBar = IsActionBarFocus()

    if GameTooltip:IsShown() then
        if not actionBar then
            Place(GameTooltip)
        end
        -- 强制不透明：本客户端提示框有淡入淡出，这里每帧拉回 1
        if GameTooltip:GetAlpha() ~= 1 then
            GameTooltip:SetAlpha(1)
        end
    end
    -- ItemRefTooltip（聊天点物品链接的提示框）不接管：
    -- 它靠自己的淡出关闭，强制 alpha 会让它关不掉
end)

-- 供其他插件复用金额格式化
TipPriceMoney = Copper
