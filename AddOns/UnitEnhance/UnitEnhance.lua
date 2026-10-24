--[[
    UnitEnhance —— 1.12 原生头像增强（参照 EN_UnitFrames 的 UI 与功能）

    UI 结构（与 EN 一致）：
      玩家/目标框右侧有一个深色「扩展面板」，竖排三行：
          98160/98160      ← 生命数值
          100%             ← 生命百分比
          40093/40093      ← 法力数值
      血条/法力条内部左侧仍显示各自百分比（绿色/蓝色）

    功能：
      * 玩家扩展：数值面板 + 经验条（含双倍经验）
      * 目标扩展：数值面板
      * 目标的目标：ToT 百分比
      * 小队扩展：小队 1~4 数值 + 百分比 + 队友目标小条
      * /ue 设置面板

    1.12 不支持的（按你的要求跳过）：
      * 焦点目标：没有 focus 单位
      * 目标的目标的目标：只有 targettarget，没有 targettargettarget
--]]

local FONT_ZH = "Fonts\\FZLBJW.TTF"
local TICK_SKIP = 5

local defaults = {
    player = true,
    xp = false,
    target = true,
    pct = true,
    tot = true,
    party = true,
    partyTarget = true,
}

local db
local entries = {}
local panels = {}
local tick = 0

-- ---------------------------------------------------------------- 基础工具

local function ApplyFont(fs, size)
    if GetLocale and GetLocale() == "zhCN" then
        fs:SetFont(FONT_ZH, size or 10, "")
    end
end

local function Opt(key)
    if db and db.opts and db.opts[key] ~= nil then
        return db.opts[key]
    end
    return defaults[key]
end

local function GetDB()
    if not UnitEnhanceDB then UnitEnhanceDB = {} end
    if not UnitEnhanceDB.opts then UnitEnhanceDB.opts = {} end
    db = UnitEnhanceDB
    return db
end

local function Pct(cur, max)
    if not max or max <= 0 then return 0 end
    return math.floor(cur * 100 / max + 0.5)
end

-- ---------------------------------------------------------------- 条内文字

-- 状态条内部只放百分比（左侧），颜色跟条一致
local function MakeBarPct(bar, unit, kind, group)
    if not bar then return nil end

    local pct = bar:CreateFontString(nil, "OVERLAY")
    ApplyFont(pct, 10)
    pct:SetPoint("LEFT", bar, "LEFT", 6, 0)
    if kind == "mana" then
        pct:SetTextColor(0.7, 0.85, 1)
    else
        pct:SetTextColor(0.7, 1, 0.7)
    end
    pct:SetText("")

    local e = { bar = bar, unit = unit, kind = kind, group = group, pct = pct }
    table.insert(entries, e)
    return e
end

-- ---------------------------------------------------------------- 扩展面板

-- 深色面板：竖排「生命数值 / 百分比 / 法力数值」，挂在血条右侧
local function MakePanel(healthBar, unit, group, side, name)
    if not healthBar then return nil end

    local f = CreateFrame("Frame", name, healthBar:GetParent() or UIParent)
    f:SetWidth(100)
    f:SetHeight(42)
    -- 顶部对齐血条上沿，让第一行文字正好落在血条高度上
    if side == "bottom" then
        f:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 22, -4)
    elseif side == "left" then
        f:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", -3, 16)
    else
        f:SetPoint("TOPLEFT", healthBar, "TOPRIGHT", 2, 16)
    end
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(0, 0, 0, 0.72)
    f:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.85)
    -- 必须抬高 frame level，否则背景会被父框架的贴图画在上面（文字是 OVERLAY 所以能看见）
    local parent = f:GetParent()
    if parent and parent.GetFrameLevel then
        f:SetFrameLevel(parent:GetFrameLevel() + 5)
    end

    -- 顺序：百分比(上) -> 生命数值(中) -> 法力数值(下)
    -- 玩家框的面板在右侧，文字左对齐；目标框的面板在左侧，文字右对齐
    local right = (side == "left")

    local pc = f:CreateFontString(nil, "OVERLAY")
    ApplyFont(pc, 11)
    if right then
        pc:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -2)
        pc:SetJustifyH("RIGHT")
    else
        pc:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -2)
        pc:SetJustifyH("LEFT")
    end
    pc:SetTextColor(0.75, 1, 0.75)
    pc:SetText("")

    local hp = f:CreateFontString(nil, "OVERLAY")
    ApplyFont(hp, 11)
    if right then
        hp:SetPoint("TOPRIGHT", pc, "TOPRIGHT", 0, -12)
        hp:SetJustifyH("RIGHT")
    else
        hp:SetPoint("TOPLEFT", pc, "TOPLEFT", 0, -12)
        hp:SetJustifyH("LEFT")
    end
    hp:SetTextColor(1, 1, 1)
    hp:SetText("")

    local mp = f:CreateFontString(nil, "OVERLAY")
    ApplyFont(mp, 11)
    if right then
        mp:SetPoint("TOPRIGHT", hp, "TOPRIGHT", 0, -12)
        mp:SetJustifyH("RIGHT")
    else
        mp:SetPoint("TOPLEFT", hp, "TOPLEFT", 0, -12)
        mp:SetJustifyH("LEFT")
    end
    mp:SetTextColor(0.75, 0.85, 1)
    mp:SetText("")

    local p = { frame = f, unit = unit, group = group,
                hp = hp, pct = pc, mp = mp }
    table.insert(panels, p)
    return p
