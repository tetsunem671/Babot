--// CORE SYSTEM (Logic Only)

local Core = {}

--// SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Network = require(ReplicatedStorage.Shared.Packages.Network)

--// DATA
local Tags = require(ReplicatedStorage.Shared.Data.Tags)
local EntitiesData = require(ReplicatedStorage.Shared.Data.EntitiesData)
local MutationData = require(ReplicatedStorage.Shared.Data.MutationData)
local InfiniteMath = require(ReplicatedStorage.Shared.Utility.InfiniteMath)

--// VFX
loadstring(game:HttpGet("https://raw.githubusercontent.com/tetsunem671/Babot/refs/heads/main/removeeffects.lua"))()

--==================================================
-- STATE
--==================================================
Core.Running = true
Core.Stopped = false

Core.AUTO_FARM = false
Core.AUTO_GIFT = false
Core.TARGET_NAME = ""

Core.FARM_THRESH = 1
Core.GIFT_MIN = 0
Core.GIFT_MAX = 1e10

Core.TRADE_LIMIT = 3
Core.tradedCount = 0
Core.lastTraded = "None"
Core.startTime = 0

Core.UPG_DELAY = 0.08
Core.LOOP_DELAY = 0.08
Core.GIFT_REQUEST_DELAY = 0.39

local MIN_SLOT, MAX_SLOT, MAX_LEVEL = 21, 21, 75

local CONFIG_FILE = "auto_farm_config.json"

local TRADELOCKED = {"Esok Sekolah"}

--==================================================
-- PLOT DETECTION
--==================================================
local Plot
for _, plot in pairs(workspace.Plots:GetChildren()) do
    local text = plot.Decorations.PlotOwner.OwnerGUI.TextLabel.Text
    if text == player.Name or text == player.DisplayName then
        Plot = plot
        break
    end
end

if not Plot then
    warn("Plot not found")
    return Core
end

local Slots = Plot.Slots

--==================================================
-- UTILS
--==================================================
function ToNumberV2(table)
    return table.first * (10 ^ table.second)
end

local function ue()
    local c,b = player.Character, player.Backpack
    if not c then return end
    for _,v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") then v.Parent = b end
    end
end

local function parse(s)
    if not s then return 0 end
    s = tostring(s):upper():gsub(",", ""):gsub("%s+", "")
    local num, suffix = s:match("([%d%.]+)([KMBT]?)")
    num = tonumber(num)
    if not num then return 0 end

    local mult = {K=1e3, M=1e6, B=1e9, T=1e12}
    return num * (mult[suffix] or 1)
end

Core.Parse = parse

local function tweenTo(cf)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (hrp.Position - cf.Position).Magnitude
    if dist <= 20 then return end

    local t = dist / 60

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(t, Enum.EasingStyle.Linear),
        {CFrame = cf}
    )

    tween:Play()
    tween.Completed:Wait()
end

Core.TweenTo = tweenTo

local function GetTrueCPS(tool)
    if not tool then return InfiniteMath.new(0) end

    local name = tool.Name
    local level = tool:GetAttribute("Level") or 1
    local mutation = tool:GetAttribute("Mutation")

    local data = EntitiesData.Brainrots[name]
    if not data or not data.CPS then
        return InfiniteMath.new(0)
    end

    local cps = InfiniteMath.new(data.CPS)

    -- mutation multiplier
    local mutationMulti = 1
    if mutation then
        local buff = MutationData.Buffs[mutation]
        if buff and buff.Value then
            mutationMulti = buff.Value
        end
    end

    cps = cps * InfiniteMath.new(mutationMulti)

    -- level multiplier
    local levelMulti = InfiniteMath.new(EntitiesData.GetMultiplierPerLevel(level))
    cps = cps * levelMulti

    local cps2 = ToNumberV2(cps)

    return cps2
end

local function slot(i)
    return Slots:FindFirstChild("Slot"..i)
end

local function fire(a,b)
    Network.FireServer(a,b)
end

--==================================================
-- FARM LOGIC
--==================================================
local function interactSlot(i)
    fire("S_Interact", i)

    return true
