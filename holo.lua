local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local BreakablesClass = require(game:GetService("ReplicatedStorage").Shared.Classes.BreakablesClass)
local player = Players.LocalPlayer

local Knit

--// POSITIONS
local pos1 = Vector3.new(203.75, 398.77, 138.81)
local pos2 = Vector3.new(-2199.80, 719.17, 2377.03)

--// STATE 
local config = getgenv().CONFIG or {} 
local selectedPos = config.Default and pos1 or nil 
local enabled = config.Default and true or false

local serverhop = config.Serverhop or {}
local hopEnabled = serverhop.Enabled or false
local hopTime = serverhop.Time or 3600

local PLACE_ID = game.PlaceId
local hopStartTime = tick()

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AutoBreakGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function createButton(text, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 150, 0, 50)
    b.Position = UDim2.new(0, 20, 0, y)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(80,80,80)
    b.TextColor3 = Color3.new(1,1,1)
    b.Parent = gui
    return b
end

local btn1 = createButton("Position 1", 200)
local btn2 = createButton("Position 2", 260)

local function toggleEnabled(pos, activeBtn)
    enabled = not enabled
    selectedPos = pos

    if enabled then
        if activeBtn == 1 then
            btn1.BackgroundColor3 = Color3.fromRGB(0,170,0)
            btn2.BackgroundColor3 = Color3.fromRGB(80,80,80)
        elseif activeBtn == 2 then
            btn1.BackgroundColor3 = Color3.fromRGB(80,80,80)
            btn2.BackgroundColor3 = Color3.fromRGB(0,170,0)
        end
    else
        -- reset both
        btn1.BackgroundColor3 = Color3.fromRGB(80,80,80)
        btn2.BackgroundColor3 = Color3.fromRGB(80,80,80)
    end
end

--// BUTTON LOGIC
btn1.MouseButton1Click:Connect(function()
    toggleEnabled(pos1, 1)
end)

btn2.MouseButton1Click:Connect(function()
    toggleEnabled(pos2, 2)
end)

--// STOP (optional: press again to stop)
local UIS = game:GetService("UserInputService")

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.P then
        enabled = false
        selectedPos = nil

        btn1.BackgroundColor3 = Color3.fromRGB(80,80,80)
        btn2.BackgroundColor3 = Color3.fromRGB(80,80,80)
    end
end)

local function serverHop()
    local success, err = pcall(function()
        -- upvalues: (ref) v_u_6
        if not Knit then
            Knit = require(ReplicatedStorage.Packages.knit)
        end
        local AutoReconnectService = Knit.GetService("AutoReconnectService")
        if AutoReconnectService then
            AutoReconnectService.RequestReconnect:Fire()
        end
    end)
    if not success then
        warn("[AutoReconnectController] RequestReconnect failed:", err)
    end
    --TeleportService:Teleport(game.PlaceId, player)
end

--// TWEEN (NON-BLOCKING)
local currentTween

local humanoid

local function getHumanoid()
    local char = player.Character
    if not char then return end
    return char:FindFirstChildOfClass("Humanoid")
end

local function tweenTo(position)
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - position).Magnitude
    local speed = 50

    local tween = TweenService:Create(hrp, TweenInfo.new(distance / speed, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    })

    tween:Play()
    tween.Completed:Wait()
end

local function walkTo(position)
    humanoid = getHumanoid()
    if not humanoid then return end

    humanoid:MoveTo(position)
end

--// GET NEAREST BREAKABLE
local function getNearestBreakable(hrp)
    local breakables = BreakablesClass.GetNearby(hrp.Position, 100)

    table.sort(breakables, function(a, b)
        return (a.position - hrp.Position).Magnitude <
               (b.position - hrp.Position).Magnitude
    end)

    for _, obj in ipairs(breakables) do
        if obj and not obj.isBroken and not obj.isDestroyed and obj.hp > 0 then
            return obj
        end
    end
end

task.spawn(function()
    local ATTACK_RANGE = 8
    local currentTarget = nil

    while true do
        task.wait(0.1)

        if not enabled or not selectedPos then continue end

        local char = player.Character
        if not char then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then continue end

        -- 🔥 stay inside farm zone
        if (hrp.Position - selectedPos).Magnitude > 120 then
            tweenTo(selectedPos)
            continue
        end

        local target = getNearestBreakable(hrp)

        if target then
            local dist = (hrp.Position - target.position).Magnitude

            -- 🔥 only move if not in range
            if dist > ATTACK_RANGE then
                walkTo(target.position)
            else
                -- 🔥 small micro-adjust to keep moving (prevents idle)
                humanoid:Move(Vector3.new(
                    math.random(-1,1),
                    0,
                    math.random(-1,1)
                ), false)
            end

        else
            walkTo(selectedPos)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)

        if not hopEnabled then continue end

        if tick() - hopStartTime >= hopTime then
            print("🔁 Server hopping...")
            serverHop()
            break -- stop script after teleport
        end
    end
end)