end

local function UpdatePanel(p)
    if not Opt(p.group) or not UnitExists(p.unit) then
        p.frame:Hide()
        return
    end

    local hmax = UnitHealthMax(p.unit)
    local hcur = UnitHealth(p.unit)
    if not hmax or hmax <= 0 then
        p.frame:Hide()
        return
    end

    p.hp:SetText(tostring(hcur) .. "/" .. tostring(hmax))

    if Opt("pct") then
        p.pct:SetText(Pct(hcur, hmax) .. "%")
        p.pct:Show()
    else
        p.pct:SetText("")
    end

    local mmax = UnitManaMax(p.unit)
    local mcur = UnitMana(p.unit)
    if mmax and mmax > 0 then
        p.mp:SetText(tostring(mcur) .. "/" .. tostring(mmax))
    else
        p.mp:SetText("")
    end

    p.frame:Show()
end

local function UpdateEntry(e)
    local bar = e.bar
    if not bar then return end

    if not Opt(e.group) or not bar:IsShown() or not UnitExists(e.unit) then
        e.pct:Hide()
        return
    end

    local cur, max
    if e.kind == "mana" then
        cur, max = UnitMana(e.unit), UnitManaMax(e.unit)
    else
        cur, max = UnitHealth(e.unit), UnitHealthMax(e.unit)
    end

    if not cur or not max or max <= 0 then
        e.pct:Hide()
        return
    end

    if Opt("pct") then
        e.pct:SetText(Pct(cur, max) .. "%")
        e.pct:Show()
    else
        e.pct:Hide()
    end
end

-- ---------------------------------------------------------------- 注册

-- 玩家 / 目标：条内百分比 + 右侧扩展面板
MakePanel(getglobal("PlayerFrameHealthBar"), "player", "player", "right", "UEPanelPlayer")

MakePanel(getglobal("TargetFrameHealthBar"), "target", "target", "left", "UEPanelTarget")

-- 宠物 / 小队：只在条内显示百分比
MakeBarPct(getglobal("PetFrameHealthBar"), "pet", "hp", "player")
MakeBarPct(getglobal("PetFrameManaBar"), "pet", "mana", "player")
for i = 1, 4 do
    MakeBarPct(getglobal("PartyMemberFrame" .. i .. "HealthBar"),
               "party" .. i, "hp", "party")
end

-- 目标的目标百分比
local totPct, totAnchor
do
    local totBar = getglobal("TargetofTargetHealthBar")
    totAnchor = getglobal("TargetofTargetTextureFrame")
        or (totBar and totBar:GetParent()) or totBar
    if totAnchor then
        totPct = totAnchor:CreateFontString(nil, "OVERLAY")
        ApplyFont(totPct, 9)
        totPct:SetPoint("BOTTOM", totAnchor, "BOTTOM", 0, 2)
        totPct:SetTextColor(1, 0.9, 0.6)
        totPct:SetText("")
    end
end

