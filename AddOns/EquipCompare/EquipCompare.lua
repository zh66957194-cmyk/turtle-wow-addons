--[[
    EquipCompare —— 1.12 装备自动对比

    移植自 335 客户端的 EquipmentCompare（stillwater）。
    1.12 没有 OnTooltipSetItem / GameTooltip_ShowCompareItem，
    改为包装 GameTooltip:SetBagItem / SetInventoryItem；
    GetItemInfo 只返回 3 个字段（4~9 全 nil），部位靠提示框文本关键字判断。

    对比框用客户端的 ShoppingTooltip1/2（已验证可用），
    上面额外加一条红色、大一号的「当前装备」标题条。
--]]

local HEADER_TEXT = "当前装备"
local HEADER_SIZE = 13

-- 关键字按优先级排列（长词在前，避免「手」抢走「双手/手套」）
local SLOT_KEYWORDS = {
    { key = "单手", slots = { 16 } },
    { key = "双手", slots = { 16 } },
    { key = "主手", slots = { 16 } },
    { key = "副手", slots = { 17 } },
    { key = "盾牌", slots = { 17 } },
    { key = "手套", slots = { 10 } },
    { key = "手腕", slots = { 9 } },
    { key = "手指", slots = { 11, 12 } },
    { key = "饰品", slots = { 13, 14 } },
    { key = "头部", slots = { 1 } },
    { key = "颈部", slots = { 2 } },
    { key = "肩部", slots = { 3 } },
    { key = "衬衣", slots = { 4 } },
    { key = "胸部", slots = { 5 } },
    { key = "腰部", slots = { 6 } },
    { key = "腿部", slots = { 7 } },
    { key = "背部", slots = { 15 } },
    { key = "远程", slots = { 18 } },
    { key = "投掷", slots = { 18 } },
    { key = "魔杖", slots = { 18 } },
    { key = "圣物", slots = { 19 } },
    { key = "圣契", slots = { 19 } },
    { key = "图腾", slots = { 19 } },
    { key = "神像", slots = { 19 } },
    -- 远程武器：提示框里可能只写武器类型，没有「远程」前缀
    { key = "弩",   slots = { 18 } },
    { key = "枪械", slots = { 18 } },
    { key = "枪",   slots = { 18 } },
    { key = "弓",   slots = { 18 } },
    { key = "投掷", slots = { 18 } },
    { key = "脚",   slots = { 8 } },
    { key = "手",   slots = { 10 } },
}

local FONT_ZH = "Fonts\\FZLBJW.TTF"

local function ApplyFont(fs, size)
    if GetLocale and GetLocale() == "zhCN" then
        fs:SetFont(FONT_ZH, size, "")
    end
end

local function GetItemID(link)
    if not link then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    return id and tonumber(id)
end

-- 从提示框文本里找部位关键字
local function FindSlots(tooltip)
    local name = tooltip:GetName()
    local n = tooltip:NumLines() or 0
    if n < 2 then return nil end

    local i, j, fs, text, entry, head
    -- 只看物品信息头部（第 2~4 行），且关键字必须出现在行首。
    -- 否则像「虎眼石」的配方列表里有「铜质宝石手套」，会被误判成手套。
    -- 扫描 2~6 行：蓝装/紫装常有「唯一」「装备后绑定」等额外行，
    -- 部位行会被挤到第 4、5 行，只看 2~4 会漏掉
    for i = 2, 6 do
        if i > n then break end
        fs = getglobal(name .. "TextLeft" .. i)
        text = fs and fs:GetText()
        if text then
            for j = 1, table.getn(SLOT_KEYWORDS) do
                entry = SLOT_KEYWORDS[j]
                head = string.sub(text, 1, string.len(entry.key))
                if head == entry.key then
                    return entry.slots
                end
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------- 标题条

local headers = {}

