-- ToTPlus —— 目标链显示（可点击）
-- 两行：左边名字，右边血量百分比；点击选中对应单位。

local FONT = "Fonts\\FZLBJW.TTF"
local ROW_H = 20
local FONT_SIZE = 13

local wrap = CreateFrame("Frame", "ToTPlusFrame", UIParent)
wrap:SetWidth(150)
wrap:SetPoint("TOPLEFT", TargetFrame, "BOTTOMRIGHT", -74, -10)
wrap:SetFrameStrata("MEDIUM")

local function MakeRow(unit, offsetY, r, g, b)
    local row = CreateFrame("Button", nil, wrap)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", wrap, "TOPLEFT", 0, offsetY)
    row:SetPoint("TOPRIGHT", wrap, "TOPRIGHT", 0, offsetY)

    -- 血条（在文字下面）
    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetAllPoints(row)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.1, 0.7, 0.1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)

    row.bar = bar

    -- 悬停时显示的蓝色描边
    local border = CreateFrame("Frame", nil, row)
    border:SetPoint("TOPLEFT", row, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10 })
    border:SetBackdropBorderColor(0.05, 0.45, 1, 1)
    border:SetFrameLevel(row:GetFrameLevel() + 5)   -- 抬到血条与文字之上
    border:Hide()

    row:SetScript("OnEnter", function() border:Show() end)
    row:SetScript("OnLeave", function() border:Hide() end)


    local name = bar:CreateFontString(nil, "OVERLAY")
    name:SetFont(FONT, FONT_SIZE, "OUTLINE")
    name:SetPoint("LEFT", row, "LEFT", 4, 0)
    name:SetJustifyH("LEFT")
    name:SetTextColor(r, g, b)
    name:SetText("")

    local pct = bar:CreateFontString(nil, "OVERLAY")
    pct:SetFont(FONT, FONT_SIZE, "OUTLINE")
    pct:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    pct:SetJustifyH("RIGHT")
    pct:SetTextColor(r, g, b)
    pct:SetText("")

    row.nameText = name
    row.pctText = pct
    row.unit = unit
    row:SetScript("OnClick", function()
        if UnitExists(unit) then
            TargetUnit(unit)
        end
    end)
    row:Hide()
    return row
end

local row1 = MakeRow("targettarget", 0, 1, 0.9, 0.6)
local row2 = MakeRow("targettargettarget", -(ROW_H + 3), 0.75, 0.85, 1)

local driver = CreateFrame("Frame", nil, UIParent)
driver:SetWidth(1)
driver:SetHeight(1)
driver:Show()

local tick = 0
local function UpdateRow(row, unit, staticRight)
    if not UnitName(unit) then
        row:Hide()
        return
    end
    row.nameText:SetText(UnitName(unit))
    local cur, max = UnitHealth(unit), UnitHealthMax(unit)
    if cur and max and max > 0 then
        row.pctText:SetText(tostring(cur) .. "/" .. tostring(max))
        row.bar:SetMinMaxValues(0, max)
        row.bar:SetValue(cur)
    else
        row.pctText:SetText("")
        row.bar:SetValue(0)
    end
    row:Show()
end

driver:SetScript("OnUpdate", function()
    tick = tick + 1
    if tick < 5 then
        return
    end
    tick = 0

    -- 宽度跟随目标框

    UpdateRow(row1, "targettarget")
    UpdateRow(row2, "targettargettarget")

    if UnitName("targettarget") or UnitName("targettargettarget") then
        local rows = 1
        if UnitName("targettargettarget") then rows = 2 end
        if rows == 2 then
            wrap:SetHeight(ROW_H * 2 + 3)
        else
            wrap:SetHeight(ROW_H)
        end
        wrap:Show()
    else
        wrap:Hide()
    end
end)

SLASH_TOTPLUS1 = "/tot"
SlashCmdList["TOTPLUS"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f目标链|r ToT=" .. tostring(UnitName("targettarget")) .. " ToToT=" .. tostring(UnitName("targettargettarget")), 1, 1, 0)
end
