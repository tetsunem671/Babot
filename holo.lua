--// =========================
--// SERVICES
--// =========================
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Knit = require(ReplicatedStorage.Packages.knit)

local player = Players.LocalPlayer
local BreakablesClass = require(ReplicatedStorage.Shared.Classes.BreakablesClass)

--// =========================
--// CONFIG / STATE
--// =========================
local CONFIG = getgenv().CONFIG or {}

local POSITIONS = {
    ["Position 1"] = Vector3.new(203.75, 398.77, 138.81),
    ["Position 2"] = Vector3.new(-2199.80, 719.17, 2377.03)
}

local SelectedName = CONFIG.PositionOption or "Position 1"

local STATE = {
    Enabled = CONFIG.Default or false,
    SelectedPos = POSITIONS[SelectedName],
    CurrentTween = nil,

    HopEnabled = CONFIG.Serverhop and CONFIG.Serverhop.Enabled or false,
    HopTime = CONFIG.Serverhop and CONFIG.Serverhop.Time or 3600,
    HopStart = tick(),

    AutoR = CONFIG.AutoR or false,
    AutoRDelay = 0.2,

    CFrameText = "",
    TweenToCF = false,
    TweenSpeed = 100,
    TweenCancel = false,
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

function METHODS.StringToCFrame(str)
    local t = {}
    for num in string.gmatch(str, "[^,]+") do
        table.insert(t, tonumber(num))
    end
    if #t >= 3 then
        return CFrame.new(unpack(t))
    end
end

function METHODS.TweenToCFrame(cf)
    local char = METHODS.GetCharacter()
    local hrp = METHODS.GetHRP()
    if not char or not hrp then return end

    STATE.TweenCancel = false

    local startCF = hrp.CFrame
    local distance = (cf.Position - startCF.Position).Magnitude
    local duration = distance / STATE.TweenSpeed

    local startTime = tick()

    task.spawn(function()
        while true do
            if STATE.TweenCancel or not STATE.TweenToCF then
                break
            end

            local elapsed = tick() - startTime
            local alpha = math.clamp(elapsed / duration, 0, 1)

            local newCF = startCF:Lerp(cf, alpha)
            char:PivotTo(newCF)

            if alpha >= 1 then
                break
            end

            task.wait()
        end
    end)
end

function METHODS.TweenTo(position)
    local hrp = METHODS.GetHRP()
    if not hrp then return end

    -- cancel previous tween if exists
    if STATE.CurrentTween then
        STATE.CurrentTween:Cancel()
        STATE.CurrentTween = nil
    end

    local distance = (hrp.Position - position).Magnitude
    local speed = 80

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position + Vector3.new(0,3,0))}
    )

    STATE.CurrentTween = tween
    tween:Play()

    -- cleanup when done
    tween.Completed:Connect(function()
        if STATE.CurrentTween == tween then
            STATE.CurrentTween = nil
        end
    end)
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
        local svc = Knit.GetService("AutoReconnectService")
        if svc then
            svc.RequestReconnect:Fire()
        end
    end)
end


function METHODS.PressR()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
end

function METHODS.WaitUntilReady()
    -- wait for player + character
    repeat task.wait() until player
    repeat task.wait() until player.Character
    repeat task.wait() until player.Character:FindFirstChild("HumanoidRootPart")

    -- wait for Knit to fully start
    local started = false

    Knit.Start():andThen(function()
        started = true
    end):catch(function(err)
        warn("Knit failed:", err)
    end)

    repeat task.wait() until started
end

function METHODS.TeleportSmart(targetName)
    local svc = Knit.GetService("AreasService")
    local visual = Knit.GetController("TeleportVisualizerController")

    -- cancel animation (important)
    pcall(function()
        visual:CancelSequence()
        svc.TeleportToLocation:Fire(targetName)
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

local FarmTab = Window:CreateTab("Farming", 4483362458)
local MoveTab = Window:CreateTab("Movement", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

FarmTab:CreateDropdown({
    Name = "Farm Position",
    Options = {"Position 1", "Position 2"},
    CurrentOption = CONFIG.PositionOption or "Position 1",
    Callback = function(option)
        local selected = typeof(option) == "table" and option[1] or option
    
        if selected == "Position 2" then
            task.spawn(function()
                local name = "Easter"
    
                METHODS.TeleportSmart(name)
            end)
        end

        SelectedName = selected
        STATE.SelectedPos = POSITIONS[selected]
    end
})

FarmTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = STATE.Enabled,
    Callback = function(val)
        STATE.Enabled = val

        if not val and STATE.CurrentTween then
            STATE.CurrentTween:Cancel()
            STATE.CurrentTween = nil
        end
    end
})

FarmTab:CreateToggle({
    Name = "Auto Press R",
    CurrentValue = STATE.AutoR,
    Callback = function(val)
        STATE.AutoR = val
    end
})

FarmTab:CreateSlider({
    Name = "R Delay",
    Range = {0.05, 1},
    Increment = 0.05,
    CurrentValue = STATE.AutoRDelay,
    Callback = function(val)
        STATE.AutoRDelay = val
    end
})

MoveTab:CreateInput({
    Name = "CFrame (paste here)",
    PlaceholderText = "x,y,z,...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        STATE.CFrameText = text
    end
})

MiscTab:CreateSlider({
    Name = "Tween Speed",
    Range = {10, 300},
    Increment = 10,
    CurrentValue = STATE.TweenSpeed,
    Callback = function(val)
        STATE.TweenSpeed = val
    end
})

MiscTab:CreateToggle({
    Name = "Tween To CFrame",
    CurrentValue = false,
    Callback = function(val)
        STATE.TweenToCF = val

        if val then
            local cf = METHODS.StringToCFrame(STATE.CFrameText)
            if cf then
                METHODS.TweenToCFrame(cf)
            else
                warn("Invalid CFrame")
            end
        else
            STATE.TweenCancel = true
        end
    end
})

MiscTab:CreateToggle({
    Name = "Server Hop",
    CurrentValue = STATE.HopEnabled,
    Callback = function(val)
        STATE.HopEnabled = val
    end
})

MiscTab:CreateSlider({
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
timerLabel.TextColor3 = Color3.new(1,1,1)

--// =========================
--// FARM LOOP
--// =========================
task.spawn(function()
    local ATTACK_RANGE = 8

    while true do
        task.wait(0.1)

        if not STATE.Enabled or not STATE.SelectedPos then 
            if STATE.CurrentTween then
                STATE.CurrentTween:Cancel()
                STATE.CurrentTween = nil
            end
            continue 
        end

        local hrp = METHODS.GetHRP()
        local humanoid = METHODS.GetHumanoid()
        if not hrp or not humanoid then continue end

        if (hrp.Position - STATE.SelectedPos).Magnitude > 60 then
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

task.spawn(function()
    while true do
        task.wait(STATE.AutoRDelay)

        if STATE.AutoR then
            METHODS.PressR()
        end
    end
end)
