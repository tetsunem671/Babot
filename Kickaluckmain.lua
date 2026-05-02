--// CORE (FROM GITHUB)
local Core = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/tetsunem671/Babot/refs/heads/main/Core.lua"
))()

--// UI LIB
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Farm + Gift",
    LoadingTitle = "Initializing",
    LoadingSubtitle = "Control Panel"
})

--==================================================
-- GIFT TAB
--==================================================
local GiftTab = Window:CreateTab("Auto Gift")

local Indicator = GiftTab:CreateParagraph({
    Title = "Trade Stats",
    Content = "Idle"
})

GiftTab:CreateToggle({
    Name = "Auto Gift",
    CurrentValue = Core.AUTO_GIFT,
    Callback = function(v)
        Core.AUTO_GIFT = v
    end
})

GiftTab:CreateInput({
    Name = "Gift MIN (e.g. 1M)",
    CurrentValue = Core.GIFT_MIN,
    Callback = function(txt)
        Core.GIFT_MIN = Core.Parse(txt)
    end
})

GiftTab:CreateInput({
    Name = "Gift MAX (e.g. 10B)",
    CurrentValue = Core.GIFT_MAX,
    Callback = function(txt)
        Core.GIFT_MAX = Core.Parse(txt)
    end
})

GiftTab:CreateInput({
    Name = "Target Player",
    CurrentValue = "",
    Callback = function(txt)
        Core.TARGET_NAME = txt
    end
})

--==================================================
-- FARM TAB
--==================================================
local FarmTab = Window:CreateTab("Auto Farm")

FarmTab:CreateToggle({
    Name = "Auto Farm (Place + Upgrade)",
    CurrentValue = Core.AUTO_FARM,
    Callback = function(v)
        Core.AUTO_FARM = v
    end
})

FarmTab:CreateInput({
    Name = "Farm Threshold",
    CurrentValue = Core.FARM_THRESH,
    Callback = function(txt)
        Core.FARM_THRESH = Core.Parse(txt)
    end
})

FarmTab:CreateInput({
    Name = "Upgrade Delay",
    CurrentValue = Core.UPG_DELAY,
    Callback = function(txt)
        Core.UPG_DELAY = tonumber(txt) or Core.UPG_DELAY
    end
})

FarmTab:CreateInput({
    Name = "Loop Delay",
    CurrentValue = Core.LOOP_DELAY,
    Callback = function(txt)
        Core.LOOP_DELAY = tonumber(txt) or Core.LOOP_DELAY
    end
})

--==================================================
-- STATS UI LOOP
--==================================================
task.spawn(function()
    while task.wait(0.5) do
        if Indicator then
            Indicator:Set({
                Title = "Trade Stats",
                Content = string.format(
                    "Traded: %d / %d\nLast: %s\nTime: %ds",
                    Core.tradedCount,
                    Core.TRADE_LIMIT,
                    Core.lastTraded,
                    Core.startTime > 0 and math.floor(os.clock() - Core.startTime) or 0
                )
            })
        end
    end
end)
