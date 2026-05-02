local Players = game:GetService("Players")
local player = Players.LocalPlayer

--// CORE (FROM GITHUB)
_G.AutoGiftToggle = nil
_G.AutoFarmToggle = nil

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

_G.Indicator = GiftTab:CreateParagraph({
    Title = "Trade Stats",
    Content = "Idle"
})

_G.AutoGiftToggle = GiftTab:CreateToggle({
    Name = "Auto Gift",
    CurrentValue = Core.AUTO_GIFT,
    Callback = function(v)
        Core.AUTO_GIFT = v
    end
})

GiftTab:CreateInput({
    Name = "Gift MIN (e.g. 1M)",
    PlaceholderText = tostring(Core.GIFT_MIN or ""),
    CurrentValue = tostring(Core.GIFT_MIN or ""),
    Callback = function(txt)
        Core.GIFT_MIN = Core.Parse(txt)
    end
})

GiftTab:CreateInput({
    Name = "Gift MAX (e.g. 10B)",
    PlaceholderText = tostring(Core.GIFT_MAX or ""),
    CurrentValue = tostring(Core.GIFT_MAX or ""),
    Callback = function(txt)
        Core.GIFT_MAX = Core.Parse(txt)
    end
})

GiftTab:CreateInput({
    Name = "Trade Limit",
    PlaceholderText = tostring(Core.TRADE_LIMIT),
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        local n = tonumber(txt)
        if n and n > 0 then
            Core.TRADE_LIMIT = math.floor(n)
            print("Trade Limit:", Core.TRADE_LIMIT)
        end
    end
})

GiftTab:CreateInput({
    Name = "Target Player",
    PlaceholderText = tostring(Core.TARGET_NAME or ""),
    CurrentValue = Core.TARGET_NAME or "",
    Callback = function(txt)
        Core.TARGET_NAME = txt
    end
})
--==================================================
-- FARM TAB
--==================================================
local FarmTab = Window:CreateTab("Auto Farm")

_G.AutoFarmToggle = FarmTab:CreateToggle({
    Name = "Auto Farm (Place + Upgrade)",
    CurrentValue = Core.AUTO_FARM,
    Callback = function(v)
        Core.AUTO_FARM = v
    end
})

FarmTab:CreateInput({
    Name = "Farm Threshold",
    PlaceholderText = tostring(Core.FARM_THRESH or ""),
    CurrentValue = tostring(Core.FARM_THRESH or ""),
    Callback = function(txt)
        Core.FARM_THRESH = Core.Parse(txt)
    end
})

FarmTab:CreateInput({
    Name = "Upgrade Delay",
    PlaceholderText = tostring(Core.UPG_DELAY or ""),
    CurrentValue = tostring(Core.UPG_DELAY or ""),
    Callback = function(txt)
        Core.UPG_DELAY = tonumber(txt) or Core.UPG_DELAY
    end
})

FarmTab:CreateInput({
    Name = "Loop Delay",
    PlaceholderText = tostring(Core.LOOP_DELAY or ""),
    CurrentValue = tostring(Core.LOOP_DELAY or ""),
    Callback = function(txt)
        Core.LOOP_DELAY = tonumber(txt) or Core.LOOP_DELAY
    end
})

function Core.Stop()
    if Core.Stopped then return end
    Core.Stopped = true

    Core.Running = false
    Core.AUTO_FARM = false
    Core.AUTO_GIFT = false

    print("[Core] Stopping all systems...")

    -- kill VFX loop if it exists
    if _G.__VFX_STOP then
        _G.__VFX_STOP()
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "STOP_GUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 160, 0, 50)
button.Position = UDim2.new(0, 20, 0.5, 0)
button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
button.TextColor3 = Color3.new(1,1,1)
button.Text = "STOP SCRIPT"
button.Parent = gui

button.MouseButton1Click:Connect(function()
    Stop()
    button.Text = "STOPPED"
    button.BackgroundColor3 = Color3.fromRGB(70,70,70)
end)

--==================================================
-- STATS UI LOOP
--==================================================
task.spawn(function()
    while task.wait(0.5) do
        if _G.Indicator then
            _G.Indicator:Set({
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