-- 目标的目标的目标（实测本客户端支持 targettargettarget）
local tot2Pct
do
    local totFrame = getglobal("TargetofTargetFrame") or getglobal("TargetofTargetTextureFrame")
    if totFrame then
        tot2Pct = totFrame:CreateFontString(nil, "OVERLAY")
        ApplyFont(tot2Pct, 9)
        tot2Pct:SetPoint("TOP", totFrame, "BOTTOM", 0, -2)
        tot2Pct:SetTextColor(0.8, 0.9, 1)
        tot2Pct:SetText("")
    end
end

-- ---------------------------------------------------------------- 经验条

local xpBar, xpText
do
    local pf = getglobal("PlayerFrame")
    if pf then
        xpBar = CreateFrame("StatusBar", "UnitEnhanceXPBar", pf)
        xpBar:SetHeight(6)
        xpBar:SetWidth(180)
        xpBar:SetPoint("BOTTOMLEFT", pf, "BOTTOMLEFT", 44, -10)
        xpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        xpBar:SetStatusBarColor(0.58, 0, 0.55)
        xpBar:SetMinMaxValues(0, 1)
        xpBar:SetValue(0)

        xpBar.bg = xpBar:CreateTexture(nil, "BACKGROUND")
        xpBar.bg:SetAllPoints(xpBar)
        xpBar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        xpBar.bg:SetVertexColor(0.25, 0.25, 0.25, 0.8)

        xpText = xpBar:CreateFontString(nil, "OVERLAY")
        ApplyFont(xpText, 9)
        xpText:SetPoint("BOTTOM", xpBar, "TOP", 0, 1)
        xpText:SetTextColor(1, 0.82, 0)
        xpText:SetText("")
    end
end

local function UpdateXP()
    -- 按需求关闭经验条显示
    if xpBar then xpBar:Hide() end
    if xpText then xpText:Hide() end
end

-- ---------------------------------------------------------------- 队友目标

local partyTargetFrames = {}
for i = 1, 4 do
    local pf = getglobal("PartyMemberFrame" .. i)
    if pf then
        local f = CreateFrame("Frame", nil, pf)
        f:SetWidth(76)
        f:SetHeight(14)
        f:SetPoint("BOTTOMLEFT", pf, "BOTTOMLEFT", 0, -16)

        local bar = CreateFrame("StatusBar", nil, f)
        bar:SetWidth(76)
        bar:SetHeight(8)
        bar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(0.8, 0.15, 0.15)
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)

        local text = bar:CreateFontString(nil, "OVERLAY")
        ApplyFont(text, 8)
        text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        text:SetTextColor(1, 1, 1)
        text:SetText("")

        f.bar = bar
        f.text = text
        f.unit = "party" .. i .. "target"
        f:Hide()
        partyTargetFrames[i] = f
    end
end

local function UpdatePartyTargets()
    local i, f, unit
    for i = 1, 4 do
        f = partyTargetFrames[i]
        if f then
            unit = f.unit
            if Opt("party") and Opt("partyTarget") and UnitName(unit) then
                local max = UnitHealthMax(unit)
                local cur = UnitHealth(unit)
                if max and max > 0 then
                    f.bar:SetMinMaxValues(0, max)
                    f.bar:SetValue(cur)
                    f.text:SetText(Pct(cur, max) .. "%")
                    f:Show()
                else
                    f:Hide()
                end
            else
                f:Hide()
            end
        end
    end
end

-- ---------------------------------------------------------------- 主循环

local driver = CreateFrame("Frame", nil, UIParent)
driver:SetWidth(1)
driver:SetHeight(1)
driver:Show()
driver:SetScript("OnUpdate", function()
    tick = tick + 1
    if tick < TICK_SKIP then return end
    tick = 0

    local i
    for i = 1, table.getn(entries) do
        UpdateEntry(entries[i])
    end
    for i = 1, table.getn(panels) do
        UpdatePanel(panels[i])
    end
    UpdateXP()
    UpdatePartyTargets()

    if totPct then
        -- 不再每帧 Show()：客户端的 TargetofTarget_OnUpdate 会 Hide 它，
        -- 两边抢会造成闪烁。交给客户端自己控制显隐。
        if Opt("target") and Opt("tot") and UnitName("targettarget") then
            local cur, max = UnitHealth("targettarget"), UnitHealthMax("targettarget")
            if max and max > 0 then
                totPct:SetText(Pct(cur, max) .. "%")
                totPct:Show()
            else
                totPct:Hide()
            end
        else
            totPct:Hide()
        end
    end

    if tot2Pct then
        if Opt("target") and Opt("tot") and UnitName("targettargettarget") then
            local cur, max = UnitHealth("targettargettarget"), UnitHealthMax("targettargettarget")
            if max and max > 0 then
                tot2Pct:SetText("" .. math.floor(cur * 100 / max + 0.5) .. "%")
                tot2Pct:Show()
            else
                tot2Pct:Hide()
            end
        else
            tot2Pct:Hide()
        end
    end
end)

