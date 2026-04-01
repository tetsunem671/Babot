local TweenService = game:GetService("TweenService")
local BreakablesClass = require(game:GetService("ReplicatedStorage").Shared.Classes.BreakablesClass)
local player = game.Players.LocalPlayer

--// POSITIONS (EDIT THESE)
local pos1 = Vector3.new(203.75982666015625, 398.7754211425781, 138.8179931640625) -- 🔥 change this
local pos2 = Vector3.new(-2199.806884765625, 719.1761474609375, 2377.031005859375) -- 🔥 change this

--// STATE
local config = getgenv().CONFIG or {}
local selectedPos = config.Default and pos1 or nil
local enabled = config.Default and true or false

--// GUI
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local btn1 = Instance.new("TextButton")
btn1.Size = UDim2.new(0, 150, 0, 50)
btn1.Position = UDim2.new(0, 20, 0, 200)
btn1.Text = "Position 1"
btn1.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
btn1.TextColor3 = Color3.new(1,1,1)
btn1.Parent = gui

local btn2 = Instance.new("TextButton")
btn2.Size = UDim2.new(0, 150, 0, 50)
btn2.Position = UDim2.new(0, 20, 0, 260)
btn2.Text = "Position 2"
btn2.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
btn2.TextColor3 = Color3.new(1,1,1)
btn2.Parent = gui

--// TWEEN FUNCTION
local function tweenTo(position)
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local distance = (hrp.Position - position).Magnitude
    local speed = 18

    local tween = TweenService:Create(hrp, TweenInfo.new(distance / speed, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    })

    tween:Play()
    tween.Completed:Wait()
end

--// BUTTON LOGIC
btn1.MouseButton1Click:Connect(function()
    selectedPos = pos1
    enabled = not enabled

    btn2.BackgroundColor3 = Color3.fromRGB(80,80,80)
    btn1.BackgroundColor3 = enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(80,80,80)
end)

btn2.MouseButton1Click:Connect(function()
    selectedPos = pos2
    enabled = not enabled

    btn1.BackgroundColor3 = Color3.fromRGB(80,80,80)
    btn1.BackgroundColor3 = enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(80,80,80)
end)

--// MAIN LOOP
task.spawn(function()
    while true do
        task.wait(0.2)

        if not enabled or not selectedPos then continue end

        local char = player.Character
        if not char then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- 🔥 ALWAYS GO BACK TO SELECTED POSITION
        if (hrp.Position - selectedPos).Magnitude > 100 then
            tweenTo(selectedPos)
        end

        local breakables = BreakablesClass.GetNearby(hrp.Position, 100)

        -- SORT NEAREST
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
