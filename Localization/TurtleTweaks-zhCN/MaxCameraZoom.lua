local feature = ns.Register({
  identifier = "MaxCameraZoom",
  description = "增大镜头的最大缩放距离。",
  category = "utility",
  config = {}
})

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function()
  if not ns.IsEnabled(feature.identifier) then
    -- Reset to default game values.
    SlashCmdList["CONSOLE"]("cameraDistanceMax 15")
    SlashCmdList["CONSOLE"]("cameraDistanceMaxFactor 1.9")
    SlashCmdList["CONSOLE"]("cameraDistanceMoveSpeed 8.33")
    SlashCmdList["CONSOLE"]("cameraDistanceSmoothSpeed 8.33")
    return
  end

  SlashCmdList["CONSOLE"]("cameraDistanceMax 50")
  SlashCmdList["CONSOLE"]("cameraDistanceMaxFactor 5")
  SlashCmdList["CONSOLE"]("cameraDistanceMoveSpeed 50")
  SlashCmdList["CONSOLE"]("cameraDistanceSmoothSpeed 1")
end)