local function GetHeader(index)
    if headers[index] then return headers[index] end

    local f = CreateFrame("Frame", "ECHeader" .. index, UIParent)
    f:SetWidth(150)
    f:SetHeight(26)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, 0.85)
    f:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    f:SetFrameStrata("TOOLTIP")

    f.text = f:CreateFontString(nil, "OVERLAY")
    ApplyFont(f.text, HEADER_SIZE)
    -- 用两点锚定让文字块填满标题条，再靠 JustifyV 居中：
    -- 这样不管字体行高怎么变，文字一定在框体垂直中间。
    f.text:SetPoint("TOPLEFT", f, "TOPLEFT", 10, 0)
    f.text:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 0)
    f.text:SetJustifyH("LEFT")
    f.text:SetJustifyV("MIDDLE")
    f.text:SetText(HEADER_TEXT)
    f.text:SetTextColor(1, 0.15, 0.15)

    f:Hide()
    headers[index] = f
    return f
end

-- ---------------------------------------------------------------- 对比显示

local function HideCompare()
    local i, tip
    for i = 1, 2 do
        tip = getglobal("ShoppingTooltip" .. i)
        if tip then tip:Hide() end
        if headers[i] then headers[i]:Hide() end
    end
end

local function ShowCompare(slots, hoveredID)
    HideCompare()

    local idx = 0
    local i, link, id, tip, head, prevTip
    for i = 1, table.getn(slots) do
        link = GetInventoryItemLink("player", slots[i])
        id = GetItemID(link)
        -- 不再跳过「和身上装备同 ID」的情况：
        -- 玩家经常需要拿同款装备对比（附魔/宝石/耐久差异），跳过会导致完全没提示
        if link then
            idx = idx + 1
            if idx > 2 then break end

            tip = getglobal("ShoppingTooltip" .. idx)
            if tip then
                head = GetHeader(idx)
                head:ClearAllPoints()
                if idx == 1 then
                    head:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 6, 0)
                else
                    head:SetPoint("TOPLEFT", prevTip, "TOPRIGHT", 6, 22)
                end

                tip:SetOwner(GameTooltip, "ANCHOR_NONE")
                tip:ClearAllPoints()
                tip:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, 0)
                tip:SetInventoryItem("player", slots[i])

                -- 追加售价（数据来自 Cleanup 的 TIP_ITEMS）
                local itemID = GetItemID(link)
                local item = itemID and TIP_ITEMS and TIP_ITEMS[itemID]
                if item and item[1] and item[1] > 0 then
                    local money = item[1]
                    local txt
                    if TipPriceMoney then
                        txt = TipPriceMoney(money)
                    else
                        txt = tostring(math.floor(money / 100) / 100) .. "金"
                    end
                    tip:AddLine(" ")
                    tip:AddLine("售价：" .. txt, 1, 1, 1)
                end

                tip:SetAlpha(1)
                tip:Show()

                head:SetAlpha(1)
                head:SetWidth(tip:GetWidth() or 150)
                head:Show()

                prevTip = tip
            end
        end
    end
end

local function HookTooltip(methodName, getLink)
    local orig = GameTooltip[methodName]
    if not orig then return end
    GameTooltip[methodName] = function(self, a, b)
        orig(self, a, b)
        -- 出任何错都不能影响原版提示框
        pcall(function()
            local link = getLink(a, b)
            if not link then
                HideCompare()
                return
            end
            local slots = FindSlots(self)
            if not slots then
                HideCompare()
                return
            end
            ShowCompare(slots, GetItemID(link))
        end)
    end
end

HookTooltip("SetBagItem", function(bag, slot)
    if bag and slot then return GetContainerItemLink(bag, slot) end
end)

-- 商人回购（buyback）栏
-- 本客户端没有 GetBuybackItemLink（实测为 nil），拿不到物品链接，
-- 但只要部位能识别出来就够做对比，所以这里不需要 link。
do
    local orig = GameTooltip.SetBuybackItem
    if orig then
        GameTooltip.SetBuybackItem = function(self, a, b)
            orig(self, a, b)
            pcall(function()
                local slots = FindSlots(self)
                if not slots then
                    HideCompare()
                    return
                end
                ShowCompare(slots, nil)
            end)
        end
    end
