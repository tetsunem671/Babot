local TweenService = game:GetService("TweenService")
local BreakablesClass = require(game:GetService("ReplicatedStorage").Shared.Classes.BreakablesClass)
local player = game.Players.LocalPlayer

--// STATE
local enabled = false

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AutoBreakGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 150, 0, 50)
button.Position = UDim2.new(0, 20, 0, 200)
button.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
button.TextColor3 = Color3.new(1,1,1)
button.Text = "Auto: OFF"
button.Parent = gui

--// TOGGLE
button.MouseButton1Click:Connect(function()
    enabled = not enabled

    if enabled then
        button.Text = "Auto: ON"
        button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        button.Text = "Auto: OFF"
        button.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    end
end)

--// TWEEN FUNCTION
local function tweenTo(position)
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - position).Magnitude
    local speed = 20

    local tween = TweenService:Create(hrp, TweenInfo.new(distance / speed, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    })

    tween:Play()
    tween.Completed:Wait()
end

--// MAIN LOOP
task.spawn(function()
    while true do
        task.wait(0.2)

        if not enabled then continue end

        local char = player.Character
        if not char then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        local breakables = BreakablesClass.GetNearby(hrp.Position, 100)

        -- 🔥 SORT BY DISTANCE (nearest first)
        table.sort(breakables, function(a, b)
            return (a.position - hrp.Position).Magnitude < (b.position - hrp.Position).Magnitude
        end)

        for _, obj in ipairs(breakables) do
            if not enabled then break end

            if obj and not obj.isBroken and not obj.isDestroyed then
                
                tweenTo(obj.position)

                repeat
                    if not enabled then break end
                    obj:Hit()
                    task.wait(0.1)
                until obj.isBroken or obj.isDestroyed or obj.hp <= 0
            end
        end
    end
end)
