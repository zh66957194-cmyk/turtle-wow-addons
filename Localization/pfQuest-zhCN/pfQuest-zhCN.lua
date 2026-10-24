-- 把这段追加到 pfQuest\locales.lua 文件末尾
-- 注意：pfQuest_Loc 带 __index 元表，读任何键都会返回键名，必须用 rawset 覆盖
if GetLocale and GetLocale() == "zhCN" and pfQuest_Loc then
    local zh = {
        ["Database"] = "数据库",
        ["Chests & Treasures"] = "宝箱与宝藏",
        ["Herbs & Flowers"] = "草药与花",
        ["Mines & Ores"] = "矿脉与矿石",
        ["Fishing Pools"] = "鱼群",
        ["Rare Mobs"] = "稀有怪物",
        ["Auctioneer"] = "拍卖师",
        ["Banker"] = "银行家",
        ["Battlemaster"] = "战场指挥官",
        ["Flight Master"] = "飞行管理员",
        ["Innkeeper"] = "旅店老板",
        ["Mailbox"] = "邮箱",
        ["Meeting Stones"] = "集合石",
        ["Repair"] = "修理",
        ["Spirit Healer"] = "灵魂医者",
        ["Stable Master"] = "兽栏管理员",
        ["Quest Journal"] = "任务日志",
        ["Welcome Screen"] = "欢迎界面",
        ["Settings"] = "设置",
        ["Merchant"] = "商人",
        ["Trainer"] = "训练师",
        ["Quest"] = "任务",
        ["Items"] = "物品",
        ["Units"] = "单位",
        ["Objects"] = "物件",
        ["Zones"] = "区域",
    }
    local k, v
    for k, v in pairs(zh) do
        rawset(pfQuest_Loc, k, v)
    end
end