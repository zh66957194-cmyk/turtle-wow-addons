local config = {
  loaded = false,
  yOffset = 0, -- Starting offset.
  title = "Turtle Tweaks",
  width = 600,
  height = 500,
  categories = {
    interface = { label = "界面", items = {} },
    utility = { label = "实用工具", items = {} },
    social = { label = "社交与聊天", items = {} },
    automation = { label = "自动化", items = {} },
    profession = { label = "专业", items = {} },
  }
}

-- 中文客户端需要显式指定中文字体，否则中文会显示成方块
local CJK_FONT = "Fonts\\FZLBJW.TTF"
local function ApplyCJK(fontString)
  if not fontString then return end
  if GetLocale and GetLocale() ~= "zhCN" then return end
  local font, size = fontString:GetFont()
  if font then
    fontString:SetFont(CJK_FONT, size, "")
  end
end

local frame = CreateFrame("FRAME", nil, UIParent)

frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and not config.loaded then
    frame:EnableMouse(true)
    frame:Hide()

    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetWidth(config.width)
    frame:SetHeight(config.height)
    frame:SetFrameStrata("HIGH")

    -- Create a backdrop for our addon.
    frame:SetBackdrop({
      bgFile = "Interface\\AddOns\\TurtleTweaks\\UI\\BG",
      edgeFile = "Interface\\AddOns\\TurtleTweaks\\UI\\Border",
      tile = true,
      tileSize = 128,
      edgeSize = 32,
      insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })

    -- Create a font string for the title.
    frame.title = frame:CreateFontString(nil, "HIGH", "GameFontNormal")
    frame.title:SetText("Turtle Tweaks")
    ApplyCJK(frame.title)
    frame.title:SetPoint("TOP", 0, -5)

    -- Create a close button.
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 3, 4)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- Create scrollable frame.
    frame.scrollFrame = CreateFrame("ScrollFrame", "TurtleTweaksSettings", frame, "UIPanelScrollFrameTemplate")
    frame.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -26)
    frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 42)

    local child = CreateFrame("Frame", nil, frame.scrollFrame)
    child:SetWidth(frame:GetWidth())
    child:SetHeight(frame:GetHeight() - 100)
    frame.scrollFrame:SetScrollChild(child)
    
    -- Move features to categories.
    for _, item in ipairs(ns.Features) do
      tinsert(config.categories[item.category].items, item)
    end

    -- Render categories and options.
    local yOffset = config.yOffset
    -- 固定分类顺序（pairs 的顺序是随机的）
    local categoryOrder = { "interface", "utility", "social", "automation", "profession" }
    for idx = 1, table.getn(categoryOrder) do
      local name = categoryOrder[idx]
      local data = config.categories[name]
      if data then
      yOffset = yOffset + 10

      local title = child:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
      title:SetPoint("TOPLEFT", 20, -yOffset)
      title:SetText(data.label)
      ApplyCJK(title)
      yOffset = yOffset + 20

      for _, item in ipairs(data.items) do
        local checkbox = CreateFrame("CheckButton", nil, child, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 30, -yOffset)
        checkbox.identifier = item.identifier
      
        if TurtleTweaksDB[item.identifier] ~= nil then
          checkbox:SetChecked(TurtleTweaksDB[item.identifier])
        end

        local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 1)
        label:SetText(item.description)
        ApplyCJK(label)
        
        checkbox:SetScript("OnClick", function(self)
          local checked = checkbox:GetChecked()
          if checked then
            TurtleTweaksDB[checkbox.identifier] = true
          else
            TurtleTweaksDB[checkbox.identifier] = false
          end
        end)

        yOffset = yOffset + 30
      end
      end
    end

    local apply = CreateFrame("Button", "TurtleTweaksApply", frame, "UIPanelButtonTemplate")
    apply:SetPoint("BOTTOMRIGHT", -12, 12)
    apply:SetWidth(70)
    apply:SetHeight(22)
    apply:SetText("应用")
    ApplyCJK(getglobal("TurtleTweaksApplyText"))
    apply:SetScript("OnClick", function(self)
      ReloadUI()
    end)

    local cancel = CreateFrame("Button", "TurtleTweaksCancel", frame, "UIPanelButtonTemplate")
    cancel:SetPoint("BOTTOMRIGHT", -90, 12)
    cancel:SetWidth(70)
    cancel:SetHeight(22)
    cancel:SetText("取消")
    ApplyCJK(getglobal("TurtleTweaksCancelText"))
    cancel:SetScript("OnClick", function(self)
      frame:Hide()
    end)

    -- Add a button to the game menu that opens our addon frame when clicked.
    local mainMenuButton = CreateFrame("Button", nil, GameMenuFrame, "GameMenuButtonTemplate")
    mainMenuButton:SetPoint("TOP", GameMenuButtonUIOptions, "BOTTOM", 0, -20)
    mainMenuButton:SetText("Turtle Tweaks")
    if mainMenuButton.GetFontString then
      ApplyCJK(mainMenuButton:GetFontString())
    end
    mainMenuButton:SetScript("OnClick", function()
      HideUIPanel(GameMenuFrame)
      frame:Show()
    end)

    -- Add a button to the game menu that opens our addon frame when clicked.
    GameMenuButtonKeybindings:ClearAllPoints()
    GameMenuButtonKeybindings:SetPoint("TOP", mainMenuButton, "BOTTOM", 0, -1)
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 30)
    
    do
      SLASH_TT1 = "/tt"
      SlashCmdList["TT"] = function(msg, editbox)
        if frame:IsVisible() then
          frame:Hide()
        else
          frame:Show()
        end
      end
    end
    
    config.loaded = true
  end
end)