end

local function getUpgradePrompt(i)
    local s = slot(i)
    if not s then return end

    local placed = s:FindFirstChild("PlacedPart")
    if placed then
        return placed:FindFirstChildWhichIsA("ProximityPrompt", true)
    end
end

local function upgradePrompt(i)
    local prompt = getUpgradePrompt(i)
    if not prompt then return false end

    local part = prompt.Parent
    if not part then return false end

    tweenTo(part.CFrame)

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
    while Core.Running and Core.AUTO_FARM do
        local s = slot(i)
        local placed = s and s:FindFirstChild("PlacedPart")

        if not placed then
            task.wait(0.05)
        else
            local lvl = placed:GetAttribute("Level")
            if lvl and lvl >= MAX_LEVEL then break end

            fire("B_Upgrade", i)
            task.wait(Core.UPG_DELAY)
        end
    end
end

--==================================================
-- LOOPS
--==================================================
task.spawn(function()
    while Core.Running do
        if not Core.AUTO_FARM then task.wait(0.5) continue end

        task.wait(Core.LOOP_DELAY)

        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if not Core.AUTO_FARM then break end

            if tool:IsA("Tool") and ((tool:GetAttribute("Level") or 0) < 75) and tool:GetAttribute("GUID") then
                local value = GetTrueCPS(tool)
                local threshold = Core.FARM_THRESH

                if value and value > InfiniteMath.new(0) and value < threshold then
                    ue()
                    tool.Parent = player.Character
                    task.wait(0.2)
    
    
                    local i = getFreeSlot()
                    if i then
                        interactSlot(i)
                        repeat task.wait() until slot(i) and slot(i):FindFirstChild("PlacedPart")
                        upgradeFully(i)
                    end
                end
            end
        end
            
         _G.AutoFarmToggle:Set(false)
    end
end)

--==================================================
-- GIFT SYSTEM
--==================================================
local function getTarget()
    print(Core.TARGET_NAME)
    local name = tostring(Core.TARGET_NAME or ""):lower():gsub("%s+", "")
    local me = player

    -- explicit target
    if name ~= "" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= me and p.Name:lower() == name then
                return p
            end
        end
    end

    -- fallback: first valid OTHER player
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= me and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            return p
        end
    end

    return nil
end

local function tradeWith(target)
    print(target)
    local char = target.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local prompt = hrp:FindFirstChild("GiftPrompt") or hrp:WaitForChild("GiftPrompt", 2)
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
        and not table.find(EntitiesData.TradeLocked, tool.Name) and not table.find(TRADELOCKED, tool.Name)
end

task.spawn(function()
    while Core.Running do
        if not Core.AUTO_GIFT then task.wait(0.5) continue end

        local target = getTarget()
        if not target then task.wait(1) continue end
        if target == player then
            warn("[Gift] blocked self-trade attempt")
            continue
        end

        if Core.tradedCount >= Core.TRADE_LIMIT then task.wait(0.5) continue end

        for _, tool in ipairs(player.Backpack:GetChildren()) do
            if not Core.AUTO_GIFT then break end
            if Core.tradedCount >= Core.TRADE_LIMIT then task.wait(0.5) continue end
            
            local value = GetTrueCPS(tool)
            
            local min = Core.GIFT_MIN
            local max = Core.GIFT_MAX
            
            if value >= min and value <= max then
                if isGiftable(tool) then
                    ue()
                    tool.Parent = player.Character
                    task.wait(0.123)
    
                    print("[Gift Target Selected]:", target and target.Name or "NONE")
                    --tradeWith(target)
                    fire("GiftRequest", target.UserId)
                    repeat task.wait(0.5) until tool.Parent ~= player.Character
                    task.wait(Core.GIFT_REQUEST_DELAY)
                    Core.tradedCount += 1
                    Core.lastTraded = tool.Name
                end
            end
        end
        Core.tradedCount = 0
        _G.AutoGiftToggle:Set(false)
    end
end)

if Network.OnClientEvent then
    Network.OnClientEvent("SendGift"):Connect(function()
        fire("SendGift", true)
    end)
end

return Core
