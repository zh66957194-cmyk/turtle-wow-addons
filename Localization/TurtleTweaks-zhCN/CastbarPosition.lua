local feature = ns.Register({
  identifier = "CastbarPosition",
  description = "把施法条的位置向上移。",
  category = "interface",
  config = {}
})

local frame = CreateFrame("Frame")

frame:RegisterAllEvents()

frame:SetScript("OnEvent", function()
  if not ns.IsEnabled(feature.identifier) then return end

  CastingBarFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 270)  
end)
