--[[
    MinimapBag —— 1.12 小地图按钮收纳

    背景：ImmersiveButtonTray 能采集按钮（实测按钮确实被隐藏了），
    但它的托盘框架在 1.12 上没能正常显示，导致按钮"消失且无法打开"。
    所以自己实现：采集逻辑简单直接，显示层完全可控。

    实现：
      * 扫描所有锚定在 Minimap 上的 Button（排除缩放/追踪等原生按钮）
      * 记录原始父框架与锚点，然后塞进袋子网格
      * 袋子由小地图左下角一个常驻按钮开关
      * /mmb restore 可把按钮全部放回原位
--]]

local BUTTON_SIZE = 30
local COLS = 4
local SPACING = 4

local bag, toggleBtn
local items = {}
local opened = false

local function Msg(s)
    DEFAULT_CHAT_FRAME:AddMessage("|cff7fff7f小地图收纳|r " .. s, 1, 1, 0)
end

-- 原生按钮不收
local IGNORE = {
    MiniMapWorldMapButton = true,
    MinimapZoomIn = true,
    MinimapZoomOut = true,
    MiniMapTracking = true,
    MiniMapTrackingButton = true,
    MiniMapMailFrame = true,
    MiniMapBattlefieldFrame = true,
    TimeManagerClockButton = true,
    GameTimeFrame = true,
}

-- 名称里带这些片段的框架一律不采集（任务标记、地图节点等）
-- 只排除任务标记/地图节点这一类；pfQuest 的启动按钮（pfQuestIcon）要能被收纳
local EXCLUDE = { "node", "marker", "pin", "pfmap" }

local function IsExcluded(name)
    local lower = string.lower(name)
    local i
    for i = 1, table.getn(EXCLUDE) do
        if string.find(lower, EXCLUDE[i], 1, true) then
            return true
        end
    end
    return false
end

local function IsCollectable(btn)
    if not btn or not btn.GetObjectType then return false end
    if btn:GetObjectType() ~= "Button" then return false end
    local n = btn:GetName()
    if not n or IGNORE[n] then return false end
    if IsExcluded(n) then return false end
    if btn == toggleBtn then return false end

    -- 精确白名单：pfQuest 的启动按钮锚点不在 Minimap 上，单独放行
    -- （注意不能用 substring 匹配 pfquest，会把 pfQuest 的设置面板一起收进来）
    if n == "pfQuestIcon" then
        return true
    end

    local _, rel = btn:GetPoint()
    return rel == Minimap
end

local function BuildBag()
    if bag then return end

    bag = CreateFrame("Frame", "MinimapBagFrame", UIParent)
    bag:SetWidth(COLS * (BUTTON_SIZE + SPACING) + SPACING)
    bag:SetHeight(60)
    bag:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -6)
    bag:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    bag:SetBackdropColor(0, 0, 0, 0.85)
    bag:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    bag:SetFrameStrata("MEDIUM")
    bag:Hide()

    toggleBtn = CreateFrame("Button", "MinimapBagToggle", Minimap)
    toggleBtn:SetWidth(24)
    toggleBtn:SetHeight(24)
    toggleBtn:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, -2)
    toggleBtn:SetNormalTexture("Interface\\Icons\\INV_Misc_Bag_08")
    toggleBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    toggleBtn:SetScript("OnClick", function()
        if opened then
            bag:Hide()
            opened = false
        else
            bag:Show()
            opened = true
        end
    end)
end

local function Collect()
    BuildBag()
    items = {}

    local f = EnumerateFrames()
    while f do
        if IsCollectable(f) then
            local point, rel, relPoint, x, y = f:GetPoint()
            table.insert(items, {
                btn = f,
                parent = f:GetParent(),
                point = point, rel = rel, relPoint = relPoint, x = x, y = y,
            })
        end
        f = EnumerateFrames(f)
    end

    local i, it, btn, col, row
    for i = 1, table.getn(items) do
        it = items[i]
        btn = it.btn
        col = math.mod(i - 1, COLS)
        row = math.floor((i - 1) / COLS)

        btn:SetParent(bag)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", bag, "TOPLEFT",
                     SPACING + col * (BUTTON_SIZE + SPACING),
                     -(SPACING + row * (BUTTON_SIZE + SPACING)))
        btn:SetWidth(BUTTON_SIZE)
        btn:SetHeight(BUTTON_SIZE)
        btn:Show()
    end

    local rows = math.ceil(table.getn(items) / COLS)
    if rows < 1 then rows = 1 end
    bag:SetHeight(rows * (BUTTON_SIZE + SPACING) + SPACING)
end

local function Restore()
    local i, it, btn
    for i = 1, table.getn(items) do
        it = items[i]
        btn = it.btn
        btn:SetParent(it.parent or Minimap)
        btn:ClearAllPoints()
        if it.point then
            btn:SetPoint(it.point, it.rel or Minimap, it.relPoint or it.point, it.x or 0, it.y or 0)
        else
            btn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
        end
        btn:SetWidth(32)
        btn:SetHeight(32)
        btn:Show()
    end
    items = {}
end

-- 登录后延迟采集，等其它插件把按钮建好
local timer = CreateFrame("Frame")
local ticks = 0
timer:SetScript("OnUpdate", function()
    ticks = ticks + 1
    if ticks < 180 then return end
    timer:SetScript("OnUpdate", nil)
    pcall(Collect)
end)

SLASH_MINIMAPBAG1 = "/mmb"
SlashCmdList["MINIMAPBAG"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "open" then
        BuildBag() bag:Show() opened = true
    elseif msg == "close" then
        if bag then bag:Hide() end
        opened = false
    elseif msg == "rescan" then
        pcall(Restore)
        pcall(Collect)
        Msg("已重新扫描")
    elseif msg == "restore" then
        pcall(Restore)
        Msg("已还原所有按钮")
    else
        Msg("命令：/mmb open | close | rescan | restore")
    end
end