end

-- 商人：接管对比，同时屏蔽客户端自带的商人对比（样式不统一）
HookTooltip("SetMerchantItem", function(index)
    if index then return GetMerchantItemLink(index) end
end)

-- 让客户端原生的商人对比永远返回 nil，这样它不会再 Show 自己的对比框，
-- 由我们的系统（带红色标题 + 售价）接管。
do
    local tip1 = getglobal("ShoppingTooltip1")
    local tip2 = getglobal("ShoppingTooltip2")
    if tip1 and tip1.SetMerchantCompareItem then
        tip1.SetMerchantCompareItem = function() return nil end
    end
    if tip2 and tip2.SetMerchantCompareItem then
        tip2.SetMerchantCompareItem = function() return nil end
    end
end

-- 专业训练师：悬停配方时对比（拿不到物品链接，只靠提示框部位判断）
do
    local orig = GameTooltip.SetTrainerService
    if orig then
        GameTooltip.SetTrainerService = function(self, a, b)
            orig(self, a, b)
            pcall(function()
                local slots = FindSlots(self)
                if not slots then
                    HideCompare()
                    return
                end
                ShowCompare(slots, nil)
            end)
        end
    end
end

-- 任务奖励（选择/奖励列表）
HookTooltip("SetQuestItem", function(qtype, index)
    if qtype and index then return GetQuestItemLink(qtype, index) end
end)

HookTooltip("SetQuestLogItem", function(qtype, index)
    if qtype and index then return GetQuestLogItemLink(qtype, index) end
end)

-- 制造技能：产物 / 配方材料 / 制造界面
HookTooltip("SetTradeSkillItem", function(index)
    if index then return GetTradeSkillItemLink(index) end
end)

HookTooltip("SetCraftItem", function(skill, slot)
    if skill and slot then return GetCraftReagentItemLink(skill, slot) end
end)

HookTooltip("SetCraftSpell", function(slot)
    if slot then return GetCraftItemLink(slot) end
end)

-- 注意：不包装 SetInventoryItem。
-- 1.12 的人物装备面板（纸娃娃）依赖它，包装后会导致面板上的提示框异常，
-- 所以只处理背包（SetBagItem）。装备栏本身不需要对比。

-- 主提示框隐藏时收起对比框（1.12 的 OnUpdate 没有 elapsed）
local watcher = CreateFrame("Frame", nil, UIParent)
watcher:SetWidth(1)
watcher:SetHeight(1)
watcher:Show()
local lastShown = false
watcher:SetScript("OnUpdate", function()
    local shown = GameTooltip:IsShown() and true or false
    if lastShown and not shown then
        HideCompare()
    end
    lastShown = shown
end)

-- 调试：/ec test 预览「当前装备」对比框
SLASH_EQUIPCOMPARE1 = "/ec"
SlashCmdList["EQUIPCOMPARE"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "test" then
        local tip = getglobal("ShoppingTooltip1")
        if tip then
            tip:SetOwner(UIParent, "ANCHOR_NONE")
            tip:ClearAllPoints()
            tip:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 60, -260)
            tip:SetInventoryItem("player", 16)
            local tid = GetItemID(GetInventoryItemLink("player", 16))
            local ti = tid and TIP_ITEMS and TIP_ITEMS[tid]
            if ti and ti[1] and ti[1] > 0 then
                tip:AddLine(" ")
                tip:AddLine("售价：" .. (TipPriceMoney and TipPriceMoney(ti[1]) or tostring(ti[1])), 1, 1, 1)
            end
            tip:Show()

            local head = GetHeader(1)
            head:ClearAllPoints()
            head:SetPoint("BOTTOMLEFT", tip, "TOPLEFT", 0, 0)
            head:SetWidth(tip:GetWidth() or 150)
            head:Show()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f装备对比|r /ec test 预览对比框", 1, 1, 0)
    end
end
