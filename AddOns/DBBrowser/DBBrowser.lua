-- ============================================================
-- DBBrowser —— 乌龟服游戏内数据库查询（1.12 / Lua 5.0）
-- /db 打开或关闭面板
-- 数据来自 twptr_world：物品 20700 / 任务 5875 / 生物 12513
-- ============================================================

local ROWS = 14
local MAX_RESULTS = 3000
local FONT = "Fonts\\ARKai_T.ttf"

local QUALITY_RGB = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 1.00, 1.00, 1.00 },
    [2] = { 0.12, 1.00, 0.00 },
    [3] = { 0.00, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1.00, 0.50, 0.00 },
    [6] = { 0.90, 0.80, 0.50 },
}

local db_items = { ids = {}, names = {}, zh = {}, lines = {} }
local db_quests = { ids = {}, names = {}, zh = {}, lines = {} }
local db_creatures = { ids = {}, names = {}, zh = {}, lines = {} }

local current = db_items
local current_type = "item"
local results = {}
local page = 1
local total_pages = 1
local keyword = ""

-- ---------- 解析导出的数据 ----------

local function SplitFields(line)
    local fields = {}
    local p = 1
    while true do
        local sep = string.find(line, "|", p, true)
        if not sep then
            table.insert(fields, string.sub(line, p))
            break
        end
        table.insert(fields, string.sub(line, p, sep - 1))
        p = sep + 1
    end
    return fields
end

local function ParseRecords(data, dest)
    if not data then return end
    local pos = 1
    local len = string.len(data)
    while pos <= len do
        local e = string.find(data, "\n", pos, true)
        if not e then e = len + 1 end
        local line = string.sub(data, pos, e - 1)
        if string.len(line) > 0 then
            local f1 = string.find(line, "|", 1, true)
            if f1 then
                local id = tonumber(string.sub(line, 1, f1 - 1))
                local f2 = string.find(line, "|", f1 + 1, true)
                local nm
                if f2 then
                    nm = string.sub(line, f1 + 1, f2 - 1)
                else
                    nm = string.sub(line, f1 + 1)
                end
                if id then
                    local zh_name = ""
                    local f = SplitFields(line)
                    if f[6] and string.len(f[6]) > 0 then
                        zh_name = f[6]
                    end
                    table.insert(dest.ids, id)
                    table.insert(dest.names, string.lower(nm or ""))
                    table.insert(dest.zh, zh_name)
                    table.insert(dest.lines, line)
                end
            end
        end
        pos = e + 1
    end
end

-- ---------- 界面 ----------

local frame
local editbox
local rows = {}
local status_text
local type_buttons = {}

local function SetType(t)
    if t == "item" then
        current = db_items
        current_type = "item"
    elseif t == "quest" then
        current = db_quests
        current_type = "quest"
    else
        current = db_creatures
        current_type = "creature"
    end
    for k, b in pairs(type_buttons) do
        if b.setText then
            if k == current_type then
                b.setText:SetTextColor(1, 0.82, 0.25)
            else
                b.setText:SetTextColor(0.75, 0.75, 0.75)
            end
        end
    end
end

local function ShowPage()
    local count = table.getn(results)
    if count == 0 then
        total_pages = 1
    else
        total_pages = math.floor((count - 1) / ROWS) + 1
    end
    if page < 1 then page = 1 end
    if page > total_pages then page = total_pages end

    for i = 1, ROWS do
        local row = rows[i]
        local idx = (page - 1) * ROWS + i
        if idx <= count then
            local real_idx = results[idx]
            local line = current.lines[real_idx]
            local f = SplitFields(line)
            local disp = f[2]
            if f[6] and string.len(f[6]) > 0 then
                disp = f[6]
            end

            if current_type == "item" then
                local quality = tonumber(f[3]) or 1
                local rgb = QUALITY_RGB[quality] or QUALITY_RGB[1]
                row.text:SetTextColor(rgb[1], rgb[2], rgb[3])
                row.text:SetText(f[1] .. "  " .. disp)
                row.extra:SetText("等级 " .. (f[4] or "?") .. "  需 " .. (f[5] or "?"))
            elseif current_type == "quest" then
                row.text:SetTextColor(1, 0.82, 0.25)
                row.text:SetText(f[1] .. "  " .. disp)
                row.extra:SetText("任务等级 " .. (f[3] or "?"))
            else
                row.text:SetTextColor(0.85, 0.85, 0.85)
                row.text:SetText(f[1] .. "  " .. disp)
                row.extra:SetText("等级 " .. (f[3] or "?") .. "-" .. (f[4] or "?"))
            end
            row.text:Show()
            row.extra:Show()
        else
            row.text:Hide()
            row.extra:Hide()
        end
    end

    status_text:SetText("共 " .. count .. " 条   第 " .. page .. " / " .. total_pages .. " 页")
end