-- ---------------------------------------------------------------- 设置面板

local panel
local panelRows = {
    { key = "player",      label = "开启玩家头像扩展" },
    { key = "xp",          label = "    显示经验条" },
    { key = "target",      label = "开启目标头像扩展" },
    { key = "pct",         label = "    显示百分比" },
    { key = "tot",         label = "显示目标的目标" },
    { key = "party",       label = "开启队友头像扩展" },
    { key = "partyTarget", label = "    显示队友目标" },
}

local function RefreshPanel()
    if not panel then return end
    local i, row
    for i = 1, table.getn(panel.checks) do
        row = panel.checks[i]
        if Opt(row.ueKey) then
            row:SetChecked(1)
        else
            row:SetChecked(nil)
        end
    end
end

local function BuildPanel()
    if panel then return panel end

    panel = CreateFrame("Frame", "UnitEnhancePanel", UIParent)
    panel:SetWidth(320)
    panel:SetHeight(300)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    panel:Hide()

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyFont(title, 14)
    title:SetPoint("TOP", panel, "TOP", 0, -14)
    title:SetText("头像增强")

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)

    panel.checks = {}
    local y = -40
    local i, row
    for i = 1, table.getn(panelRows) do
        row = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        row:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, y)
        row:SetWidth(24)
        row:SetHeight(24)
        row.ueKey = panelRows[i].key

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ApplyFont(label, 12)
        label:SetPoint("LEFT", row, "RIGHT", 4, 0)
        label:SetText(panelRows[i].label)

        row:SetScript("OnClick", function()
            local v = this:GetChecked()
            if v then v = true else v = false end
            UnitEnhanceDB.opts[this.ueKey] = v
            RefreshPanel()
        end)

        table.insert(panel.checks, row)
        y = y - 30
    end

    return panel
end

-- ---------------------------------------------------------------- 初始化与命令

local init = CreateFrame("Frame")
init:RegisterEvent("VARIABLES_LOADED")
init:RegisterEvent("PLAYER_ENTERING_WORLD")
local layoutDone = false

init:SetScript("OnEvent", function()
    GetDB()
    if panel then RefreshPanel() end

    -- 首次安装时把目标框往右挪一次，给玩家框的面板腾位置；
    -- 之后不再干预，玩家可以自由拖动目标框。
    if not layoutDone then
        layoutDone = true
        if not UnitEnhanceDB.targetPinned then
            UnitEnhanceDB.targetPinned = true
            local pf, tf = getglobal("PlayerFrame"), getglobal("TargetFrame")
            if pf and tf then
                tf:ClearAllPoints()
                tf:SetPoint("TOPLEFT", pf, "TOPLEFT", 340, 0)
            end
        end
    end
end)

SLASH_UNITENHANCE1 = "/ue"
SlashCmdList["UNITENHANCE"] = function(msg)
    GetDB()
    msg = string.lower(msg or "")
    if msg == "on" then
        local k
        for k = 1, table.getn(panelRows) do
            UnitEnhanceDB.opts[panelRows[k].key] = true
        end
        RefreshPanel()
        DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f头像增强|r 全部开启", 1, 1, 0)
    elseif msg == "off" then
        UnitEnhanceDB.opts.player = false
        UnitEnhanceDB.opts.target = false
        UnitEnhanceDB.opts.party = false
        UnitEnhanceDB.opts.tot = false
        RefreshPanel()
        DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f头像增强|r 全部关闭", 1, 1, 0)
    else
        local p = BuildPanel()
        if p:IsShown() then
            p:Hide()
        else
            RefreshPanel()
            p:Show()
        end
    end
end
