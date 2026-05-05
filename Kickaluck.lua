--// SERVICES
local P = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local R = game:GetService("ReplicatedStorage")

local player = P.LocalPlayer
local Network = require(R.Shared.Packages.Network)

local CONFIG_FILE = "auto_farm_config.json"

--// DEPENDENCIES
local Tags = require(R.Shared.Data.Tags)
local EntitiesData = require(R.Shared.Data.EntitiesData)

--==================================================
-- SETTINGS
--==================================================
local MIN_SLOT, MAX_SLOT, MAX_LEVEL = 21, 21, 75


local FARM_THRESH = 1
local GIFT_MIN = 0
local GIFT_MAX = 1e10 -- default 10B

local AutoFarmToggle
local GiftToggle
local Indicator

local TRADE_LIMIT = 3
local tradedCount = 0
local lastTraded = "None"
local startTime = 0

local UPG_DELAY = 0.08
local LOOP_DELAY = 0.08
local GIFT_DELAY = 0.25

local AUTO_FARM = false
local AUTO_GIFT = false
local TARGET_NAME = ""

local function fixPrompt(prompt)
    if prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 0
    end
end

-- Apply to all existing prompts
for _, v in ipairs(workspace:GetDescendants()) do
    fixPrompt(v)
end

-- Apply to any new prompts added later
workspace.DescendantAdded:Connect(function(descendant)
    fixPrompt(descendant)
end)

local Config = {
    AUTO_GIFT = AUTO_GIFT,
    AUTO_FARM = AUTO_FARM,

    GIFT_MIN = GIFT_MIN,
    GIFT_MAX = GIFT_MAX,
    TRADE_LIMIT = TRADE_LIMIT,
    TARGET_NAME = TARGET_NAME,

    FARM_THRESH = FARM_THRESH,
    UPG_DELAY = UPG_DELAY,
    LOOP_DELAY = LOOP_DELAY
}

local Plots = workspace.Plots

local Plot
for _, plot in pairs(Plots:GetChildren()) do
    local text = plot.Decorations.PlotOwner.OwnerGUI.TextLabel.Text
    if text == player.Name or text == player.DisplayName then
        Plot = plot
        break
    end
end

if not Plot then
    warn("Plot not found")
    return
end

local Slots = Plot.Slots

local ignore_Name = {"Dragon Cannelloni", "Spaghetti Tualetti", "Esok Sekolah"}

--==================================================
-- CONTROLLER
--==================================================
local Controller = { Running = true }

--==================================================
-- STOP BUTTON
--==================================================
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "AutoControl"
gui.ResetOnSpawn = false

local button = Instance.new("TextButton", gui)
button.Size = UDim2.new(0,160,0,50)
button.Position = UDim2.new(0,20,0.5,0)
button.BackgroundColor3 = Color3.fromRGB(200,50,50)
button.TextColor3 = Color3.new(1,1,1)
button.Text = "STOP SCRIPT"

button.Activated:Connect(function()
    Controller.Running = false
    button.Text = "STOPPED"
    button.BackgroundColor3 = Color3.fromRGB(80,80,80)
end)

local function SaveConfig()
    Config.AUTO_GIFT = AUTO_GIFT
    Config.AUTO_FARM = AUTO_FARM
    Config.GIFT_MIN = GIFT_MIN
    Config.GIFT_MAX = GIFT_MAX
    Config.TRADE_LIMIT = TRADE_LIMIT
    Config.TARGET_NAME = TARGET_NAME
    Config.FARM_THRESH = FARM_THRESH
    Config.UPG_DELAY = UPG_DELAY
    Config.LOOP_DELAY = LOOP_DELAY

    if writefile then
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end
end

local function LoadConfig()
    if not readfile then return end
    if not isfile(CONFIG_FILE) then return end

    local data = HttpService:JSONDecode(readfile(CONFIG_FILE))

    AUTO_GIFT = data.AUTO_GIFT or AUTO_GIFT
    AUTO_FARM = data.AUTO_FARM or AUTO_FARM

    GIFT_MIN = data.GIFT_MIN or GIFT_MIN
    GIFT_MAX = data.GIFT_MAX or GIFT_MAX
    TRADE_LIMIT = data.TRADE_LIMIT or TRADE_LIMIT
    TARGET_NAME = data.TARGET_NAME or TARGET_NAME

    FARM_THRESH = data.FARM_THRESH or FARM_THRESH
    UPG_DELAY = data.UPG_DELAY or UPG_DELAY
    LOOP_DELAY = data.LOOP_DELAY or LOOP_DELAY
end

--==================================================
-- UTILS
--==================================================
local function isNear(cf)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    return (hrp.Position - cf.Position).Magnitude <= 20
end

local function randDelay(base)
    return base + (math.random() * base * 0.5)
end

local function tweenTo(cf)
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (hrp.Position - cf.Position).Magnitude
    if dist <= 20 then return end -- already close enough

    local t = dist / 60 -- speed factor (adjust if needed)

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = cf}
    )

    tween:Play()
    tween.Completed:Wait()
end