local function DoSearch()
    local kw = string.lower(editbox:GetText() or "")
    keyword = kw
    results = {}
    page = 1

    if string.len(kw) == 0 then
        ShowPage()
        return
    end

    local n = table.getn(current.ids)
    local is_num = tonumber(kw)
    local kw_raw = editbox:GetText() or ""
    for i = 1, n do
        local hit = false
        if is_num and current.ids[i] == is_num then
            hit = true
        elseif string.find(current.names[i], kw, 1, true) then
            hit = true
        elseif string.len(current.zh[i]) > 0 and string.find(current.zh[i], kw_raw, 1, true) then
            hit = true
        end
        if hit then
            table.insert(results, i)
            if table.getn(results) >= MAX_RESULTS then
                break
            end
        end
    end

    ShowPage()
end

local function MakeButton(parent, text, w, h, x, y, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w)
    b:SetHeight(h)
    b:SetPoint("TOPLEFT", x, y)
    b:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    b:SetBackdropColor(0.12, 0.12, 0.14, 0.9)
    b:SetBackdropBorderColor(0.4, 0.35, 0.2, 1)
    local label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", 0, 0)
    label:SetText(text)
    label:SetTextColor(0.85, 0.85, 0.85)
    b.setText = label
    b:SetScript("OnClick", function()
        onClick()
    end)
    return b
end

local function CreatePanel()
    frame = CreateFrame("Frame", "DBBrowserFrame", UIParent)
    frame:SetWidth(420)
    frame:SetHeight(470)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
    frame:SetBackdropBorderColor(0.55, 0.45, 0.2, 1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
    frame:Hide()
    frame:SetScript("OnHide", function()
        if editbox then editbox:ClearFocus() end
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("乌龟服数据库")
    title:SetTextColor(1, 0.82, 0.25)

    local close = MakeButton(frame, "X", 22, 22, 386, -8, function()
        frame:Hide()
    end)

    type_buttons.item = MakeButton(frame, "物品", 60, 22, 14, -38, function()
        SetType("item")
        DoSearch()
    end)
    type_buttons.quest = MakeButton(frame, "任务", 60, 22, 80, -38, function()
        SetType("quest")
        DoSearch()
    end)
    type_buttons.creature = MakeButton(frame, "生物", 60, 22, 146, -38, function()
        SetType("creature")
        DoSearch()
    end)

    editbox = CreateFrame("EditBox", "DBBrowserEditBox", frame)
    editbox:SetWidth(240)
    editbox:SetHeight(22)
    editbox:SetPoint("TOPLEFT", 14, -70)
    editbox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    editbox:SetBackdropColor(0.1, 0.1, 0.12, 1)
    editbox:SetFontObject(GameFontNormal)
    editbox:SetMaxLetters(40)
    editbox:SetScript("OnEnterPressed", function()
        DoSearch()
    end)
    editbox:SetScript("OnEscapePressed", function()
        editbox:ClearFocus()
        frame:Hide()
    end)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetPoint("TOPLEFT", 14, -94)
    hint:SetText("输入中文名 / 英文名 / 数字 ID，回车搜索")
    hint:SetTextColor(0.55, 0.55, 0.55)

    local search_btn = MakeButton(frame, "搜索", 70, 22, 262, -70, function()
        DoSearch()
    end)

    for i = 1, ROWS do
        local row = {}
        row.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("TOPLEFT", 16, -112 - (i - 1) * 20)
        row.text:SetJustifyH("LEFT")
        row.text:SetWidth(290)
        row.extra = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.extra:SetPoint("TOPRIGHT", -16, -112 - (i - 1) * 20)
        row.extra:SetJustifyH("RIGHT")
        row.extra:SetTextColor(0.6, 0.6, 0.6)
        row.text:Hide()
        row.extra:Hide()
        rows[i] = row
    end

    local prev = MakeButton(frame, "上一页", 70, 22, 14, -412, function()
        if page > 1 then
            page = page - 1
            ShowPage()
        end
    end)
    local nextb = MakeButton(frame, "下一页", 70, 22, 92, -412, function()
        if page < total_pages then
            page = page + 1
            ShowPage()
        end
    end)

    status_text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    status_text:SetPoint("TOPLEFT", 180, -417)
    status_text:SetTextColor(0.7, 0.7, 0.7)
    status_text:SetText("")
end

-- ---------- 初始化 ----------

local init = CreateFrame("Frame", "DBBrowserEvents", UIParent)
init:RegisterEvent("VARIABLES_LOADED")

init:SetScript("OnEvent", function()
    if event ~= "VARIABLES_LOADED" then return end
    ParseRecords(DB_ITEMS, db_items)
    ParseRecords(DB_QUESTS, db_quests)
    ParseRecords(DB_CREATURES, db_creatures)
    CreatePanel()
    SetType("item")
    DEFAULT_CHAT_FRAME:AddMessage("|cffa050ffDBBrowser|r 已加载：" ..
        table.getn(db_items.ids) .. " 物品 / " ..
        table.getn(db_quests.ids) .. " 任务 / " ..
        table.getn(db_creatures.ids) .. " 生物    输入 |cffffff00/db|r 打开")
end)

-- 注意：pfQuest 也用 /db，会覆盖本插件的注册（游戏内表现为 DBBrowser 失效）
SLASH_DBBROWSER1 = "/wdb"
SLASH_DBBROWSER2 = "/dbrowser"
SlashCmdList["DBBROWSER"] = function()
    if not frame then return end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        editbox:SetFocus()
    end
end
