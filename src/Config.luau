local C = { MaxSpeed = 32, BoostSpeed = 40, Acceleration = 16, Braking = 24, LateralSpeed = 17 }
C.Styles = {
    "霓虹骑士",
    "星际信使",
    "幻影忍者",
    "赛博机甲",
    "极光翼装",
    "熔岩先锋",
    "寒霜疾影",
    "黄金冠军",
}
C.Palettes = { Color3.fromRGB(47, 225, 255), Color3.fromRGB(230, 85, 255), Color3.fromRGB(255, 186, 55) }
C.Skins = {
    Color3.fromRGB(18, 23, 35),
    Color3.fromRGB(220, 226, 235),
    Color3.fromRGB(54, 91, 150),
    Color3.fromRGB(132, 63, 165),
    Color3.fromRGB(48, 145, 120),
    Color3.fromRGB(183, 72, 51),
    Color3.fromRGB(194, 151, 89),
    Color3.fromRGB(91, 99, 116),
}
C.SkinNames = { "曜石", "银白", "深蓝", "幻紫", "翡翠", "赤焰", "流金", "钛灰" }
C.Items = {
    Boost = "涡轮冲刺",
    Shield = "能量护盾",
    Rocket = "追踪飞弹",
    Leader = "领跑锁定",
    EMP = "电磁脉冲",
    Trap = "减速力场",
    Magnet = "牵引加速",
    Steal = "道具夺取",
}
C.ItemHelp = {
    Boost = "4秒加速，最高40",
    Shield = "6秒护盾，抵挡一次攻击",
    Rocket = "追踪前方最近对手，预警后命中",
    Leader = "锁定第一名，落后越远越易获得",
    EMP = "干扰附近18米内对手",
    Trap = "在身后留下可见减速力场",
    Magnet = "距前方对手越远，加速越久",
    Steal = "夺取前方对手道具；可被护盾挡住",
}
C.Items.Cleanse = "净化脉冲"
C.Items.Decoy = "全息诱饵"
C.Items.Spring = "弹跳踏板"
C.Items.Vacuum = "磁力拾取"
C.Items.Smoke = "烟幕云"
C.Items.Shockwave = "震荡波"
C.ItemHelp.Cleanse = "解除减速并获得3秒保护"
C.ItemHelp.Decoy = "8秒内拦截一次追踪攻击"
C.ItemHelp.Spring = "身后放置弹跳板，踩中获得跃升"
C.ItemHelp.Vacuum = "6秒内扩大拾取范围至16米"
C.ItemHelp.Smoke = "留下短暂烟幕，遮挡身后视线"
C.ItemHelp.Shockwave = "震退10米内对手，可用护盾抵挡"
function C.OutfitName(i)
    C.Rules = require(script.Parent:WaitForChild("SharedModules"):WaitForChild("Rules"))
    return C.Styles[(i - 1) % 8 + 1]
        .. " · "
        .. ({ "冰蓝", "幻紫", "流金" })[math.floor((i - 1) / 8) + 1]
end
C.Rules = require(script.Parent:WaitForChild("SharedModules"):WaitForChild("Rules"))
return C