local function ue()
    local c,b = player.Character, player.Backpack
    if not c then return end
    for _,v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") then v.Parent = b end
    end
end

local function updateUI()
    local elapsed = startTime > 0 and math.floor(os.clock() - startTime) or 0

    Indicator:Set({
        Title = "Trade Stats",
        Content = string.format(
            "Traded: %d / %d\nLast: %s\nTime: %ds",
            tradedCount,
            TRADE_LIMIT,
            lastTraded,
            elapsed
        )
    })
end

local function parse(s)
    if not s then return 0 end
    s = tostring(s):upper():gsub(",", ""):gsub("%s+", "")
    local num,suffix = s:match("([%d%.]+)([KMBT]?)")
    num = tonumber(num)
    if not num then return 0 end

    local mult = {K=1e3,M=1e6,B=1e9,T=1e12}
    return num * (mult[suffix] or 1)
end

local function slot(i)
    return Slots:FindFirstChild("Slot"..i)
end

local function fire(a,b)
    Network.FireServer(a,b)
end

--==================================================
-- CPS
--==================================================
local function cps()
    local c = player.Character
    if not c then return 0 end

    for _,t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local m = t:FindFirstChildWhichIsA("Model")
            if m then
                local ok,v = pcall(function()
                    return m.Root.EntityGUI.Frame.CPSFrame.Label.Text
                end)
                if ok and v then return parse(v) end
            end
        end
    end
    return 0
end

--==================================================
-- SLOT / UPGRADE
--==================================================
local function getPromptFromSlot(i)
    local s = slot(i)
    if not s then return end

    return s:FindFirstChildWhichIsA("ProximityPrompt", true)
end


local function interactSlot(i)
    local s = slot(i)
    if not s then return end
    
    local prompt = getPromptFromSlot(i)
    if not prompt then return false end

    local part = s:WaitForChild("UpgradeSign")
    if not part then return false end

    tweenTo(part.CFrame)

    -- ensure instant trigger
    prompt.HoldDuration = 0

    -- safest built-in trigger
    prompt:InputHoldBegin()
    task.wait()
    prompt:InputHoldEnd()

    return true
end

local function getUpgradePrompt(i)
    local s = slot(i)
    if not s then return end

    local placed = s:FindFirstChild("PlacedPart")
    if placed then
        return placed:FindFirstChildWhichIsA("ProximityPrompt", true)
    end

    local attachment = s:FindFirstChild("Attachment")
    if attachment then
        return attachment:FindFirstChildWhichIsA("ProximityPrompt", true)
    end
end

local function upgradePrompt(i)
    local prompt = getUpgradePrompt(i)
    if not prompt then return false end

    local part = prompt.Parent
    if not part then return false end

    tweenTo(part.CFrame)

    prompt.HoldDuration = 0

    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(0.1)
        prompt:InputHoldEnd()
    end

    return true
end

local function getFreeSlot()
    for i = MIN_SLOT, MAX_SLOT do
        if slot(i) then return i end
    end
end

local function upgradeFully(i)
    while Controller.Running do
        if not AUTO_FARM then
            task.wait(0.5)
            break
        end
        local s = slot(i)
        local placed = s and s:FindFirstChild("PlacedPart")

        if not placed then
            task.wait(0.05)
        else
            local lvl = placed:GetAttribute("Level")
            if lvl and lvl >= MAX_LEVEL then break end

            upgradePrompt(i)
            task.wait(randDelay(UPG_DELAY))
        end
    end
end

--==================================================
-- AUTO PLACE + UPGRADE LOOP
--==================================================

task.spawn(function()
    while Controller.Running do
        if not AUTO_FARM then
            task.wait(0.5)
            continue
        end
        task.wait(randDelay(LOOP_DELAY))

        for _,tool in ipairs(player.Backpack:GetChildren()) do
            if not AUTO_FARM then
                task.wait(0.5)
                break
            end
            if not Controller.Running then break end

            if tool:IsA("Tool") and not table.find(ignore_Name, tool.Name) and tool:GetAttribute("Level") < 75 then
                ue()
                tool.Parent = player.Character
                task.wait(0.2)

                local value = cps()

                if value > 0 and value < FARM_THRESH then
                    local i = getFreeSlot()

                    if i then
                        interactSlot(i)

                        repeat task.wait() until slot(i)
                            and slot(i):FindFirstChild("PlacedPart")

                        task.wait(0.1)
                        upgradeFully(i)
                    end
                end
            end
        end
        AutoFarmToggle:Set(false)
    end
end)

--==================================================
-- GIFT SYSTEM
--==================================================
local function getTradePrompt(target)
    local char = target.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- wait for the injected prompt
    return hrp:FindFirstChild("GiftPrompt") 
        or hrp:WaitForChild("GiftPrompt", 2)
end

local function tradeWith(target)
    local prompt = getTradePrompt(target)
    if not prompt then return false end

    tweenTo(prompt.Parent.CFrame)

    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(0.1)
        prompt:InputHoldEnd()
    end

    return true
end

local function isGiftable(tool)
    return tool:IsA("Tool")
        and tool:HasTag(Tags.EntityTool)
        and not table.find(EntitiesData.TradeLocked, tool.Name)
