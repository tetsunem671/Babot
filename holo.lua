--// =========================
--// SERVICES
--// =========================
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local BreakablesClass = require(ReplicatedStorage.Shared.Classes.BreakablesClass)

--// =========================
--// CONFIG / STATE
--// =========================
local CONFIG = getgenv().CONFIG or {}

local STATE = {
    Enabled = CONFIG.Default or false,
    SelectedPos = nil,

    HopEnabled = CONFIG.Serverhop and CONFIG.Serverhop.Enabled or false,
    HopTime = CONFIG.Serverhop and CONFIG.Serverhop.Time or 3600,
    HopStart = tick()
}

local POSITIONS = {
    ["Position 1"] = Vector3.new(203.75, 398.77, 138.81),
    ["Position 2"] = Vector3.new(-2199.80, 719.17, 2377.03)
}

--// =========================
--// METHODS (CORE LOGIC)
--// =========================
local METHODS = {}

function METHODS.GetCharacter()
    return player.Character
end

function METHODS.GetHRP()
    local char = METHODS.GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function METHODS.GetHumanoid()
    local char = METHODS.GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function METHODS.TweenTo(position)
    local hrp = METHODS.GetHRP()
    if not hrp then return end

    local distance = (hrp.Position - position).Magnitude
    local speed = 50

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position + Vector3.new(0,3,0))}
    )

    tween:Play()
    tween.Completed:Wait()
end

function METHODS.WalkTo(position)
    local humanoid = METHODS.GetHumanoid()
    if humanoid then
        humanoid:MoveTo(position)
    end
end

function METHODS.GetNearestBreakable(hrp)
    local list = BreakablesClass.GetNearby(hrp.Position, 100)

    table.sort(list, function(a,b)
        return (a.position - hrp.Position).Magnitude <
               (b.position - hrp.Position).Magnitude
    end)

    for _,obj in ipairs(list) do
        if obj and not obj.isBroken and not obj.isDestroyed and obj.hp > 0 then
            return obj
        end
    end
end

function METHODS.ServerHop()
    pcall(function()
        local Knit = require(ReplicatedStorage.Packages.knit)
        local svc = Knit.GetService("AutoReconnectService")
        if svc then
            svc.RequestReconnect:Fire()
        end
    end)
end

--// =========================
--// RAYFIELD UI
--// =========================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Auto Break",
    LoadingTitle = "Auto Farm",
    LoadingSubtitle = "by you",
    ConfigurationSaving = {Enabled = false}
})

local MainTab = Window:CreateTab("Main", 4483362458)

--// POSITION SELECTOR
MainTab:CreateDropdown({
    Name = "Select Position",
    Options = {"Position 1", "Position 2"},
    CurrentOption = "Position 1",
    Callback = function(option)
        STATE.SelectedPos = POSITIONS[option]
    end
})

--// ENABLE TOGGLE
MainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = STATE.Enabled,
    Callback = function(val)
        STATE.Enabled = val
    end
})

--// SERVERHOP TOGGLE
MainTab:CreateToggle({
    Name = "Server Hop",
    CurrentValue = STATE.HopEnabled,
    Callback = function(val)
        STATE.HopEnabled = val
    end
})

--// SERVERHOP TIMER
MainTab:CreateSlider({
    Name = "Hop Time (seconds)",
    Range = {60, 7200},
    Increment = 60,
    CurrentValue = STATE.HopTime,
    Callback = function(val)
        STATE.HopTime = val
        STATE.HopStart = os.clock()
    end
})

--// =========================
--// TIMER GUI (TOP RIGHT)
--// =========================
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "TimerUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,180,0,70)
frame.Position = UDim2.new(1,-200,0,20)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local timerLabel = Instance.new("TextLabel", frame)
timerLabel.Size = UDim2.new(1,0,0.6,0)
timerLabel.BackgroundTransparency = 1
timerLabel.TextScaled = true
timerLabel.TextColor3 = Color3.new(1,1,1)

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1,0,0.4,0)
statusLabel.Position = UDim2.new(0,0,0.6,0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextScaled = true

--// =========================
--// FARM LOOP
--// =========================
print(STATE.SelectedPos, STATE.Enabled)
task.spawn(function()
    local ATTACK_RANGE = 8

    while true do
        task.wait(0.1)

        if not STATE.Enabled or not STATE.SelectedPos then continue end

        local hrp = METHODS.GetHRP()
        local humanoid = METHODS.GetHumanoid()
        if not hrp or not humanoid then continue end

        if (hrp.Position - STATE.SelectedPos).Magnitude > 120 then
            METHODS.TweenTo(STATE.SelectedPos)
            continue
        end

        local target = METHODS.GetNearestBreakable(hrp)

        if target then
            local dist = (hrp.Position - target.position).Magnitude

            if dist > ATTACK_RANGE then
                METHODS.WalkTo(target.position)
            else
                humanoid:Move(Vector3.new(
                    math.random(-1,1),0,math.random(-1,1)
                ), false)
            end
        else
            METHODS.WalkTo(STATE.SelectedPos)
        end
    end
end)

--// =========================
--// TIMER LOOP
--// =========================
task.spawn(function()
    while true do
        task.wait(1)

        if not STATE.HopEnabled then
            timerLabel.Text = "Timer: OFF"
            statusLabel.Text = "Disabled"
            continue
        end

        local elapsed = tick() - STATE.HopStart
        local remaining = math.max(0, STATE.HopTime - elapsed)

        local m = math.floor(remaining / 60)
        local s = math.floor(remaining % 60)

        timerLabel.Text = string.format("Timer: %02d:%02d", m, s)

        if remaining > 10 then
            statusLabel.Text = "Farming"
        elseif remaining > 0 then
            statusLabel.Text = "Preparing..."
        else
            statusLabel.Text = "Hopping..."
            METHODS.ServerHop()
            break
        end
    end
end)
