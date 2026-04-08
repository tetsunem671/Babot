--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

--// Modules
local SharedEggs = require(ReplicatedStorage.Modules.Gameplay.Shared_Eggs)
local SharedModifiers = require(ReplicatedStorage.Modules.Gameplay.Shared_Modifiers)

--// Workspace
local PlotsFolder = workspace:WaitForChild("Core"):WaitForChild("Scriptable"):WaitForChild("Plots")

--// HELPER FUNCTIONS
local function hasSelectedMutation(eggModifiers)
    if typeof(eggModifiers) ~= "string" or eggModifiers == "" then
        return false
    end
    for mut in eggModifiers:gmatch("([^,]+)") do
        mut = mut:match("^%s*(.-)%s*$")
        if table.find(STATE.SelectedMutations, mut) then
            return true
        end
    end
    return false
end

local function isNoMutation(eggModifiers)
    return typeof(eggModifiers) ~= "string" or eggModifiers == ""
end

--// LOOP
task.spawn(function()
    while true do
        task.wait(0.2)

        for _, plot in pairs(PlotsFolder:GetChildren()) do
            if plot:FindFirstChild("Conveyor") and plot:FindFirstChild("Eggs") then
                for _, egg in pairs(plot.Eggs:GetChildren()) do
                    local eggName = egg:GetAttribute("baseName")
                    local eggModifiers = egg:GetAttribute("modifiers")
                    local canBuy = false

                    -- WITH MUTATION
                    if STATE.AutoBuyMutation 
                    and table.find(STATE.SelectedEggsWithMutation, eggName)
                    and hasSelectedMutation(eggModifiers) then
                        canBuy = true
                    end

                    -- NO MUTATION
                    if STATE.AutoBuyNoMutation 
                    and table.find(STATE.SelectedEggsNoMutation, eggName)
                    and isNoMutation(eggModifiers) then
                        canBuy = true
                    end

                    if canBuy then
                        local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt")
                        if prompt and not prompt:GetAttribute("TriggeredByScript") then
                            prompt:SetAttribute("TriggeredByScript", true)

                            task.spawn(function()
                                prompt:InputHoldBegin()
                                task.wait(0.5)
                                prompt:InputHoldEnd()
                                task.wait(0.1)
                                prompt:SetAttribute("TriggeredByScript", false)
                            end)
                        end
                    end
                end
            end
        end
    end
end)
