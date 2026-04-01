local TweenService = game:GetService("TweenService")
local BreakablesClass = require(game:GetService("ReplicatedStorage").Shared.Classes.BreakablesClass)
local player = game.Players.LocalPlayer

--// POSITIONS
local pos1 = Vector3.new(203.75, 398.77, 138.81)
local pos2 = Vector3.new(-2199.80, 719.17, 2377.03)

--// STATE
local selectedPos = nil
local enabled = false

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

--// BUTTON LOGIC
btn1.MouseButton1Click:Connect(function()
    selectedPos = pos1
    enabled = true

    btn1.BackgroundColor3 = Color3.fromRGB(0,170,0)
    btn2.BackgroundColor3 = Color3.fromRGB(80,80,80)
end)

btn2.MouseButton1Click:Connect(function()
    selectedPos = pos2
    enabled = true

    btn2.BackgroundColor3 = Color3.fromRGB(0,170,0)
    btn1.BackgroundColor3 = Color3.fromRGB(80,80,80)
end)

--// STOP (optional: press again to stop)
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.P then
        enabled = false
        btn1.BackgroundColor3 = Color3.fromRGB(80,80,80)
        btn2.BackgroundColor3 = Color3.fromRGB(80,80,80)
    end
end)

--// TWEEN
local function tweenTo(position)
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - position).Magnitude
    local speed = 18

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(distance / speed, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position + Vector3.new(0, 3, 0))}
    )

    tween:Play()
    tween.Completed:Wait()
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

--// MAIN LOOP
task.spawn(function()
    while true do
        task.wait(0.2)

        if not enabled or not selectedPos then continue end

        local char = player.Character
        if not char then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- Always return to farming zone
        if (hrp.Position - selectedPos).Magnitude > 120 then
            tweenTo(selectedPos)
            task.wait(0.5)
        end

        local target = getNearestBreakable(hrp)

        if target then
            tweenTo(target.position)

            local hitCount = 0

            repeat
                if not enabled then break end

                target:Hit()
                hitCount += 1

                -- 🔥 Anti-spawn-break protection
                task.wait(0.15)

                -- stop overhitting (IMPORTANT)
                if hitCount > 25 then break end

            until target.isBroken or target.isDestroyed or target.hp <= 0

            -- 🔥 give time for respawn system
            task.wait(0.3)

        else
            -- 🔥 nothing found → reset position to refresh spawn
            tweenTo(selectedPos)
            task.wait(1)
        end
    end
end)
