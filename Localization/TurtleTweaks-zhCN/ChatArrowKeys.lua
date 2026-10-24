local feature = ns.Register({
  identifier = "ChatArrowKeys",
  description = "在聊天框里使用方向键移动光标。",
  category = "social",
  config = {}
})

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function()
  if not ns.IsEnabled(feature.identifier) then return end
  ChatFrameEditBox:SetAltArrowKeyMode(false);
end)
