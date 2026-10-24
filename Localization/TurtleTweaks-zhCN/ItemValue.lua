local feature = ns.Register({
  identifier = "ItemValue",
  description = "在鼠标提示里显示物品的商人售价。",
  category = "interface",
  config = {},
})

local frame = CreateFrame("Frame", nil, GameTooltip)

local function ShowCompare(tooltip)
  -- abort if shift is not pressed
  -- if not IsShiftKeyDown() then
    -- ShoppingTooltip1:Hide()
    -- ShoppingTooltip2:Hide()
    -- return
  -- end

  print(tooltip)

  -- for i=1,tooltip:NumLines() do
  --   local tmpText = _G[tooltip:GetName() .. "TextLeft"..i]

  --   for slotType, slotName in pairs(slots) do
  --     if tmpText:GetText() == slotType then
  --       local slotID = GetInventorySlotInfo(slotName)
  --       print("SLOTID:" .. slotID)
  --     end
  --   end
  -- end
end

frame:SetScript("OnUpdate", function()
  if not ns.IsEnabled(feature.identifier) then return end
  -- ShowCompare(GameTooltip)
end)
