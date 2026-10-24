local feature = ns.Register({
  identifier = "ManaEnergyTick",
  description = "用法力/能量刻度条显示回复节奏。",
  category = "interface",
  config = {}
})

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function()
  if not ns.IsEnabled(feature.identifier) then return end

  print("Mana and energy tick")
end)
