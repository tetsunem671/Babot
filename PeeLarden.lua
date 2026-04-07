--!strict
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Events
local PurchaseEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PurchaseConveyorEgg")
local SharedEggs = require(ReplicatedStorage.Modules.Gameplay.Shared_Eggs)

-- Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()

-- State
local STATE = {
    AutoBuy = false,
    SelectedEggs = {},
    SelectedMutations = {}
}

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "Egg Auto-Buyer",
    LoadingTitle = "Initializing...",
    LoadingSubtitle = "Rayfield UI",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EggAutoBuyer",
        FileName = "Config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- Auto-Buy Toggle
local AutoBuyToggle = Window:CreateToggle({
    Name = "Auto Buy",
    CurrentValue = false,
    Flag = "AutoBuyFlag",
    Callback = function(value)
        STATE.AutoBuy = value
    end
})

-- Egg Multi-Select Dropdown
local EggDropdown = Window:CreateDropdown({
    Name = "Select Eggs",
    Options = SharedEggs.GetEggNames(), -- Make sure this returns a table of all egg names
    MultiSelection = true,
    CurrentOption = {},
    Flag = "EggDropdownFlag",
    Callback = function(selected)
        STATE.SelectedEggs = selected
    end
})

-- Mutation Multi-Select Dropdown
local MutationDropdown = Window:CreateDropdown({
    Name = "Select Mutations",
    Options = {"Mutation1","Mutation2","Mutation3","Mutation4"}, -- Replace with your mutation list
    MultiSelection = true,
    CurrentOption = {},
    Flag = "MutationDropdownFlag",
    Callback = function(selected)
        STATE.SelectedMutations = selected
    end
})

-- Auto-Buy Logic
RunService.Heartbeat:Connect(function(dt)
    if not STATE.AutoBuy then return end

    -- Loop through all plots / conveyors
    for _, plot in pairs(workspace.Core.Scriptable.Plots:GetChildren()) do
        if plot:FindFirstChild("Conveyor") and plot:FindFirstChild("Eggs") then
            for _, egg in pairs(plot.Eggs:GetChildren()) do
                local eggName = egg:GetAttribute("baseName")
                local eggModifiers = egg:GetAttribute("modifiers")
                local canBuy = false

                -- Check if this egg is in selected eggs
                if table.find(STATE.SelectedEggs, eggName) then
                    -- If mutations selected, check if egg matches any mutation
                    if #STATE.SelectedMutations > 0 and eggModifiers then
                        for mut in eggModifiers:gmatch("([^,]+)") do
                            mut = mut:match("^%s*(.-)%s*$")
                            if table.find(STATE.SelectedMutations, mut) then
                                canBuy = true
                                break
                            end
                        end
                    elseif #STATE.SelectedMutations == 0 then
                        canBuy = true
                    end
                end

                -- Fire server if conditions met
                if canBuy then
                    pcall(function()
                        PurchaseEvent:FireServer(eggName, tonumber(plot.Name))
                    end)
                end
            end
        end
    end
end)
