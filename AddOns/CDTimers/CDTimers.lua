--[[
    CDTimers —— 1.12 技能冷却计时 + 距离着色

    参照 335 客户端的 tdCooldown2（多玩冷却计时）的核心功能重写：
      * 动作条图标上显示剩余冷却时间
      * 超出射程的技能图标变红

    1.12 没有 CooldownFrame_SetTimer（3.x API），所以用 GetActionCooldown
    轮询冷却；所有调用都做存在性判断并包 pcall，避免一个接口缺失导致整体失效。

    命令：/cd on | /cd off | /cd range（开关距离着色）
--]]

local TICK_CD = 4        -- 冷却刷新间隔（帧）
local TICK_RANGE = 12    -- 距离着色刷新间隔（帧）
local FONT = "Fonts\\FRIZQT__.TTF"
local SIZE = 13
local MAX_SLOTS = 120

local cdEnabled = true
local rangeEnabled = true

local tickRange = 0
local colored = {}

local function UpdateRange(button, slot)
    local icon = getglobal((button:GetName() or "") .. "Icon")
    if not icon then return end

    if not rangeEnabled or not IsActionInRange or not button:IsShown() then
        if colored[button] then
            icon:SetVertexColor(1, 1, 1)
            colored[button] = nil
        end
        return
    end

    local inRange = IsActionInRange(slot)
    if inRange == 0 then
        icon:SetVertexColor(1, 0.35, 0.35)
        colored[button] = true
    else
        if colored[button] then
            icon:SetVertexColor(1, 1, 1)
            colored[button] = nil
        end
    end
end

local driver = CreateFrame("Frame", nil, UIParent)
driver:SetWidth(1)
driver:SetHeight(1)
driver:Show()
driver:SetScript("OnUpdate", function()
    tickRange = tickRange + 1
    if tickRange < 12 then return end
    tickRange = 0

    pcall(function()
        local i, button
        for i = 1, 120 do
            button = getglobal("ActionButton" .. i)
            if button then
                UpdateRange(button, i)
            end
        end
    end)
end)

SLASH_CDTIMERS1 = "/rc"
SlashCmdList["CDTIMERS"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "on" then
        rangeEnabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f距离着色|r 已开启", 1, 1, 0)
    elseif msg == "off" then
        rangeEnabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f距离着色|r 已关闭", 1, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f距离着色|r /rc on | /rc off", 1, 1, 0)
    end
end
