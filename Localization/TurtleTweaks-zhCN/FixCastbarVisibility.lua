local feature = ns.Register({
  identifier = "FixCastbarVisibility",
  description = "修复施法结束后施法条仍然显示的 bug。",
  category = "utility",
  config = {}
})

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("SPELLCAST_FAILED")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_INTERRUPTED")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

frame:SetScript("OnEvent", function()
  if not ns.IsEnabled(feature.identifier) then return end

  -- TODO: Find which event is needed to fix this mess.
  CastingBarFrame:Hide()
end)