end

local function getTarget()
    if TARGET_NAME ~= "" then
        for _,plr in ipairs(P:GetPlayers()) do
            if string.lower(plr.Name) == string.lower(TARGET_NAME) then
                return plr
            end
        end
        return nil
    end

    for _,plr in ipairs(P:GetPlayers()) do
        if plr ~= player then return plr end
    end
end

if Network.OnClientEvent then
    Network.OnClientEvent("SendGift"):Connect(function()
        fire("SendGift", true)
    end)
end

--==================================================
-- AUTO GIFT LOOP
--==================================================

task.spawn(function()
    while Controller.Running do
        if startTime == 0 then
            startTime = os.clock()
        end    
        if not AUTO_GIFT then
            task.wait(0.5)
            continue
        end

        local target = getTarget()
        if not target then
            task.wait(1)
            continue
        end

        if tradedCount >= TRADE_LIMIT then task.wait(0.5) continue end

        for _,tool in ipairs(player.Backpack:GetChildren()) do
            if not AUTO_GIFT then
                task.wait(0.5)
                break
            end
            if not Controller.Running then break end
            if tradedCount >= TRADE_LIMIT then break end

            if isGiftable(tool) and not table.find(ignore_Name, tool.Name) then
                ue()
                tool.Parent = player.Character
                task.wait(0.2)

                local value = cps()

                if value >= GIFT_MIN and value <= GIFT_MAX then     
                    task.wait(0.5 + math.random() * 0.5)
                    tradeWith(target)

                    repeat task.wait(GIFT_DELAY)
                    until tool.Parent ~= player.Character

                    tradedCount += 1
                    lastTraded = tool.Name
                    updateUI()
                end
            end
        end

        GiftToggle:Set(false)
        task.wait(0.2)
    end
end)

LoadConfig()

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Farm + Gift",
    LoadingTitle = "Initializing",
    LoadingSubtitle = "Control Panel"
})

--==================================================
-- MAIN TAB (GIFT)
--==================================================
local MainTab = Window:CreateTab("Auto Gift")

Indicator = MainTab:CreateParagraph({
    Title = "Trade Stats",
    Content = "Idle"
})

GiftToggle = MainTab:CreateToggle({
    Name = "Auto Gift",
    CurrentValue = AUTO_GIFT,
    Callback = function(v)
        AUTO_GIFT = v
    end
})
-- MIN
MainTab:CreateInput({
    Name = "Gift MIN (e.g. 1M)",
    PlaceholderText = "0",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        local v = parse(txt)
        if v >= 0 then
            GIFT_MIN = v
            print("Gift MIN:", GIFT_MIN)
        end
    end
})

-- MAX
MainTab:CreateInput({
    Name = "Gift MAX (e.g. 10B / 1T)",
    PlaceholderText = "10B",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        local v = parse(txt)
        if v > 0 then
            GIFT_MAX = v
            print("Gift MAX:", GIFT_MAX)
        end
    end
})

MainTab:CreateInput({
    Name = "Trade Limit",
    PlaceholderText = tostring(TRADE_LIMIT),
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        local n = tonumber(txt)
        if n and n > 0 then
            TRADE_LIMIT = math.floor(n)
            print("Trade Limit:", TRADE_LIMIT)
        end
    end
})

MainTab:CreateInput({
    Name = "Target Player",
    PlaceholderText = "username",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        TARGET_NAME = txt
        print("Target:", TARGET_NAME)
    end
})

--==================================================
-- AUTO FARM TAB
--==================================================
local FarmTab = Window:CreateTab("Auto Farm")

AutoFarmToggle = FarmTab:CreateToggle({
    Name = "Auto Farm (Place + Upgrade)",
    CurrentValue = AUTO_FARM,
    Callback = function(v)
        AUTO_FARM = v
    end
})

FarmTab:CreateInput({
    Name = "Farm Threshold (1M / 10B / 1T)",
    PlaceholderText = "10B",
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        local v = parse(txt)
        if v > 0 then
            FARM_THRESH = v
            print("Farm Threshold:", FARM_THRESH)
        end
    end
})

FarmTab:CreateInput({
    Name = "Upgrade Delay",
    PlaceholderText = tostring(UPG_DELAY),
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        local n = tonumber(txt)
        if n and n > 0 then
            UPG_DELAY = n
            print("Upgrade Delay:", UPG_DELAY)
        end
    end
})

FarmTab:CreateInput({
    Name = "Loop Delay",
    PlaceholderText = tostring(LOOP_DELAY),
    RemoveTextAfterFocusLost = false,
    Callback = function(txt)
        local n = tonumber(txt)
        if n and n > 0 then
            LOOP_DELAY = n
            print("Loop Delay:", LOOP_DELAY)
        end
    end
})


task.spawn(function()
    while Controller.Running do
        task.wait(5)
        SaveConfig()
    end
end)

task.spawn(function()
    while Controller.Running do
        if Core.AUTO_GIFT then
            updateUI()
        end
        task.wait(0.5)
    end
end)

